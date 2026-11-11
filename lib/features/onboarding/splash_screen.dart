import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../home/main_navigation_screen.dart';
import 'setup_couple_screen.dart';
import 'welcome_screen.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/in_app_update_service.dart';

/// NextMeet Splash Screen
/// Strictly following NextMeet Redesign.pdf (Page 2)
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
      // 1. Splash display duration
      final animationFuture = Future.delayed(const Duration(milliseconds: 1400));

      // 2. Auth state resolution with timeout
      final authFuture = AuthService()
          .authStateChanges
          .first
          .timeout(const Duration(seconds: 4), onTimeout: () => null);

      final result = await Future.wait([animationFuture, authFuture]);
      final AppUser? user = result[1] as AppUser?;

      if (!mounted) return;

      _checkForUpdates();

      // Inspect clipboard for 6-digit partner invite code
      String? detectedCode;
      try {
        final clipData = await Clipboard.getData(Clipboard.kTextPlain);
        final clipText = clipData?.text?.trim() ?? '';
        final cleanText = clipText.replaceAll(RegExp(r'[-\s]'), '');
        final match = RegExp(r'\b\d{6}\b').firstMatch(cleanText) ?? RegExp(r'\d{6}').firstMatch(cleanText);
        if (match != null) {
          detectedCode = match.group(0);
        }
      } catch (_) {}

      if (user != null) {
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

        if (relationship != null && detectedCode != null && relationship.inviteCode == detectedCode) {
          detectedCode = null;
        }

        final isActivelyPaired = relationship != null && relationship.status == 'active' && relationship.uid2 != null;
        final isWaitingState = relationship != null && relationship.status == 'waiting';

        if (isActivelyPaired || (isWaitingState && detectedCode == null)) {
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
            builder: (context) => WelcomeScreen(initialInviteCode: detectedCode),
          ),
        );
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
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
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background ambient circles & sprinkles matching Page 2
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Star / Butter Confetti Sprinkles
          Positioned(
            top: 140,
            left: 50,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.butter,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Positioned(
            top: 210,
            right: 70,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.butter,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 130,
            right: 90,
            child: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 16),
          ),
          Positioned(
            bottom: 230,
            right: 60,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.pinkLight.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 280,
            left: 70,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.butter,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Center: Leaning Mascots, NextMeet Wordmark, Tagline
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TwoMascotsRow(size: 96, spacing: 14),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NextMeet',
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Close, even when you are apart.',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Bottom 3 Dots Indicator (Page 2)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
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
