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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Appearance ────────────────────────────────────────────────
          _SettingsSectionLabel(label: l10n.theme.toUpperCase()),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.darkMode),
                  subtitle: Text(l10n.theme),
                  secondary: Icon(
                    Icons.brightness_6_rounded,
                    color: colorScheme.primary,
                  ),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    settings.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 0),
                ListTile(
                  leading: Icon(
                    Icons.language_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.language),
                  subtitle: Text(_getLanguageName(settings.locale, l10n)),
                  trailing: DropdownButton<String>(
                    value: settings.locale.languageCode,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Feedback ──────────────────────────────────────────────────
          _SettingsSectionLabel(label: 'FEEDBACK'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.sound),
                  secondary: Icon(
                    Icons.volume_up_rounded,
                    color: colorScheme.primary,
                  ),
                  value: settings.soundEnabled,
                  onChanged: (value) => settings.setSoundEnabled(value),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 56,
                    right: 16,
                    bottom: 8,
                  ),
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
                const Divider(indent: 16, endIndent: 16, height: 0),
                SwitchListTile(
                  title: Text(l10n.vibration),
                  secondary: Icon(
                    Icons.vibration_rounded,
                    color: colorScheme.primary,
                  ),
                  value: settings.vibrationEnabled,
                  onChanged: (value) => settings.setVibrationEnabled(value),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 56,
                    right: 16,
                    bottom: 8,
                  ),
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Notifications ─────────────────────────────────────────────
          _SettingsSectionLabel(label: 'NOTIFICATIONS'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.notifications),
                  secondary: Icon(
                    Icons.notifications_active_rounded,
                    color: colorScheme.primary,
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.setNotificationsEnabled(value),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 56,
                    right: 16,
                    bottom: 8,
                  ),
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Account ───────────────────────────────────────────────────
          _SettingsSectionLabel(label: 'ACCOUNT'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text(
                l10n.logout,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
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

/// Section label widget for grouping settings visually.
class _SettingsSectionLabel extends StatelessWidget {
  final String label;
  const _SettingsSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
