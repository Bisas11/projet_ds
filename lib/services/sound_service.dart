import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';

/// Service for sound effects and vibration feedback.
/// Uses audioplayers to play real asset files from assets/sounds/.
class SoundService {
  // Dedicated players — reusing avoids re-init overhead on repeated clicks.
  static final _clickPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final _startupPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.release);

  /// Play assets/sounds/click.mp3.
  static Future<void> playClick() async {
    await _clickPlayer.stop();
    await _clickPlayer.play(AssetSource('sounds/click.mp3'));
  }

  /// Play assets/sounds/startup.mp3 once at app launch.
  static Future<void> playStartup() async {
    await _startupPlayer.play(AssetSource('sounds/startup.mp3'));
  }

  /// Play feedback (custom click sound + optional vibration) after ML processing.
  static Future<void> playFeedback(SettingsProvider settings) async {
    if (settings.soundEnabled) {
      await playClick();
    }
    if (settings.vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Play click sound only (respects settings).
  static Future<void> playSound(SettingsProvider settings) async {
    if (settings.soundEnabled) {
      await playClick();
    }
  }

  /// Trigger vibration only (respects settings).
  static Future<void> vibrate(SettingsProvider settings) async {
    if (settings.vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Play click sound unconditionally (for the test button in settings).
  static Future<void> testSound() async {
    await playClick();
  }

  /// Trigger vibration unconditionally (for the test button in settings).
  static Future<void> testVibration() async {
    await HapticFeedback.heavyImpact();
  }
}
