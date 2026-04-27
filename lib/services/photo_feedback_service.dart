import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// A single actionable tip from the photo analysis.
class PhotoTip {
  final IconData icon;
  final String message;
  final TipType type;

  const PhotoTip(this.icon, this.message, this.type);
}

/// Classification of a tip so the UI can colour-code it.
enum TipType { good, warning, suggestion, info }

/// Pure logic service: turns ML Kit results into a quality score and tips.
/// No UI code here — keep all ML imports + logic isolated from widgets.
class PhotoFeedbackService {
  // ── Score ──────────────────────────────────────────────────────────────────

  /// Compute a 0–100 quality score using a strict penalty-based system.
  /// Starts at 100 and aggressively deducts for every detected flaw.
  /// A neutral/average image should land around 40–55, not 80+.
  static int computeScore({
    required List<Face> faces,
    required List<ImageLabel> labels,
    required double? personPercentage,
  }) {
    int score = 100;

    final names = labels.map((l) => l.label.toLowerCase()).toSet();

    // ── CRITICAL: No face detected ───────────────────────────────────────────
    if (faces.isEmpty) {
      // If person is visible but face not found → face is hidden or profile
      if (personPercentage != null && personPercentage > 8) {
        score -= 40; // face hidden / side profile / heavily obscured
      } else {
        score -= 50; // no person at all in frame
      }
      // Without a face we can still evaluate framing/lighting below
    } else {
      final face = faces.first;
      final smiling = face.smilingProbability ?? 0.5;
      final leftOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightOpen = face.rightEyeOpenProbability ?? 1.0;
      final headY = face.headEulerAngleY ?? 0.0; // left-right yaw
      final headZ = face.headEulerAngleZ ?? 0.0; // roll / tilt

      // ── Eyes closed ──────────────────────────────────────────────────────
      if (leftOpen < 0.3 && rightOpen < 0.3) {
        score -= 25; // both eyes fully closed
      } else if (leftOpen < 0.3 || rightOpen < 0.3) {
        score -= 15; // one eye closed / blinking
      } else if (leftOpen < 0.6 || rightOpen < 0.6) {
        score -= 8; // squinting
      }

      // ── Not looking at camera (side profile / turned away) ───────────────
      final absY = headY.abs();
      final absZ = headZ.abs();
      if (absY > 35) {
        score -= 25; // strong side profile
      } else if (absY > 20) {
        score -= 15; // notably turned away
      } else if (absY > 12) {
        score -= 7; // slight turn
      }

      // ── Head roll (tilted sideways) ──────────────────────────────────────
      if (absZ > 25) {
        score -= 12;
      } else if (absZ > 15) {
        score -= 6;
      }

      // ── Expression / smile ───────────────────────────────────────────────
      if (smiling < 0.2) {
        score -= 12; // flat / unhappy expression
      } else if (smiling < 0.4) {
        score -= 6; // neutral expression
      }
      // No bonus for smiling — avoid inflating scores

      // ── Tracking confidence: very low values mean ML Kit is unsure ───────
      // face.trackingId is null when confidence is poor, not a reliable proxy.
      // Instead use smilingProbability being null as a low-confidence signal.
      if (face.smilingProbability == null &&
          face.leftEyeOpenProbability == null) {
        score -= 10; // ML Kit returned minimal data — likely poor face quality
      }

      // ── Multiple faces (group shot — not ideal for a selfie) ─────────────
      if (faces.length > 1) {
        score -= 10;
      }
    }

    // ── FRAMING / COMPOSITION ────────────────────────────────────────────────
    if (personPercentage != null) {
      if (personPercentage < 3) {
        score -= 25; // subject barely visible — far too small
      } else if (personPercentage < 8) {
        score -= 18; // subject too small
      } else if (personPercentage < 15) {
        score -= 8; // slightly too small / distant
      } else if (personPercentage >= 80) {
        score -= 20; // face completely fills frame — forehead/chin cut off
      } else if (personPercentage >= 65) {
        score -= 10; // too close, likely cropped
      }
      // Ideal range 15–55%: no penalty
    } else {
      // Could not determine framing — mild penalty for uncertainty
      score -= 8;
    }

    // ── LIGHTING ─────────────────────────────────────────────────────────────
    if (names.any(
      (n) => n.contains('dark') || n.contains('night') || n == 'darkness',
    )) {
      score -= 20; // poor / dim lighting
    } else if (names.any((n) => n.contains('shadow'))) {
      score -= 10; // strong shadows on face
    }
    // No bonus for natural light — avoid inflation

    // ── SCENE CLUTTER / DISTRACTING BACKGROUND ───────────────────────────────
    final lowConfidence = labels.where((l) => l.confidence < 0.55).length;
    if (labels.length > 6 && lowConfidence > 4) {
      score -= 10; // cluttered / ambiguous scene
    } else if (labels.length > 8) {
      score -= 5; // busy background
    }

    return score.clamp(0, 100);
  }

  // ── Tips ───────────────────────────────────────────────────────────────────

  /// Generate an ordered list of human-readable photo improvement tips.
  static List<PhotoTip> generateTips({
    required List<Face> faces,
    required List<ImageLabel> labels,
    required double? personPercentage,
  }) {
    final tips = <PhotoTip>[];
    final names = labels.map((l) => l.label.toLowerCase()).toSet();

    // ── Face tips ────────────────────────────────────────────────────────────
    if (faces.isEmpty) {
      if (personPercentage != null && personPercentage > 8) {
        tips.add(
          const PhotoTip(
            Icons.face_outlined,
            'Face not visible — look directly at the camera',
            TipType.warning,
          ),
        );
      } else {
        tips.add(
          const PhotoTip(
            Icons.person_off_outlined,
            'No person detected — make sure you are in the frame',
            TipType.warning,
          ),
        );
      }
    } else {
      final face = faces.first;
      final smiling = face.smilingProbability ?? 0.5;
      final leftOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightOpen = face.rightEyeOpenProbability ?? 1.0;
      final headY = face.headEulerAngleY ?? 0.0;
      final headZ = face.headEulerAngleZ ?? 0.0;

      // Eyes
      if (leftOpen < 0.3 && rightOpen < 0.3) {
        tips.add(
          const PhotoTip(
            Icons.visibility_off,
            'Both eyes closed — keep them open and look at the lens',
            TipType.warning,
          ),
        );
      } else if (leftOpen < 0.3 || rightOpen < 0.3) {
        tips.add(
          const PhotoTip(
            Icons.visibility_off,
            'One eye appears closed — try again with eyes fully open',
            TipType.warning,
          ),
        );
      } else if (leftOpen < 0.6 || rightOpen < 0.6) {
        tips.add(
          const PhotoTip(
            Icons.remove_red_eye_outlined,
            'Eyes look squinted — open them wider for a better look',
            TipType.suggestion,
          ),
        );
      }

      // Head orientation — not frontal
      final absY = headY.abs();
      if (absY > 35) {
        tips.add(
          const PhotoTip(
            Icons.rotate_left,
            'Strong side profile — turn to face the camera directly',
            TipType.warning,
          ),
        );
      } else if (absY > 20) {
        tips.add(
          const PhotoTip(
            Icons.rotate_left,
            'Head turned away — face the camera more directly',
            TipType.suggestion,
          ),
        );
      } else if (absY > 12) {
        tips.add(
          const PhotoTip(
            Icons.rotate_left,
            'Slight head turn — centring your face will improve the shot',
            TipType.suggestion,
          ),
        );
      }

      // Head roll
      if (headZ.abs() > 25) {
        tips.add(
          const PhotoTip(
            Icons.screen_rotation,
            'Head is very tilted — straighten up for a cleaner look',
            TipType.suggestion,
          ),
        );
      } else if (headZ.abs() > 15) {
        tips.add(
          const PhotoTip(
            Icons.screen_rotation,
            'Head is tilted sideways — try keeping it level',
            TipType.suggestion,
          ),
        );
      }

      // Expression
      if (smiling < 0.2) {
        tips.add(
          const PhotoTip(
            Icons.sentiment_dissatisfied,
            'Expression looks flat or unhappy — a natural smile makes a big difference',
            TipType.warning,
          ),
        );
      } else if (smiling < 0.4) {
        tips.add(
          const PhotoTip(
            Icons.sentiment_satisfied_alt,
            'Try a warmer smile for a more engaging shot',
            TipType.suggestion,
          ),
        );
      } else if (smiling > 0.75) {
        tips.add(
          const PhotoTip(
            Icons.sentiment_very_satisfied,
            'Great natural smile!',
            TipType.good,
          ),
        );
      }

      // Low ML confidence
      if (face.smilingProbability == null &&
          face.leftEyeOpenProbability == null) {
        tips.add(
          const PhotoTip(
            Icons.help_outline,
            'Face data is incomplete — the photo may be blurry or poorly lit',
            TipType.warning,
          ),
        );
      }

      // Multiple faces
      if (faces.length > 1) {
        tips.add(
          PhotoTip(
            Icons.group,
            '${faces.length} people detected — for a selfie, try to be the only subject',
            TipType.info,
          ),
        );
      }
    }

    // ── Composition tips ─────────────────────────────────────────────────────
    if (personPercentage != null) {
      if (personPercentage < 3) {
        tips.add(
          const PhotoTip(
            Icons.zoom_in,
            'You are barely visible — move much closer to the camera',
            TipType.warning,
          ),
        );
      } else if (personPercentage < 8) {
        tips.add(
          const PhotoTip(
            Icons.zoom_in,
            'Subject too small — move closer for more impact',
            TipType.warning,
          ),
        );
      } else if (personPercentage < 15) {
        tips.add(
          const PhotoTip(
            Icons.zoom_in,
            'You could move a little closer for a stronger composition',
            TipType.suggestion,
          ),
        );
      } else if (personPercentage >= 80) {
        tips.add(
          const PhotoTip(
            Icons.zoom_out,
            'Too close! Parts of your face are likely cut off — step back',
            TipType.warning,
          ),
        );
      } else if (personPercentage >= 65) {
        tips.add(
          const PhotoTip(
            Icons.zoom_out,
            'Slightly too close — step back a little for better framing',
            TipType.suggestion,
          ),
        );
      } else {
        tips.add(
          const PhotoTip(
            Icons.crop_free,
            'Good framing — subject fills the frame well',
            TipType.good,
          ),
        );
      }
    }

    // ── Lighting tips ─────────────────────────────────────────────────────────
    if (names.any(
      (n) => n.contains('dark') || n.contains('night') || n == 'darkness',
    )) {
      tips.add(
        const PhotoTip(
          Icons.wb_sunny,
          'Low lighting — find a brighter spot or face a window',
          TipType.warning,
        ),
      );
    } else if (names.any((n) => n.contains('shadow'))) {
      tips.add(
        const PhotoTip(
          Icons.wb_cloudy_outlined,
          'Strong shadows on face — adjust your position relative to the light source',
          TipType.suggestion,
        ),
      );
    }

    // ── Scene clutter ─────────────────────────────────────────────────────────
    if (names.any((n) => n == 'food' || n == 'dish' || n.contains('cuisine'))) {
      tips.add(
        const PhotoTip(
          Icons.restaurant,
          'Food detected — shoot from above (flat lay) for the best look',
          TipType.suggestion,
        ),
      );
    }

    // Fallback
    if (tips.isEmpty) {
      tips.add(
        const PhotoTip(
          Icons.check_circle,
          'Looks good — no obvious issues detected!',
          TipType.good,
        ),
      );
    }

    return tips;
  }
}