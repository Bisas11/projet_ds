# PhotoCoach AI — Technical Study Sheet

> Personal study document for academic evaluation. Concise, project-focused, no filler.

---

## 1. App Overview

**What the app does**
- Analyzes photos using on-device AI and gives the user actionable feedback
- Offers three individual ML tools (face detection, image labeling, selfie segmentation) plus a combined **Photo Assistant** that runs all three at once and produces a quality score with tips
- Stores scan history locally (SQLite) so users can review past analyses

**Why ML is used**
- Extracting meaningful information from raw pixels (faces, objects, person vs. background) is impossible with classical algorithms — it requires trained neural network models
- ML Kit provides pre-trained, production-quality models — no training, no cloud call, no cost per request

**Real-world use case**
- Social media portrait coaching (is the lighting good? am I smiling? is the framing right?)
- Profile picture quality checker
- Accessible AI assistant for users who want photo feedback without a professional photographer

---

## 2. Technology Stack

### Flutter
- **Role:** Single codebase UI + app logic, compiled natively to Android (primary target)
- **Why:** Hot reload for fast iteration, widget tree maps well to ML result UIs, async/await handles non-blocking ML processing cleanly
- **State management:** Provider (ChangeNotifier) — `SettingsProvider` for theme/language preferences
- **Routing:** Named routes in `MaterialApp` (`/home`, `/image-labeling`, `/face-detection`, etc.)

### Firebase
| Service | How it is used |
|---|---|
| **Firebase Auth** | Email/password authentication (register, login, forgot password) |
| **Auth Gate** | `StreamBuilder<User?>` in `app.dart` — reactively switches between `LandingScreen` (logged out) and `HomeScreen` (logged in) without manual route guards |

> Firebase ML Kit was **not** used — the project uses the standalone `google_mlkit_*` packages instead (no Firebase dependency for ML).

### ML Kit (on-device)
- Models run **entirely on the device** — no image is sent to a server
- Advantages: offline support, no latency from network, no privacy concerns, no per-call cost
- Entry point for every ML operation: `InputImage.fromFile(imageFile)` — wraps a `dart:io File` into ML Kit's format
- Pattern: **create → process → close** — each call instantiates a processor, runs `.processImage()`, then calls `.close()` in a `finally` block to free native resources

---

## 3. ML Kit Services (Detailed)

### 3.1 Face Detection
**Package:** `google_mlkit_face_detection ^0.13.2`

**What it does**
- Detects human faces in a still image
- Returns bounding boxes, facial landmarks (eyes, nose, mouth corners), and classification probabilities

**Why used in this app**
- Drives the entire scoring system — if no face is found, the photo loses 20 points immediately
- Smile and eye-open probabilities determine personalized feedback tips

**How it works internally**
- Uses a CNN (convolutional neural network) trained on millions of face images
- Two-stage pipeline: face localisation (find candidate regions) → face analysis (classify attributes per region)
- `enableClassification: true` activates probability outputs (smile, eye open)
- `performanceMode: FaceDetectorMode.accurate` prioritises quality over speed

**Flutter implementation**
```dart
final inputImage = InputImage.fromFile(imageFile);
final detector = FaceDetector(
  options: FaceDetectorOptions(
    enableClassification: true,   // smiling + eye-open probabilities
    enableLandmarks: true,        // eye/nose/mouth positions
    enableContours: true,         // face outline points
    enableTracking: true,         // tracking ID per face
    performanceMode: FaceDetectorMode.accurate,
  ),
);
final List<Face> faces = await detector.processImage(inputImage);
detector.close();
```

**Key result fields used**
| Field | Type | Used for |
|---|---|---|
| `face.smilingProbability` | `double?` (0–1) | Score penalty if < 0.3; tip if > 0.6 |
| `face.leftEyeOpenProbability` | `double?` (0–1) | Score penalty if < 0.4 |
| `face.rightEyeOpenProbability` | `double?` (0–1) | Score penalty if < 0.4 |
| `face.boundingBox` | `Rect` | Display on-screen |
| `face.headEulerAngleY` | `double?` | Head tilt (left/right) |
| `face.headEulerAngleZ` | `double?` | Head rotation (roll) |
| `face.trackingId` | `int?` | Identifies the same face across frames |

---

### 3.2 Image Labeling
**Package:** `google_mlkit_image_labeling ^0.14.2`

**What it does**
- Classifies the overall content of an image into human-readable categories (e.g. "Person", "Sky", "Dog", "Smile")
- Returns a list of `ImageLabel` objects sorted by confidence

**Why used in this app**
- Detects lighting conditions (`"Dark"`, `"Night"` → −15 points)
- Detects outdoor/good lighting (`"Sky"`, `"Outdoor"`, `"Sunlight"` → +5 bonus)
- Detects scene clutter (many low-confidence labels → −5)
- Displayed directly to users on the Image Labeling screen as a list of detected concepts

**How it works internally**
- Uses MobileNet-based image classification model — a lightweight CNN designed for mobile inference
- The model outputs a probability vector over ~400+ categories; only labels above the threshold are returned

**Flutter implementation**
```dart
final inputImage = InputImage.fromFile(imageFile);
final labeler = ImageLabeler(
  options: ImageLabelerOptions(confidenceThreshold: 0.5), // only labels ≥ 50%
);
final List<ImageLabel> labels = await labeler.processImage(inputImage);
labeler.close();
```

**Key result fields used**
| Field | Type | Meaning |
|---|---|---|
| `label.label` | `String` | Human-readable category name |
| `label.confidence` | `double` (0–1) | How confident the model is |
| `label.index` | `int` | Internal model category index |

---

### 3.3 Selfie Segmentation
**Package:** `google_mlkit_selfie_segmentation ^0.10.1`

**What it does**
- Produces a per-pixel **segmentation mask** — each pixel gets a confidence value (0–1) representing probability that it belongs to a person
- Does not detect faces — it separates foreground person from background at the pixel level

**Why used in this app**
- Calculates what percentage of the frame the subject occupies → framing score
- If `personPercentage < 5%` → subject too small (−15); if `≥ 70%` → too close (−10)
- Renders a green overlay on the Selfie Segmentation screen to visualise what the model detected

**How it works internally**
- Uses a lightweight encoder-decoder CNN (similar to U-Net architecture)
- Processes full image, outputs a float mask of width × height confidence values
- `enableRawSizeMask: true` ensures the mask matches the original image resolution (not downscaled)

**Flutter implementation**
```dart
final inputImage = InputImage.fromFile(imageFile);
final segmenter = SelfieSegmenter(
  mode: SegmenterMode.single,   // still image (not stream)
  enableRawSizeMask: true,       // mask = original image size
);
final SegmentationMask? mask = await segmenter.processImage(inputImage);
segmenter.close();
```

**Converting the mask to a visible overlay**
```dart
// mask.confidences is a flat Float32List of width × height values
for (int i = 0; i < confidences.length; i++) {
  if (confidences[i] > 0.5) {
    // Person pixel → green RGBA
    pixels[i * 4 + 0] = 76;   // R
    pixels[i * 4 + 1] = 175;  // G
    pixels[i * 4 + 2] = 80;   // B
    pixels[i * 4 + 3] = (180 * confidences[i]).toInt(); // A (variable opacity)
  }
  // Background → transparent (all zeros)
}
// Encode to PNG via ui.decodeImageFromPixels → ui.Image → toByteData(PNG)
```

**Person percentage calculation**
```dart
int personPixels = mask.confidences.where((c) => c > 0.5).length;
double personPercentage = (personPixels / mask.confidences.length) * 100;
```

---

## 4. Application Architecture

### Folder structure
```
lib/
├── main.dart               # Entry point — Firebase init, SystemChrome, app launch
├── app.dart                # MaterialApp, ThemeData (design system), routes
├── models/                 # Data models (ScanRecord for history)
├── providers/              # SettingsProvider (theme, language — ChangeNotifier)
├── screens/
│   ├── splash_screen.dart          # Animated startup screen (fade + scale, 4.5s)
│   ├── auth_gate.dart              # StreamBuilder auth gate (reached after splash)
│   ├── landing_screen.dart         # Unauthenticated users — hero + CTA
│   ├── home_screen.dart            # Main hub with feature cards + drawer
│   ├── image_labeling_screen.dart  # Individual ML screen
│   ├── face_detection_screen.dart  # Individual ML screen
│   ├── selfie_segmentation_screen.dart # Individual ML screen
│   ├── photo_assistant_screen.dart # Combined: all 3 ML + score + tips
│   ├── history_screen.dart         # SQLite scan history browser
│   ├── history_detail_screen.dart  # Full detail view for a saved scan result
│   ├── profile_screen.dart         # View/edit display name, photo, reset password
│   └── settings_screen.dart / about_screen.dart / ...
├── services/
│   ├── ml_service.dart             # All ML Kit calls (static methods)
│   ├── photo_feedback_service.dart # Scoring + tip generation (pure logic)
│   ├── database_service.dart       # SQLite CRUD via sqflite
│   ├── sound_service.dart          # Audio playback via audioplayers
│   └── notification_service.dart   # Daily reminder (flutter_local_notifications)
└── widgets/
    ├── ml_widgets.dart             # MlEmptyState, MlLoadingState, MlSectionHeader
    └── result_card.dart            # Reusable result row with optional confidence bar
```

### Separation of concerns
| Layer | Responsibility |
|---|---|
| **Screens** | UI layout, user input, display of results — no ML logic |
| **MLService** | All ML Kit operations — no UI imports |
| **PhotoFeedbackService** | Score computation + tip generation — no UI, no ML Kit imports (receives pre-processed results) |
| **DatabaseService** | SQLite persistence — no business logic |
| **Providers** | App-wide state (settings) — no business logic |

### Auth gate (reactive)
The auth gate was **extracted into its own widget** (`auth_gate.dart`) so the splash screen can navigate to it cleanly after finishing its animation. `app.dart` no longer hosts it inline.

```dart
// screens/auth_gate.dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.data != null) return const HomeScreen();
    return const LandingScreen();
  },
)
```

### Data flow: Image → UI
```
User picks image (ImagePicker)
       ↓
File stored as dart:io File
       ↓
MLService.detectFaces(file)      ─┐
MLService.labelImage(file)        ├─ Future.wait([...]) — concurrent
MLService.segmentSelfie(file)    ─┘
       ↓
Results passed to PhotoFeedbackService.computeScore() + .generateTips()
       ↓
setState() updates screen state → Flutter rebuilds widget tree
       ↓
Results optionally saved to SQLite via DatabaseService
```

---

## 5. Splash Screen

**File:** `lib/screens/splash_screen.dart`

**What it does**
- First screen the user sees on every app launch
- Displays the app logo (`Icons.camera_enhance_rounded` in a translucent circle) and the name "PhotoCoach AI"
- Plays `assets/sounds/startup.mp3` via `SoundService`
- After **4.5 seconds** it performs a cross-fade `pushReplacement` to `AuthGate`

**Animation**
- Uses `AnimationController` with `SingleTickerProviderStateMixin`
- Duration: 900ms; two concurrent animations driven by the same controller:
  - `_fadeAnim` — `CurvedAnimation(curve: Curves.easeIn)` on opacity 0 → 1
  - `_scaleAnim` — `Tween(0.80 → 1.0)` with `Curves.easeOutCubic` for the subtle scale bump
- Both wrapped in `FadeTransition` + `ScaleTransition`

**Navigation to AuthGate**
```dart
Timer(const Duration(milliseconds: 4500), () {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const AuthGate(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ),
  );
});
```

**Why `pushReplacement`?**
The splash screen must not remain on the navigation stack — pressing back after login should not take the user back to the splash.

---

## 6. Sound System

**Package:** `audioplayers ^6.1.0`
**Files:** `assets/sounds/click.mp3`, `assets/sounds/startup.mp3`

**Why not `SystemSound.play()`?**
- `SystemSound` uses the OS default click — on Android this sound is **disabled by default** on most devices
- `audioplayers` plays real asset files that are always present and always audible

**SoundService design**
```dart
class SoundService {
  // Dedicated players — reusing avoids re-init overhead
  static final _clickPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final _startupPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.release);

  static Future<void> playClick() async {
    await _clickPlayer.stop();  // interrupt previous click if still playing
    await _clickPlayer.play(AssetSource('sounds/click.mp3'));
  }

  static Future<void> playStartup() async {
    await _startupPlayer.play(AssetSource('sounds/startup.mp3'));
  }
}
```

**Why two separate `AudioPlayer` instances?**
- `_clickPlayer` uses `ReleaseMode.stop` — stopped and restarted each time, so rapid taps don't queue multiple plays
- `_startupPlayer` uses `ReleaseMode.release` — played once then resources are released

**Integration points**
| Where | Method called |
|---|---|
| `SplashScreen.initState()` | `SoundService.playStartup()` |
| ML result screens (all 4) | `SoundService.playFeedback(settings)` → calls `playClick()` |
| Settings → Test Sound button | `SoundService.testSound()` → calls `playClick()` |

---

## 7. Profile System

**File:** `lib/screens/profile_screen.dart`

- Reads from `FirebaseAuth.instance.currentUser`
- Lets users edit their **display name** → `user.updateDisplayName(name)`
- Lets users pick a **profile photo** from the gallery via `image_picker`, copies it to the app documents directory, stores the local path as `user.updatePhotoURL(savedPath)`
- **Reset password** → `FirebaseAuth.instance.sendPasswordResetEmail(email: email)` — sends a Firebase reset link
- Photo is displayed as `FileImage` (local path), `NetworkImage` (URL), or initials fallback

**Why store the photo path in `photoURL` instead of Firebase Storage?**
No cloud storage dependency — photos remain on-device, no cost, no upload latency.

---

## 8. Implementation Details

### Key Flutter plugins
| Plugin | Version | Purpose |
|---|---|---|
| `google_mlkit_face_detection` | ^0.13.2 | Face analysis |
| `google_mlkit_image_labeling` | ^0.14.2 | Object/scene classification |
| `google_mlkit_selfie_segmentation` | ^0.10.1 | Person mask |
| `firebase_auth` | latest | User authentication |
| `firebase_core` | latest | Firebase initialisation |
| `sqflite` | ^2.4.2 | Local SQLite database |
| `image_picker` | latest | Camera + gallery access |
| `google_fonts` | ^6.2.1 | Inter typeface |
| `provider` | latest | State management |
| `flutter_local_notifications` | latest | Daily reminders |
| `shared_preferences` | latest | Settings persistence |
| `audioplayers` | ^6.1.0 | Custom audio files (click.mp3, startup.mp3) |

### Image capture / loading
```dart
// Via ImagePicker (camera or gallery)
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery);
if (picked != null) {
  final file = File(picked.path); // dart:io File
  // pass file to MLService
}
```
- All three ML services accept `File` → `InputImage.fromFile(file)` is the universal adapter

### ML result processing
- Each `MLService` method follows **create → process → close** pattern using `try/finally`
- In **PhotoAssistantScreen**, all three calls run in parallel:
  ```dart
  final results = await Future.wait([
    MLService.detectFaces(imageFile),
    MLService.labelImage(imageFile),
    MLService.segmentSelfie(imageFile),
  ]);
  ```
- This is more efficient than sequential `await` — total time ≈ slowest single operation, not the sum

### UI updates
- Each screen uses `StatefulWidget` with `bool _isProcessing`, result variables, and `setState()`
- `_isProcessing = true` → shows `MlLoadingState` widget (spinner + text)
- After processing → `setState()` sets results → `MlSectionHeader` + result cards are rendered
- `MlEmptyState` widget shown when no image has been picked yet

### Immersive display
```dart
// In main.dart — hides bottom navigation bar, keeps status bar
await SystemChrome.setEnabledSystemUIMode(
  SystemUiMode.manual,
  overlays: [SystemUiOverlay.top],
);
```

---

## 9. Image Scoring System (Strict Mode)

### Logic overview
`PhotoFeedbackService.computeScore()` takes three inputs (already computed by ML Kit):
- `List<Face> faces` — from face detection
- `List<ImageLabel> labels` — from image labeling
- `double? personPercentage` — derived from selfie segmentation mask

### Why penalty-based?
- **Alternative (weighted sum):** Complex to calibrate, hard to explain what changed the score
- **Penalty-based from 100:** Intuitive (like a school grade), each deduction maps to a specific problem, easy to extend, easy to justify to the user with a matching tip
- Score is clamped to `[0, 100]` — can never go negative or exceed 100
- **Philosophy:** Penalise flaws aggressively; do NOT reward neutral conditions. A genuinely good selfie should be hard to achieve. Average images should land ~40–55, not 80+.

### Score bands
| Range | Label |
|---|---|
| 0–40 | Poor |
| 41–65 | Average |
| 66–80 | Good |
| 81–100 | Excellent (rare) |

### Penalty table (current strict values)
| Condition | Check | Score Δ |
|---|---|---|
| No person at all | `faces.isEmpty && personPct ≤ 8%` | **−50** |
| Face hidden / side profile | `faces.isEmpty && personPct > 8%` | **−40** |
| Both eyes fully closed | `leftOpen < 0.3 && rightOpen < 0.3` | **−25** |
| One eye closed / blinking | `leftOpen < 0.3 \|\| rightOpen < 0.3` | −15 |
| Squinting | `< 0.6` on either eye | −8 |
| Strong side profile | `headY.abs() > 35°` | **−25** |
| Notably turned away | `headY.abs() > 20°` | −15 |
| Slight head turn | `headY.abs() > 12°` | −7 |
| Head tilted/rolled (heavy) | `headZ.abs() > 25°` | −12 |
| Head tilted/rolled (light) | `headZ.abs() > 15°` | −6 |
| Flat / unhappy expression | `smiling < 0.2` | −12 |
| Neutral expression | `smiling < 0.4` | −6 |
| ML Kit low confidence | `smilingProbability == null && leftEyeOpen == null` | −10 |
| Multiple faces | `faces.length > 1` | −10 |
| Subject barely visible | `personPct < 3%` | **−25** |
| Subject too small | `personPct < 8%` | −18 |
| Subject slightly small | `personPct < 15%` | −8 |
| Face fills frame (cropped) | `personPct ≥ 80%` | **−20** |
| Too close | `personPct ≥ 65%` | −10 |
| Framing unknown | `personPercentage == null` | −8 |
| Dark / night scene | label contains `"dark"`, `"night"`, `"darkness"` | −20 |
| Strong shadows | label contains `"shadow"` | −10 |
| Cluttered scene | `labels.length > 6 && lowConfidenceCount > 4` | −10 |
| Busy background | `labels.length > 8` | −5 |

> There are **no bonuses** — good conditions simply avoid penalties.

### Example score walkthrough
Scenario: portrait taken at night, neutral expression, slight head turn (14°), subject well-framed (20% of frame)
- Start: **100**
- Face detected ✓, eyes open ✓
- Head turn 14° → `headY.abs() > 12°` → **−7** → 93
- Neutral expression (smiling ≈ 0.3) → **−6** → 87
- 20% framing ✓ (ideal range) → no penalty
- Dark scene label detected → **−20** → 67
- **Final score: 67/100 — "Good"**

Same scenario with old (lenient) system: 100 − 5 (no smile) − 15 (dark) = **80 — was overrating**

### Tips system
Each detected problem generates a `PhotoTip` with:
- An `IconData` (Material icon)
- A human-readable `message` string
- A `TipType` that controls the colour in the UI

| TipType | Colour | Meaning |
|---|---|---|
| `good` | Green | Positive feedback |
| `warning` | Orange/Red | Problem requiring action |
| `suggestion` | Blue | Improvement idea |
| `info` | Grey | Neutral observation |

Tips are generated independently of the score — a tip can exist even if the score deduction is 0 (e.g. a "good" tip when smile > 0.6).

---

## Quick-Reference: Possible Exam Questions

**Q: How does the app run all three ML operations at once?**
> `Future.wait([detectFaces, labelImage, segmentSelfie])` — Dart's async model runs them concurrently; total time = max of the three, not the sum.

**Q: Why is ML Kit used instead of a cloud API?**
> On-device inference: no internet required, no latency, no data privacy issues, no cost per request.

**Q: What is `InputImage.fromFile()`?**
> The universal ML Kit adapter that converts a `dart:io File` into the `InputImage` format that all ML Kit processors accept.

**Q: How does the segmentation mask become a visible green overlay?**
> The `mask.confidences` (Float32List) is iterated pixel-by-pixel; pixels with confidence > 0.5 are set to green RGBA; the raw pixel array is encoded to PNG via `ui.decodeImageFromPixels` → `ui.Image` → `toByteData(png)`.

**Q: Why is the scoring penalty-based and why was it made stricter?**
> Penalty-based is intuitive — each deduction maps to one specific problem. It was made stricter because the original system gave high scores to mediocre photos (e.g. a dark, unsmiling, slightly-turned face still scored 80). The new system removes all bonuses and adds graduated penalties for head orientation, eye state, framing, and lighting. Neutral images now land ~40–55.

**Q: How does authentication work without route guards?**
> `AuthGate` holds a `StreamBuilder<User?>` on `FirebaseAuth.instance.authStateChanges()` — it reactively rebuilds whenever auth state changes. The splash screen navigates to `AuthGate` after 4.5s; `AuthGate` then shows `HomeScreen` (logged in) or `LandingScreen` (logged out).

**Q: Why is the splash screen using `pushReplacement` instead of `push`?**
> So the splash screen is removed from the navigation stack — pressing back after login would otherwise return the user to the splash screen.

**Q: Why use `audioplayers` instead of `SystemSound.play()`?**
> `SystemSound` uses the OS default click sound which is disabled by default on most Android devices. `audioplayers` plays real MP3 asset files bundled with the app, so sounds are always audible regardless of device settings.

**Q: How does the profile photo system work without cloud storage?**
> The picked image is copied to the app's documents directory (`getApplicationDocumentsDirectory()`). The local file path is then stored as `user.photoURL` via `FirebaseAuth.updatePhotoURL()`. No cloud storage is used — photos remain on-device.

**Q: Where is scan history stored and why not Firebase?**
> SQLite via `sqflite` — local storage, works offline, no read/write costs, history is device-private.
