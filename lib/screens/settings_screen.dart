import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Settings screen: theme, language, sound, vibration, notifications, logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // ── Theme ──
          SwitchListTile(
            title: Text(l10n.darkMode),
            subtitle: Text(l10n.theme),
            secondary: const Icon(Icons.brightness_6),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (value) {
              settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),

          // ── Language ──
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(settings.locale, l10n)),
            trailing: DropdownButton<String>(
              value: settings.locale.languageCode,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
              ],
              onChanged: (value) {
                if (value != null) {
                  settings.setLocale(Locale(value));
                }
              },
            ),
          ),
          const Divider(),

          // ── Sound ──
          SwitchListTile(
            title: Text(l10n.sound),
            secondary: const Icon(Icons.volume_up),
            value: settings.soundEnabled,
            onChanged: (value) => settings.setSoundEnabled(value),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.volume_up, size: 16),
                label: Text(l10n.testSound),
                onPressed: settings.soundEnabled
                    ? () => SystemSound.play(SystemSoundType.click)
                    : null,
              ),
            ),
          ),
          const Divider(),

          // ── Vibration ──
          SwitchListTile(
            title: Text(l10n.vibration),
            secondary: const Icon(Icons.vibration),
            value: settings.vibrationEnabled,
            onChanged: (value) => settings.setVibrationEnabled(value),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.vibration, size: 16),
                label: Text(l10n.testVibration),
                onPressed: settings.vibrationEnabled
                    ? () => HapticFeedback.heavyImpact()
                    : null,
              ),
            ),
          ),
          const Divider(),

          // ── Notifications ──
          SwitchListTile(
            title: Text(l10n.notifications),
            secondary: const Icon(Icons.notifications_active),
            value: settings.notificationsEnabled,
            onChanged: (value) => settings.setNotificationsEnabled(value),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: Text(l10n.testNotification),
                onPressed: settings.notificationsEnabled
                    ? () => NotificationService().showTestNotification()
                    : null,
              ),
            ),
          ),
          const Divider(),

          // ── Logout ──
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService().signOut();
              // Pop to root so the StreamBuilder's rebuilt LandingScreen is revealed
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Get the display name for the current locale.
  String _getLanguageName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'fr':
        return l10n.french;
      case 'en':
        return l10n.english;
      case 'ar':
        return l10n.arabic;
      default:
        return locale.languageCode;
    }
  }
}
