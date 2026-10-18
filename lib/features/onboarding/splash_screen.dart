import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../home/main_navigation_screen.dart';
import '../auth/login_screen.dart';
import 'setup_couple_screen.dart';
import 'package:flutter/services.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/in_app_update_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    try {
      // 1. Min splash animation time (reduced from 2500ms to 1200ms for fast launch)
      final animationFuture = Future.delayed(const Duration(milliseconds: 1200));
      
      // 2. Wait for auth service to determine auth state with timeout
      final authFuture = AuthService()
          .authStateChanges
          .first
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
      
      final result = await Future.wait([animationFuture, authFuture]);
      final AppUser? user = result[1] as AppUser?;

      if (!mounted) return;

      // Non-blocking in-app update check
      _checkForUpdates();

      // Inspect clipboard for 6-digit partner invite code
      String? detectedCode;
      try {
        final clipData = await Clipboard.getData(Clipboard.kTextPlain);
        final clipText = clipData?.text?.trim() ?? '';
        final match = RegExp(r'\b\d{6}\b').firstMatch(clipText);
        if (match != null) {
          detectedCode = match.group(0);
        }
      } catch (_) {}

      if (user != null) {
        // Fetch relationship with timeout to avoid infinite freeze
        RelationshipModel? relationship;
        try {
          relationship = await CloudRelationshipService()
              .streamRelationship()
              .first
              .timeout(const Duration(seconds: 4), onTimeout: () => null);
        } catch (e) {
          debugPrint('Relationship stream timeout/error: $e');
        }
        
        if (!mounted) return;
        
        if (relationship != null) {
          // Register FCM token asynchronously in background
          NotificationService().getToken().then((token) {
            if (token != null && relationship?.id != null) {
              CloudRelationshipService().updateFcmToken(relationship!.id!, token);
            }
          }).catchError((e) {
            debugPrint('Error registering FCM token: $e');
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        } else {
          // User exists but has no couple yet - send to setup with detected code
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SetupCoupleScreen(initialInviteCode: detectedCode),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(initialInviteCode: detectedCode),
          ),
        );
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    await InAppUpdateService().checkForUpdateSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient (Elegant Depth)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.background.withValues(alpha: 0.9),
                  AppColors.background,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          
          // Subtle Particle-like background (Optional, using icons for simplicity)
          Positioned(
            top: -50,
            right: -50,
            child: FadeIn(
              delay: const Duration(milliseconds: 1500),
              child: Icon(Icons.favorite_rounded, color: AppColors.primary.withValues(alpha: 0.04), size: 300),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 1000),
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Text(
                        'NextMeet',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                          fontSize: 40,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Where Hearts Connect ❤️',
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Indicator & Version
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                FadeInUp(
                  delay: const Duration(milliseconds: 1200),
                  child: const HeartPulseLoader(),
                ),
                const SizedBox(height: 32),
                FadeIn(
                  delay: const Duration(milliseconds: 1500),
                  child: Text(
                    'VERSION 1.0.22',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeIn(
                  delay: const Duration(milliseconds: 1800),
                  child: Text(
                    '© 2026 NEXTMEET',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      fontSize: 8,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeartPulseLoader extends StatefulWidget {
  const HeartPulseLoader({super.key});

  @override
  State<HeartPulseLoader> createState() => _HeartPulseLoaderState();
}

class _HeartPulseLoaderState extends State<HeartPulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: AppColors.primary.withValues(alpha: 0.2),
            size: 32,
          ),
          const Icon(
            Icons.favorite_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
