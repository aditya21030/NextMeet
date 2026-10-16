import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/auth/reset_password_screen.dart';
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

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
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

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class NextMeetApp extends StatefulWidget {
  const NextMeetApp({super.key});

  @override
  State<NextMeetApp> createState() => _NextMeetAppState();
}

class _NextMeetAppState extends State<NextMeetApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'NextMeet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
