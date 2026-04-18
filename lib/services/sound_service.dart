import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';

/// Service for sound effects and vibration feedback.
/// Uses built-in Flutter APIs — no additional packages needed.
class SoundService {
  /// Play feedback (sound + vibration) after ML processing completes.
  /// Checks the user's settings before playing.
  static void playFeedback(SettingsProvider settings) {
    if (settings.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (settings.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Play sound effect only.
  static void playSound(SettingsProvider settings) {
    if (settings.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Trigger vibration only.
  static void vibrate(SettingsProvider settings) {
    if (settings.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
}
