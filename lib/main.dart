import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'features/onboarding/splash_screen.dart';
import 'core/services/notification_service.dart';

void main() async {
  // Ensure binding is initialized in root zone
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Caught Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught PlatformDispatcher Error: $error');
    return true; // prevent crash
  };

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // Mount UI immediately so the user sees the Splash screen without delay
  runApp(const NextMeetApp());

  // Initialize notifications asynchronously without blocking the UI thread or window manager
  try {
    final notificationService = NotificationService();
    notificationService.initialize().catchError((e) {
      debugPrint('Notification service initialization error: $e');
    });
  } catch (e) {
    debugPrint('Notification service launch warning: $e');
  }
}

class NextMeetApp extends StatelessWidget {
  const NextMeetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextMeet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
