import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';

/// Service for sound effects and vibration feedback.
/// Uses built-in Flutter APIs — no additional packages needed.
class SoundService {
  /// Play feedback (sound + vibration) after ML processing completes.
  /// Checks the user's settings before playing.
  static Future<void> playFeedback(SettingsProvider settings) async {
    if (settings.soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (settings.vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Play sound effect only.
  static Future<void> playSound(SettingsProvider settings) async {
    if (settings.soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Trigger vibration only.
  static Future<void> vibrate(SettingsProvider settings) async {
    if (settings.vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Directly play a click sound regardless of settings (for test).
  static Future<void> testSound() async {
    await SystemSound.play(SystemSoundType.click);
  }

  /// Directly trigger vibration regardless of settings (for test).
  static Future<void> testVibration() async {
    await HapticFeedback.heavyImpact();
  }
}
