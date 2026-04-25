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

  /// Compute a 0–100 quality score using a penalty-based system.
  /// Starts at 100 and deducts for detected problems.
  static int computeScore({
    required List<Face> faces,
    required List<ImageLabel> labels,
    required double? personPercentage,
  }) {
    int score = 100;

    // ── Face penalties ───────────────────────────────────────────────────────
    if (faces.isEmpty) {
      score -= 20; // no face detected
    } else {
      final face = faces.first;
      final smiling = face.smilingProbability ?? 0;
      final leftOpen = face.leftEyeOpenProbability ?? 1;
      final rightOpen = face.rightEyeOpenProbability ?? 1;

      if (smiling < 0.3) score -= 5; // no smile
      if (leftOpen < 0.4 || rightOpen < 0.4) score -= 10; // eyes closed
    }

    // ── Composition / framing penalties ──────────────────────────────────────
    if (personPercentage != null) {
      if (personPercentage < 5) {
        score -= 15; // subject too small / bad positioning
      } else if (personPercentage >= 70) {
        score -= 10; // too close / bad framing
      }
    }

    // ── Lighting penalties ────────────────────────────────────────────────────
    final names = labels.map((l) => l.label.toLowerCase()).toSet();
    if (names.any((n) => n.contains('dark') || n.contains('night'))) {
      score -= 15; // poor lighting
    }

    // ── Scene clutter penalty ─────────────────────────────────────────────────
    final lowConfidence = labels.where((l) => l.confidence < 0.6).length;
    if (labels.length > 5 && lowConfidence > 3) {
      score -= 5; // busy / cluttered scene
    }

    // ── Good lighting bonus ───────────────────────────────────────────────────
    if (names.any(
      (n) => n.contains('sky') || n.contains('outdoor') || n == 'sunlight',
    )) {
      score += 5;
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

    // ── Face tips ────────────────────────────────────────────────────────────
    if (faces.isEmpty) {
      if (personPercentage != null && personPercentage > 8) {
        // Person in frame but face not detected → face is hidden/blurry
        tips.add(
          const PhotoTip(
            Icons.face_outlined,
            'Face not visible — look directly at the camera',
            TipType.warning,
          ),
        );
      }
    } else {
      final face = faces.first;
      final smiling = face.smilingProbability ?? 0;
      final leftOpen = face.leftEyeOpenProbability ?? 1;
      final rightOpen = face.rightEyeOpenProbability ?? 1;

      if (smiling > 0.6) {
        tips.add(
          const PhotoTip(
            Icons.sentiment_very_satisfied,
            'Great smile — very warm and inviting!',
            TipType.good,
          ),
        );
      } else if (smiling < 0.3) {
        tips.add(
          const PhotoTip(
            Icons.sentiment_satisfied_alt,
            'Try smiling for a warmer, more engaging shot',
            TipType.suggestion,
          ),
        );
      }

      if (leftOpen < 0.4 || rightOpen < 0.4) {
        tips.add(
          const PhotoTip(
            Icons.visibility_off,
            'Eyes appear closed — keep them open and look at the camera',
            TipType.warning,
          ),
        );
      }

      if (faces.length > 1) {
        tips.add(
          PhotoTip(
            Icons.group,
            '${faces.length} people detected in this frame',
            TipType.info,
          ),
        );
      }
    }

    // ── Composition tips ─────────────────────────────────────────────────────
    if (personPercentage != null) {
      if (personPercentage < 5) {
        tips.add(
          const PhotoTip(
            Icons.zoom_in,
            'Subject too small — move closer for more impact',
            TipType.warning,
          ),
        );
      } else if (personPercentage >= 70) {
        tips.add(
          const PhotoTip(
            Icons.zoom_out,
            'Too close! Step back a little for better framing',
            TipType.suggestion,
          ),
        );
      } else {
        tips.add(
          const PhotoTip(
            Icons.crop_free,
            'Subject is well-framed — great composition!',
            TipType.good,
          ),
        );
      }
    }

    // ── Scene / lighting tips ─────────────────────────────────────────────────
    final names = labels.map((l) => l.label.toLowerCase()).toSet();

    if (names.any((n) => n.contains('dark') || n.contains('night'))) {
      tips.add(
        const PhotoTip(
          Icons.wb_sunny,
          'Low lighting detected — find a brighter spot or use flash',
          TipType.warning,
        ),
      );
    } else if (names.any(
      (n) => n.contains('sky') || n.contains('outdoor') || n == 'sunlight',
    )) {
      tips.add(
        const PhotoTip(
          Icons.wb_sunny_outlined,
          'Great natural lighting from outdoors!',
          TipType.good,
        ),
      );
    }

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
          'Looks great — no issues detected!',
          TipType.good,
        ),
      );
    }

    return tips;
  }
}
