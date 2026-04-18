import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// ChangeNotifier that manages app-wide settings:
/// theme mode, locale, sound, vibration, and notifications.
/// All settings are persisted to SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // ── Current state ──
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;

  // ── Getters ──
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Load saved settings from SharedPreferences.
  /// Must be called once before runApp().
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _themeMode = (_prefs!.getBool('isDarkMode') ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
    _locale = Locale(_prefs!.getString('locale') ?? 'fr');
    _soundEnabled = _prefs!.getBool('soundEnabled') ?? true;
    _vibrationEnabled = _prefs!.getBool('vibrationEnabled') ?? true;
    _notificationsEnabled = _prefs!.getBool('notificationsEnabled') ?? true;

    notifyListeners();
  }

  // ── Setters with persistence ──

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setBool('isDarkMode', mode == ThemeMode.dark);
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _prefs?.setString('locale', locale.languageCode);
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _prefs?.setBool('soundEnabled', value);
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _prefs?.setBool('vibrationEnabled', value);
    notifyListeners();
  }

  /// Toggle notifications and schedule/cancel the daily reminder.
  void setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    _prefs?.setBool('notificationsEnabled', value);

    final notificationService = NotificationService();
    if (value) {
      await notificationService.scheduleDailyReminder();
    } else {
      await notificationService.cancelAll();
    }

    notifyListeners();
  }
}
