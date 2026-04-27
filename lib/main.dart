import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load saved settings (theme, language, toggles)
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // Schedule daily reminder if notifications are enabled
  if (settingsProvider.notificationsEnabled) {
    await notificationService.scheduleDailyReminder();
  }

  // Enable immersive fullscreen — hides system nav bar until user swipes
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top], // keep status bar, hide nav bar
  );

  runApp(
    ChangeNotifierProvider.value(
      value: settingsProvider,
      child: const VisionAIApp(),
    ),
  );
}
