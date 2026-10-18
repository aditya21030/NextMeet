import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../home/main_navigation_screen.dart';

class ConnectionSuccessScreen extends StatelessWidget {
  const ConnectionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background "Confetti" decorations
          ...List.generate(6, (index) {
            return Positioned(
              top: 100 * (index % 3).toDouble(),
              left: 50 * index.toDouble(),
              child: ZoomIn(
                delay: Duration(milliseconds: 200 * index),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary.withValues(alpha: 0.05),
                  size: 20 + (10 * index).toDouble(),
                ),
              ),
            );
          }),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
              child: Column(
                children: [
                  FadeInDown(
                    child: Text(
                      'NextMeet',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Central Connection Animation
                  FadeInUp(
                    duration: const Duration(seconds: 1),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Pulse(
                            infinite: true,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.03),
                              ),
                            ),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: AppColors.premiumShadow,
                            ),
                            child: ClipOval(
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 20,
                                    top: 40,
                                    child: FadeInLeft(
                                      delay: const Duration(milliseconds: 400),
                                      child: const CircleAvatar(
                                        radius: 40,
                                        backgroundColor: AppColors.primary,
                                        child: Icon(Icons.person, color: Colors.white, size: 40),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 20,
                                    bottom: 40,
                                    child: FadeInRight(
                                      delay: const Duration(milliseconds: 600),
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: AppColors.accent.withValues(alpha: 0.8),
                                        child: const Icon(Icons.person, color: Colors.white, size: 40),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: ZoomIn(
                                      delay: const Duration(milliseconds: 800),
                                      child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Text Content
                  FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        Text(
                          'Hearts Connected! ❤️',
                          style: AppTextStyles.h1.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          'Your private couple space is live and ready.\nEverything you share is encrypted and private.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Badges
                  FadeInUp(
                    delay: const Duration(milliseconds: 1200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge('Encrypted', Icons.lock_outline_rounded),
                        const SizedBox(width: AppSpacing.m),
                        _buildBadge('Live Sync', Icons.sync_rounded),
                        const SizedBox(width: AppSpacing.m),
                        _buildBadge('Private Space', Icons.favorite_rounded),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 1400),
                    child: PrimaryButton(
                      text: "Enter Our Shared Space ✨",
                      onPressed: () {
                        VibrationService.success();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.l),
                  FadeIn(
                    delay: const Duration(milliseconds: 1600),
                    child: Text(
                      'ESTABLISHED • ${DateTime.now().year}',
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
