import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../auth/create_account_screen.dart';

/// NextMeet Welcome Landing Screen
/// Strictly following NextMeet Redesign.pdf (Page 3)
class WelcomeScreen extends StatelessWidget {
  final String? initialInviteCode;

  const WelcomeScreen({
    super.key,
    this.initialInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top Bar: Logo + "For two" Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const TwoMascotsRow(size: 28, spacing: 3),
                      const SizedBox(width: 8),
                      Text(
                        'NextMeet',
                        style: AppTextStyles.title2.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.pinkSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'For two',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hero Illustration Container
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sun & Clouds
                    Positioned(
                      top: 24,
                      left: 36,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.butter,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 24),
                      ),
                    ),

                    // Paper plane
                    Positioned(
                      top: 70,
                      left: 70,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: const Icon(
                          Icons.send_rounded,
                          size: 26,
                          color: AppColors.ink,
                        ),
                      ),
                    ),

                    // Floating countdown badge
                    Positioned(
                      top: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Text(
                          '23 days to go',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    // Leaning Two Mascots at bottom of illustration
                    const Positioned(
                      bottom: 36,
                      child: TwoMascotsRow(size: 90, spacing: 24),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Headlines
              Text(
                'Close, even when\nyou are apart.',
                style: AppTextStyles.display.copyWith(
                  height: 1.15,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Heartbeats, memories and a countdown to your next hug, in one cosy space.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.muted,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 24),

              // CTA Buttons
              PrimaryButton(
                text: 'Get started',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAccountScreen(
                        initialInviteCode: initialInviteCode,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(
                          initialInviteCode: initialInviteCode,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'I already have an account',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
