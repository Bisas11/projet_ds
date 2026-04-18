# VisionAI — Technical Documentation

> **Version:** 1.0.0  
> **Framework:** Flutter (Dart SDK ^3.10.7)  
> **Platform:** Android (primary), multi-platform scaffold  
> **Last Updated:** April 2026

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [UI Layer (Flutter Widgets)](#3-ui-layer-flutter-widgets)
4. [Firebase Integration](#4-firebase-integration)
5. [ML Kit Integration](#5-ml-kit-integration)
6. [Dependencies & Packages](#6-dependencies--packages)
7. [Business Logic & Data Flow](#7-business-logic--data-flow)
8. [Security & Best Practices](#8-security--best-practices)
9. [Configuration & Environment](#9-configuration--environment)
10. [Performance & Optimization](#10-performance--optimization)
11. [Developer Guide](#11-developer-guide)

---

## 1. Project Overview

**VisionAI** is a Flutter mobile application that leverages **Google ML Kit** for on-device visual intelligence. The app provides three core machine-learning features — image labeling, selfie segmentation, and face detection — all running locally on the device without requiring an internet connection (except for authentication).

### Purpose

Built as an academic project fulfilling a specification ("Cahier de charges") that requires:
- Integration of at least **2 ML Kit services** (this project uses 3)
- Firebase Authentication
- Notification system
- Dark/light theme support
- Sound & vibration feedback
- Multilingual support (French, English, Arabic)
- History/persistence of scan results
- Settings management

### Key Features

| Feature | Description |
|---|---|
| **Image Labeling** | Identifies objects, animals, and places in photographs |
| **Selfie Segmentation** | Isolates a person from the background with a green mask overlay |
| **Face Detection** | Detects faces with landmarks, contours, expressions (smile, eye state), and head pose |
| **Scan History** | SQLite-backed persistence of all scan results with image thumbnails |
| **Authentication** | Email/password auth with registration and password reset via Firebase |
| **Settings** | Theme, language, sound, vibration, and notification preferences persisted locally |
| **Notifications** | Daily local push reminder to use the app |
| **Multilingual** | Full support for English, French, and Arabic (RTL) |

---

## 2. Architecture

### 2.1 Architectural Pattern

The project follows a **Service-Oriented Architecture** with **Provider** for state management. It is not a strict MVVM or Clean Architecture implementation, but rather a pragmatic layered approach well-suited for a medium-complexity Flutter app:

```
┌─────────────────────────────────────────────┐
│                  UI Layer                    │
│         (Screens / Widgets)                  │
│  StatelessWidget  │  StatefulWidget          │
├─────────────────────────────────────────────┤
│              State Management                │
│      SettingsProvider (ChangeNotifier)        │
│      via Provider package                    │
├─────────────────────────────────────────────┤
│              Service Layer                   │
│  AuthService │ MLService │ DatabaseService   │
│  NotificationService │ SoundService          │
├─────────────────────────────────────────────┤
│           Data / External Layer              │
│  Firebase Auth │ ML Kit │ SQLite │ SharedPrefs│
└─────────────────────────────────────────────┘
```

**Why this pattern?** The project avoids over-engineering. For a feature-limited ML demo app, a full Clean Architecture (repositories, use cases, entities) would be overkill. The service layer provides enough decoupling between UI and business logic while keeping the codebase concise and readable.

### 2.2 Folder Structure

```
lib/
├── main.dart                  # Entry point: Firebase init, provider setup, app launch
├── app.dart                   # Root MaterialApp: theme, locale, routes, auth gate
├── firebase_options.dart      # FlutterFire CLI-generated Firebase config
├── l10n/                      # Localization
│   ├── app_en.arb             # English translations (template)
│   ├── app_fr.arb             # French translations
│   ├── app_ar.arb             # Arabic translations
│   ├── app_localizations.dart # Generated abstract class
│   ├── app_localizations_en.dart
│   ├── app_localizations_fr.dart
│   └── app_localizations_ar.dart
├── models/
│   └── scan_result.dart       # Data model for saved ML scan results
├── providers/
│   └── settings_provider.dart # App-wide settings (theme, locale, toggles)
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── home_screen.dart
│   ├── image_labeling_screen.dart
│   ├── selfie_segmentation_screen.dart
│   ├── face_detection_screen.dart
│   ├── history_screen.dart
│   ├── settings_screen.dart
│   └── about_screen.dart
├── services/
│   ├── auth_service.dart       # Firebase Auth wrapper
│   ├── ml_service.dart         # ML Kit operations (labeling, segmentation, face)
│   ├── database_service.dart   # SQLite CRUD for scan history
│   ├── notification_service.dart # Local notification scheduling
│   └── sound_service.dart      # System sound & haptic feedback
└── widgets/
    └── result_card.dart        # Reusable result display card
```

### 2.3 Entry Point Flow

```
main() ─→ Firebase.initializeApp()
       ─→ SettingsProvider.init() (load SharedPreferences)
       ─→ NotificationService.init() (setup notification channel)
       ─→ Schedule daily reminder (if enabled)
       ─→ Set edge-to-edge system UI
       ─→ runApp(ChangeNotifierProvider → VisionAIApp)
```

### 2.4 Dependency Flow

```
Screens ──→ Services (AuthService, MLService, DatabaseService, SoundService)
Screens ──→ Provider (SettingsProvider via Provider.of<>)
Services ──→ External SDKs (Firebase Auth, ML Kit, SQLite, SharedPreferences)
Models ←──→ DatabaseService (ScanResult ↔ SQLite rows)
```

Key design decision: **Services are stateless utilities** (static methods on `MLService`, `SoundService`) or **singletons** (`DatabaseService`, `NotificationService`). This avoids dependency injection complexity while ensuring shared state (DB instance, notification plugin) isn't duplicated.

---

## 3. UI Layer (Flutter Widgets)

### 3.1 Screen Map

| Screen | Route | Type | Description |
|---|---|---|---|
| `LoginScreen` | *home* (unauthenticated) | `StatefulWidget` | Email/password login with form validation |
| `RegisterScreen` | `/register` | `StatefulWidget` | New account registration with password confirmation |
| `ForgotPasswordScreen` | `/forgot-password` | `StatefulWidget` | Password reset via email |
| `HomeScreen` | `/home` | `StatelessWidget` | Main hub with feature cards & navigation drawer |
| `ImageLabelingScreen` | `/image-labeling` | `StatefulWidget` | Pick image → label objects → save results |
| `SelfieSegmentationScreen` | `/selfie-segmentation` | `StatefulWidget` | Pick selfie → segment person → show overlay |
| `FaceDetectionScreen` | `/face-detection` | `StatefulWidget` | Pick image → detect faces → show details |
| `HistoryScreen` | `/history` | `StatefulWidget` | Browse & delete saved scan results |
| `SettingsScreen` | `/settings` | `StatelessWidget` | Theme, language, sound, vibration, notifications |
| `AboutScreen` | `/about` | `StatelessWidget` | App info & ML Kit API description |

### 3.2 Widget Hierarchy

```
VisionAIApp (MaterialApp)
├── StreamBuilder<User?> (Auth gate)
│   ├── LoginScreen (unauthenticated)
│   │   └── Form → TextFormField(email) + TextFormField(password)
│   └── HomeScreen (authenticated)
│       ├── AppBar (actions: about, history, settings)
│       ├── Drawer (user info, nav items, logout)
│       └── ListView
│           ├── _FeatureCard (Image Labeling)
│           ├── _FeatureCard (Selfie Segmentation)
│           └── _FeatureCard (Face Detection)
├── ImageLabelingScreen
│   ├── Camera/Gallery buttons
│   ├── Image.file (picked image)
│   ├── CircularProgressIndicator (processing)
│   ├── List<ResultCard> (detected labels)
│   └── Save button
├── SelfieSegmentationScreen
│   ├── Camera/Gallery buttons
│   ├── Stack [Image.file + Opacity(Image.memory(mask))]
│   ├── CircularProgressIndicator (processing)
│   ├── Card (person percentage)
│   └── Save button
├── FaceDetectionScreen
│   ├── Camera/Gallery buttons
│   ├── Image.file (picked image)
│   ├── CircularProgressIndicator (processing)
│   ├── List<Card> (per face: bounding box, smile, eyes, angles)
│   └── Save button
└── ...
```

### 3.3 State Management

**Primary:** `Provider` package with `ChangeNotifierProvider`.

Only one provider exists — `SettingsProvider` — which manages global app-wide settings (theme, locale, sound, vibration, notifications). It is created in `main()` before the widget tree and injected via `ChangeNotifierProvider.value`.

**Per-screen state:** Each ML feature screen uses local `setState()` to manage:
- `_imageFile` — the currently picked image
- `_isProcessing` — loading indicator flag
- ML results (`_labels`, `_maskOverlay`, `_faces`)

**Why `setState` over more providers?** The ML processing state is screen-local and ephemeral. It doesn't need to be shared across widgets or survive navigation. Using `setState` here is the simplest correct approach.

### 3.4 Navigation System

The app uses **named routes** defined in `MaterialApp.routes`:

```dart
routes: {
  '/register':            (_) => const RegisterScreen(),
  '/forgot-password':     (_) => const ForgotPasswordScreen(),
  '/home':                (_) => const HomeScreen(),
  '/image-labeling':      (_) => const ImageLabelingScreen(),
  '/selfie-segmentation': (_) => const SelfieSegmentationScreen(),
  '/face-detection':      (_) => const FaceDetectionScreen(),
  '/history':             (_) => const HistoryScreen(),
  '/settings':            (_) => const SettingsScreen(),
  '/about':               (_) => const AboutScreen(),
}
```

The **auth gate** is implemented not via routes but via a `StreamBuilder<User?>` on `FirebaseAuth.instance.authStateChanges()` as the `home` property. This ensures:
- When a user signs in → the stream emits the user → `HomeScreen` is shown
- When a user signs out → the stream emits `null` → `LoginScreen` is shown
- No explicit navigation is needed on login/logout

### 3.5 Reusable Widgets

| Widget | File | Description |
|---|---|---|
| `ResultCard` | `widgets/result_card.dart` | Generic `Card` + `ListTile` with title, subtitle, and icon for displaying ML results |
| `_FeatureCard` | `home_screen.dart` (private) | Navigation card with icon, title, description, and route |
| `_InfoRow` | `face_detection_screen.dart` (private) | Icon + label + value row for face attribute display |
| `_ServiceTile` | `about_screen.dart` (private) | Icon + title + description for ML Kit service listing |

### 3.6 Theming

Material 3 (`useMaterial3: true`) with `ColorScheme.fromSeed(seedColor: Colors.blue)`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
),
darkTheme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
),
```

Theme mode is controlled by `SettingsProvider.themeMode` and persisted to `SharedPreferences`.

---

## 4. Firebase Integration

### 4.1 Firebase Services Used

| Service | Package | Purpose |
|---|---|---|
| **Firebase Core** | `firebase_core: ^3.13.0` | Required initialization layer |
| **Firebase Auth** | `firebase_auth: ^5.5.2` | Email/password authentication |

The project does **not** use Firestore, Realtime Database, Cloud Storage, Cloud Functions, Hosting, Analytics, or Cloud Messaging. Data persistence is handled locally via SQLite, and notifications are local (not push via FCM).

### 4.2 Firebase Configuration

**Project ID:** `projetmobile-abcd6`

Configuration is generated by the **FlutterFire CLI** and stored in:

| File | Purpose |
|---|---|
| `lib/firebase_options.dart` | Dart-side Firebase options (API key, app ID, project ID) |
| `android/app/google-services.json` | Android-side Google Services config |
| `android/settings.gradle.kts` | Applies `com.google.gms.google-services` plugin v4.3.15 |
| `android/app/build.gradle.kts` | Applies `com.google.gms.google-services` plugin |
| `firebase.json` | Root FlutterFire CLI metadata |

Only the **Android** platform is configured. iOS, macOS, web, Windows, and Linux throw `UnsupportedError` in `firebase_options.dart`.

### 4.3 Firebase Initialization

```dart
// main.dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

This is called once in `main()` before any Firebase service is used.

### 4.4 Authentication Flow

```
┌──────────┐     ┌──────────────┐     ┌───────────┐
│  Login   │────→│ AuthService  │────→│ Firebase  │
│  Screen  │     │  .signIn()   │     │   Auth    │
└──────────┘     └──────────────┘     └───────────┘
                                            │
                                            ▼
                                    authStateChanges()
                                            │
                                            ▼
                                   ┌────────────────┐
                                   │  StreamBuilder  │
                                   │  in app.dart    │
                                   └────────────────┘
                                     │           │
                                  User?       null?
                                     ▼           ▼
                                HomeScreen   LoginScreen
```

**`AuthService`** (`services/auth_service.dart`) is a thin wrapper around `FirebaseAuth`:

| Method | Firebase Method | Description |
|---|---|---|
| `signIn(email, password)` | `signInWithEmailAndPassword` | Standard login |
| `signUp(email, password)` | `createUserWithEmailAndPassword` | New registration |
| `sendPasswordResetEmail(email)` | `sendPasswordResetEmail` | Forgot password |
| `signOut()` | `signOut` | Logout |
| `currentUser` | `.currentUser` | Getter for current user |
| `authStateChanges` | `.authStateChanges()` | Reactive auth state stream |

**Auth guard pattern:** The `StreamBuilder` in `app.dart` acts as a reactive gate. There is no route guard or middleware — the stream inherently controls which screen is shown. Signing in changes the stream value, which triggers a rebuild showing `HomeScreen`. Signing out reverses this.

**Error handling in auth screens:** `FirebaseAuthException` is caught and displayed inline as `_errorMessage`. A loading indicator replaces the submit button during async operations.

### 4.5 Form Validation

| Field | Validation Rule |
|---|---|
| Email | Non-empty and contains `@` |
| Password | Minimum 6 characters |
| Confirm Password | Must match the password field |

---

## 5. ML Kit Integration

### 5.1 ML Kit Features Used

| Feature | Package | ML Kit API |
|---|---|---|
| **Image Labeling** | `google_mlkit_image_labeling: ^0.14.2` | `ImageLabeler` |
| **Selfie Segmentation** | `google_mlkit_selfie_segmentation: ^0.10.1` | `SelfieSegmenter` |
| **Face Detection** | `google_mlkit_face_detection: ^0.13.2` | `FaceDetector` |

All three use **on-device** models, meaning no network calls are made for ML processing. The models are bundled with the app.

### 5.2 Central ML Service

All ML Kit operations are centralized in `MLService` (`services/ml_service.dart`) as **static methods**. Each method:
1. Creates a new ML Kit detector instance
2. Processes the input image
3. Closes the detector in a `finally` block (critical to avoid memory leaks)

This create-process-close pattern ensures detectors are not kept alive unnecessarily.

### 5.3 Image Labeling

**Purpose:** Identifies objects, animals, places, activities, and more in a photograph.

**Configuration:**
```dart
ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5))
```
- Confidence threshold of 0.5 (50%) filters out low-confidence labels

**Data flow:**
```
User picks image (camera/gallery)
  → File passed to MLService.labelImage()
    → InputImage.fromFile(imageFile)
    → ImageLabeler.processImage(inputImage)
    → Returns List<ImageLabel> [label text, confidence 0.0-1.0, index]
  → UI displays each label in a ResultCard
  → User can save → encode labels as JSON → insert into SQLite
```

**Saved data format (JSON):**
```json
[
  {"label": "Dog", "confidence": 0.92, "index": 0},
  {"label": "Animal", "confidence": 0.87, "index": 1}
]
```

### 5.4 Selfie Segmentation

**Purpose:** Separates the person (foreground) from the background in a selfie-style image.

**Configuration:**
```dart
SelfieSegmenter(
  mode: SegmenterMode.single,    // Optimized for still images (not video stream)
  enableRawSizeMask: true,       // Mask dimensions match raw input image
)
```

**Data flow:**
```
User picks image
  → MLService.segmentSelfie(imageFile)
    → SelfieSegmenter.processImage() → SegmentationMask
  → MLService.maskToOverlayImage(mask)
    → For each pixel: if confidence > 0.5, render green (R:76, G:175, B:80)
    → Convert RGBA pixels → ui.Image → PNG bytes (Uint8List)
  → MLService.calculatePersonPercentage(mask)
    → Count pixels with confidence > 0.5 / total pixels → percentage
  → UI shows Stack: original image + semi-transparent green overlay (60% opacity)
  → Save: personPercentage stored as JSON in SQLite
```

**Mask overlay generation** is the most computationally interesting part of this project. The method:
1. Iterates over all pixel confidences from the segmentation mask
2. Creates a raw RGBA byte array (4 bytes per pixel)
3. Marks person pixels as green with opacity proportional to confidence
4. Uses `ui.decodeImageFromPixels` to convert raw bytes to a `ui.Image`
5. Encodes to PNG via `image.toByteData(format: ui.ImageByteFormat.png)`

**Saved data format (JSON):**
```json
{"personPercentage": 67.3}
```

### 5.5 Face Detection

**Purpose:** Detects faces in an image with detailed attributes.

**Configuration:**
```dart
FaceDetector(options: FaceDetectorOptions(
  enableClassification: true,   // Smile & eye-open probabilities
  enableLandmarks: true,        // Eye, nose, mouth, ear positions
  enableContours: true,         // Face outline points
  enableTracking: true,         // Unique face tracking IDs
  performanceMode: FaceDetectorMode.accurate,  // Accuracy over speed
))
```

All options are enabled for maximum data extraction. `FaceDetectorMode.accurate` is chosen because the app processes still images (not video), so latency is acceptable.

**Data flow:**
```
User picks image
  → MLService.detectFaces(imageFile)
    → FaceDetector.processImage() → List<Face>
  → UI displays per face:
    - Bounding box position & dimensions
    - Smiling probability (0-100%)
    - Left/Right eye open probability
    - Head Euler angles Y (yaw) and Z (roll)
    - Tracking ID (if available)
  → Save: face count + per-face attributes as JSON in SQLite
```

**Saved data format (JSON):**
```json
{
  "facesCount": 2,
  "faces": [
    {
      "smiling": 0.85,
      "leftEyeOpen": 0.95,
      "rightEyeOpen": 0.92,
      "headAngleY": -3.2,
      "headAngleZ": 1.1
    }
  ]
}
```

### 5.6 ML Kit — Design Decisions

| Decision | Rationale |
|---|---|
| Static methods on `MLService` | ML Kit detectors are stateless and short-lived; no need for instance state |
| Create-process-close pattern | Prevents native memory leaks from long-lived detector instances |
| Confidence threshold 0.5 | Balanced between showing useful results and filtering noise |
| `SegmenterMode.single` | App processes single images, not video streams |
| `FaceDetectorMode.accurate` | Still-image context allows trading speed for precision |
| Green overlay for segmentation | Visually clear way to show segmentation without complex compositing |

---

## 6. Dependencies & Packages

### 6.1 Production Dependencies

| Package | Version | Purpose | Where Used |
|---|---|---|---|
| `flutter` (SDK) | — | Core framework | Everywhere |
| `flutter_localizations` (SDK) | — | Material/Cupertino l10n delegates | `app.dart` |
| `cupertino_icons` | ^1.0.8 | iOS-style icons | UI elements |
| `firebase_core` | ^3.13.0 | Firebase initialization | `main.dart` |
| `firebase_auth` | ^5.5.2 | Email/password authentication | `auth_service.dart`, auth screens |
| `google_mlkit_image_labeling` | ^0.14.2 | On-device image labeling | `ml_service.dart`, `image_labeling_screen.dart` |
| `google_mlkit_selfie_segmentation` | ^0.10.1 | Person/background separation | `ml_service.dart`, `selfie_segmentation_screen.dart` |
| `google_mlkit_face_detection` | ^0.13.2 | Face detection with attributes | `ml_service.dart`, `face_detection_screen.dart` |
| `image_picker` | ^1.1.2 | Camera/gallery image selection | All ML feature screens |
| `sqflite` | ^2.4.2 | Local SQLite database | `database_service.dart` |
| `path` | ^1.9.1 | Path manipulation utilities | `database_service.dart` |
| `path_provider` | ^2.1.5 | App documents directory | ML screens (image persistence) |
| `flutter_local_notifications` | ^18.0.1 | Scheduled local notifications | `notification_service.dart` |
| `provider` | ^6.1.5 | State management (ChangeNotifier) | `main.dart`, `app.dart`, feature screens |
| `shared_preferences` | ^2.3.5 | Key-value persistent settings | `settings_provider.dart` |
| `intl` | ^0.20.2 | Internationalization utilities | Generated l10n code |

### 6.2 Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` (SDK) | — | Testing framework |
| `flutter_lints` | ^6.0.0 | Recommended lint rules |

### 6.3 Dependency Rationale

- **No Firestore/RTDB:** All data is device-local (scan history, settings). SQLite + SharedPreferences are sufficient and keep the app fully functional offline.
- **No `firebase_messaging`:** Notifications are local reminders, not server-triggered. `flutter_local_notifications` handles this without FCM complexity.
- **`provider` over Riverpod/Bloc:** A single settings provider doesn't justify the boilerplate of Bloc or the complexity of Riverpod. Provider is the simplest viable choice.
- **Separate `google_mlkit_*` packages:** Each ML Kit feature is a standalone package (not a monolithic SDK), keeping APK size manageable by including only used models.

---

## 7. Business Logic & Data Flow

### 7.1 Application State Diagram

```
                     ┌─────────────┐
                     │  App Start  │
                     └──────┬──────┘
                            │
               ┌────────────┼────────────┐
               ▼            ▼            ▼
        Firebase Init  Settings Init  Notifications Init
               │            │            │
               └────────────┼────────────┘
                            │
                            ▼
                   ┌────────────────┐
                   │ Auth Check     │
                   │ (StreamBuilder)│
                   └───┬────────┬──┘
                  null │        │ User
                       ▼        ▼
                LoginScreen  HomeScreen ──→ ML Screens
                                           │
                                   ┌───────┼───────┐
                                   ▼       ▼       ▼
                              Labeling  Selfie   Face
                                   │       │       │
                                   └───────┼───────┘
                                           ▼
                                    DatabaseService
                                    (SQLite persist)
                                           │
                                           ▼
                                    HistoryScreen
                                    (view/delete)
```

### 7.2 ML Processing Flow (Generic)

Every ML feature screen follows the same pattern:

```dart
1. User taps Camera or Gallery button
2. ImagePicker opens native picker → returns XFile
3. setState: _imageFile = File(path), _isProcessing = true
4. MLService.<feature>(imageFile) → await async processing
5. setState: store results, _isProcessing = false
6. SoundService.playFeedback(settings)  // if enabled
7. User optionally taps Save:
   a. Copy image to app documents directory
   b. Encode results as JSON string
   c. Create ScanResult model
   d. DatabaseService().insertResult(scanResult)
   e. Show SnackBar confirmation
```

### 7.3 Data Persistence

**Two persistence mechanisms:**

| Mechanism | Package | Data | Scope |
|---|---|---|---|
| **SharedPreferences** | `shared_preferences` | Settings (theme, locale, toggles) | Key-value pairs |
| **SQLite** | `sqflite` | Scan results + image paths | Relational table |

**SQLite Schema:**

```sql
CREATE TABLE scan_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,          -- 'labeling', 'selfie_segmentation', 'face_detection'
  imagePath TEXT NOT NULL,     -- Absolute path to saved image file
  resultData TEXT NOT NULL,    -- JSON-encoded ML results
  timestamp TEXT NOT NULL      -- ISO 8601 string
);
```

**SharedPreferences Keys:**

| Key | Type | Default | Description |
|---|---|---|---|
| `isDarkMode` | `bool` | `false` | Dark theme enabled |
| `locale` | `String` | `'fr'` | Language code |
| `soundEnabled` | `bool` | `true` | System click sound on ML completion |
| `vibrationEnabled` | `bool` | `true` | Haptic feedback on ML completion |
| `notificationsEnabled` | `bool` | `true` | Daily reminder notification |

### 7.4 Error Handling Strategy

The project uses a consistent try/catch pattern in all async operations:

```dart
try {
  // Async work (ML processing, auth, DB)
} on SpecificException catch (e) {
  // Show error in UI (SnackBar or inline text)
} catch (e) {
  // Generic fallback
} finally {
  if (mounted) setState(() => _isLoading = false);
}
```

**Key patterns:**
- `mounted` checks before `setState` or `ScaffoldMessenger` calls to avoid "setState called after dispose" errors
- Firebase auth errors display `FirebaseAuthException.message` to the user
- ML Kit errors show a generic error SnackBar
- No global error boundary or crash reporting — errors are handled per-screen

### 7.5 Image Lifecycle

When a user saves an ML scan result, the image undergoes:

```
1. Original image (camera/gallery) → temporary path (cache dir)
2. File.copy() → app documents directory (persistent)
   filename: <type>_<millisecondsSinceEpoch>.jpg
3. Persistent path stored in SQLite (imagePath column)
4. On deletion: File.delete() + DB row delete
5. On "clear all": iterate all results → delete files → clear table
```

This is important because the original image from `ImagePicker` is in a temporary directory that the OS may clean up. Copying to the documents directory ensures long-term persistence.

---

## 8. Security & Best Practices

### 8.1 Authentication Security

| Aspect | Implementation | Assessment |
|---|---|---|
| Password storage | Delegated to Firebase Auth (bcrypt-hashed server-side) | Secure |
| Password minimum length | 6 characters (Firebase default) | Adequate for demo; production should require 8+ |
| Email validation | Basic `contains('@')` check | Minimal; does not validate format fully |
| Auth state management | `FirebaseAuth.authStateChanges()` stream | Correct reactive pattern |
| Session persistence | Firebase Auth handles token refresh automatically | Secure |

### 8.2 Data Security

| Aspect | Status | Notes |
|---|---|---|
| SQLite encryption | Not implemented | Data at rest is unencrypted. For sensitive data, consider `sqflite_sqlcipher` |
| Image storage | Plain files in app documents | Accessible via root/ADB. Acceptable for non-sensitive ML results |
| Firebase API key | Hardcoded in `firebase_options.dart` | Normal for Firebase client SDKs — keys are restricted by Firebase Security Rules and app SHA |
| No user data in Firestore | N/A | No cloud database means no server-side security rules needed |

### 8.3 Input Validation

| Location | Validation |
|---|---|
| Login form | Email format + password length |
| Register form | Email + password length + password match |
| Image picker | Null check (user cancels) |
| ML results | Null/empty checks before saving |
| History deletion | Confirmation dialog before delete |

### 8.4 Potential Risks & Recommendations

| Risk | Severity | Recommendation |
|---|---|---|
| No rate limiting on auth attempts | Low | Firebase Auth has built-in rate limiting; no client-side mitigation needed |
| Hardcoded notification text in French | Low | Move to localization strings for consistency |
| No input sanitization on email before trimming | Low | `trim()` is applied; SQL injection is N/A (parameterized queries via sqflite) |
| Image files not cleaned up on app uninstall | Low | Android handles this — app documents dir is removed with the app |
| No network error handling for auth | Medium | If offline, Firebase Auth throws — displayed as raw error message. Consider user-friendly offline detection |

---

## 9. Configuration & Environment

### 9.1 Firebase Setup

| Config File | Location | Generated By |
|---|---|---|
| `firebase.json` | Project root | FlutterFire CLI |
| `firebase_options.dart` | `lib/` | FlutterFire CLI |
| `google-services.json` | `android/app/` | Firebase Console / FlutterFire CLI |

**To reconfigure Firebase for a new project:**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run configuration
flutterfire configure
```

### 9.2 Android Build Configuration

| Property | Value | File |
|---|---|---|
| `applicationId` | `com.example.projet_ds` | `android/app/build.gradle.kts` |
| `minSdk` | 24 (Android 7.0) | `android/app/build.gradle.kts` |
| `targetSdk` | Flutter default | `android/app/build.gradle.kts` |
| `compileSdk` | Flutter default | `android/app/build.gradle.kts` |
| Java compatibility | 17 | `android/app/build.gradle.kts` |
| Kotlin version | 2.2.20 | `android/settings.gradle.kts` |
| AGP version | 8.11.1 | `android/settings.gradle.kts` |
| Core library desugaring | `com.android.tools:desugar_jdk_libs:2.1.4` | `android/app/build.gradle.kts` |

**`minSdk: 24`** is required by the ML Kit packages. ML Kit face detection and selfie segmentation require at least API 24.

**Core library desugaring** is enabled to support newer Java APIs on older Android versions (required by `flutter_local_notifications`).

### 9.3 Localization Configuration

Defined in `l10n.yaml`:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

The `flutter generate: true` flag in `pubspec.yaml` triggers automatic code generation from `.arb` files.

**Supported locales:** `en`, `fr`, `ar`

**Default locale:** `fr` (French) — hardcoded in `SettingsProvider._locale`.

Arabic support enables RTL layout automatically via Flutter's built-in `GlobalWidgetsLocalizations`.

### 9.4 Lint Configuration

Uses `package:flutter_lints/flutter.yaml` — the standard recommended Flutter linting rules with no custom overrides.

---

## 10. Performance & Optimization

### 10.1 Observed Optimizations

| Optimization | Location | Impact |
|---|---|---|
| **Singleton pattern** for DB & Notifications | `DatabaseService`, `NotificationService` | Single shared instance avoids repeated initialization |
| **Create-close pattern** for ML detectors | `MLService` | Frees native memory immediately after use |
| **`const` constructors** | Throughout widgets | Enables Flutter's compile-time constant optimization |
| **`mounted` checks** | All StatefulWidget async callbacks | Prevents setState on disposed widgets |
| **Lazy database initialization** | `DatabaseService.database` getter | DB is created only when first accessed |
| **`enableRawSizeMask: true`** | Selfie segmentation | Avoids a resize step in the segmentation pipeline |
| **Edge-to-edge UI** | `main.dart` | Modern immersive UI appearance |

### 10.2 Potential Bottlenecks

| Area | Issue | Impact |
|---|---|---|
| **Selfie mask generation** | Iterates every pixel + creates `ui.Image` from raw bytes | O(width × height) — can be slow on high-resolution images |
| **Image copying on save** | Full file copy to documents directory | I/O bound; large images may cause brief UI jank |
| **History screen thumbnails** | `Image.file()` for each list item without caching | Scroll performance may degrade with many items |
| **No image resizing** | Full-resolution images passed to ML Kit | Higher processing time on high-MP camera images |
| **Synchronous `existsSync()`** | `imageFile.existsSync()` in history list builder | Blocks UI thread; should be async |

### 10.3 Improvement Suggestions

| Suggestion | Priority | Effort |
|---|---|---|
| **Resize images before ML processing** (e.g., max 1024px width) | High | Low |
| **Cache thumbnails** in history screen using `Image.file` with fixed `cacheWidth` | Medium | Low |
| **Use `Isolate.run`** for selfie mask pixel manipulation | Medium | Medium |
| **Add pagination** to history screen for large datasets | Low | Medium |
| **Replace `existsSync` with `exist()`** (async) in history screen | Low | Low |
| **Preload ML models** on app start for faster first-scan experience | Low | Medium |

---

## 11. Developer Guide

### 11.1 Prerequisites

- **Flutter SDK** ^3.10.7
- **Android Studio** or **VS Code** with Flutter/Dart plugins
- **Android device or emulator** (API 24+) — ML Kit does not work on desktop/web
- **Firebase project** configured (or use the existing `projetmobile-abcd6`)

### 11.2 Getting Started

```bash
# 1. Clone the repository
git clone <repo-url>
cd projet_ds

# 2. Install dependencies
flutter pub get

# 3. Generate localization files (if l10n files are missing)
flutter gen-l10n

# 4. Run on a connected Android device/emulator
flutter run
```

### 11.3 Building for Release

```bash
# Build APK (universal)
flutter build apk

# Build APK per ABI (recommended for distribution)
flutter build apk --split-per-abi

# Build App Bundle (for Google Play)
flutter build appbundle
```

> **Note:** The release build currently uses debug signing keys. For production, configure a signing key in `android/app/build.gradle.kts`.

### 11.4 Adding a New ML Kit Feature

Follow this pattern to add a new ML Kit feature (e.g., text recognition):

**Step 1: Add the package**
```yaml
# pubspec.yaml
google_mlkit_text_recognition: ^latest
```

**Step 2: Add the ML method to `MLService`**
```dart
// services/ml_service.dart
static Future<RecognizedText> recognizeText(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile);
  final recognizer = TextRecognizer();
  try {
    return await recognizer.processImage(inputImage);
  } finally {
    recognizer.close();
  }
}
```

**Step 3: Create the screen** (copy an existing ML screen as template)
- Add camera/gallery buttons
- Call `MLService.recognizeText()`
- Display results
- Add save-to-DB logic with JSON encoding

**Step 4: Register the route**
```dart
// app.dart → routes map
'/text-recognition': (context) => const TextRecognitionScreen(),
```

**Step 5: Add a feature card to HomeScreen**

**Step 6: Add localization strings** to all 3 `.arb` files

**Step 7: Handle the new type in `HistoryScreen._getTypeLabel()` and `_getResultSummary()`**

### 11.5 Adding a New Language

1. Create `lib/l10n/app_xx.arb` (copy `app_en.arb` as template)
2. Translate all string values
3. Add the locale to `app.dart`:
   ```dart
   supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar'), Locale('xx')],
   ```
4. Add a `DropdownMenuItem` in `settings_screen.dart`
5. Run `flutter gen-l10n`

### 11.6 Key Concepts for New Developers

1. **Auth gate pattern:** Authentication is not handled via route guards. The `StreamBuilder` in `app.dart` reactively switches between `LoginScreen` and `HomeScreen`. Never manually navigate to `/home` after login — the stream handles it.

2. **ML Kit lifecycle:** Always close ML Kit detectors after use. The `finally` block in `MLService` is critical. Failing to close detectors will leak native memory.

3. **Image persistence:** Images from `ImagePicker` are temporary. If you need them long-term, copy them to `getApplicationDocumentsDirectory()` before the user navigates away.

4. **Settings reactivity:** `SettingsProvider` extends `ChangeNotifier`. Any widget consuming it via `Provider.of<SettingsProvider>(context)` will rebuild when settings change. Use `listen: false` for one-time reads (e.g., in button callbacks).

5. **Localization:** All user-visible strings must go through `AppLocalizations.of(context)!`. Never hardcode display text. After modifying `.arb` files, run `flutter gen-l10n` to regenerate Dart classes.

6. **Database is local-only:** There is no cloud sync. Each device has its own isolated scan history. If the app is uninstalled, all data is lost.

7. **Notification text is hardcoded in French** in `notification_service.dart`. This is a known limitation — it should ideally use localized strings, but `NotificationService.scheduleDailyReminder()` runs outside the widget tree where `BuildContext` is unavailable.

### 11.7 Project File Quick Reference

| Need to... | Go to... |
|---|---|
| Change Firebase config | `lib/firebase_options.dart` |
| Add a new screen | `lib/screens/` + register route in `app.dart` |
| Add a new ML feature | `lib/services/ml_service.dart` |
| Change DB schema | `lib/services/database_service.dart` (_onCreate) |
| Add a setting | `lib/providers/settings_provider.dart` |
| Add a translation | `lib/l10n/app_*.arb` files |
| Change theme colors | `lib/app.dart` (seedColor) |
| Change minimum Android SDK | `android/app/build.gradle.kts` |
| Add a dependency | `pubspec.yaml` |

---

## Appendix A: Complete Route Map

```
/                       → Auth gate (StreamBuilder)
  ├── [unauthenticated] → LoginScreen
  └── [authenticated]   → HomeScreen
/register               → RegisterScreen
/forgot-password        → ForgotPasswordScreen
/home                   → HomeScreen
/image-labeling         → ImageLabelingScreen
/selfie-segmentation    → SelfieSegmentationScreen
/face-detection         → FaceDetectionScreen
/history                → HistoryScreen
/settings               → SettingsScreen
/about                  → AboutScreen
```

## Appendix B: Localization Keys Count

| Locale | Keys | File |
|---|---|---|
| English | 72 | `lib/l10n/app_en.arb` |
| French | 72 | `lib/l10n/app_fr.arb` |
| Arabic | 72 | `lib/l10n/app_ar.arb` |

## Appendix C: Data Model Reference

### ScanResult

```dart
class ScanResult {
  final int? id;          // Auto-increment PK (null on creation)
  final String type;      // 'labeling' | 'selfie_segmentation' | 'face_detection'
  final String imagePath; // Absolute filesystem path to saved image
  final String resultData;// JSON-encoded ML results
  final String timestamp; // ISO 8601 datetime string
}
```

### SQLite ↔ Dart mapping

| SQLite Column | Dart Field | Type |
|---|---|---|
| `id` | `id` | `int?` |
| `type` | `type` | `String` |
| `imagePath` | `imagePath` | `String` |
| `resultData` | `resultData` | `String` |
| `timestamp` | `timestamp` | `String` |
