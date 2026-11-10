import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet+ Purchase Celebration Screen ("YOU ARE IN!")
/// Strictly following NextMeet Monetize.md & Design System
class PlusWelcomeScreen extends StatelessWidget {
  const PlusWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),

              // Crown Mascots with Stars
              TwoMascotsRow(
                spacing: 24,
                leftAccessory: MascotAccessory.crown,
                rightAccessory: MascotAccessory.crown,
              ),

              const SizedBox(height: 20),

              Text(
                'YOU ARE IN! 👑',
                style: AppTextStyles.display.copyWith(fontSize: 30, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to NextMeet+ Pro\nBoth you and your partner now have all VIP perks unlocked!',
                style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Unlocked Perks Summary List (Monetize.md)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _vipRow(Icons.block_rounded, '100% Ad-Free across all 20 games', AppColors.primary),
                    const Divider(height: 18, color: AppColors.border),
                    _vipRow(Icons.cloud_done_rounded, 'Unlimited 4K Vault & voice whispers', AppColors.partner),
                    const Divider(height: 18, color: AppColors.border),
                    _vipRow(Icons.widgets_rounded, 'All 14 interactive home & lock widgets', AppColors.mintText),
                    const Divider(height: 18, color: AppColors.border),
                    _vipRow(Icons.celebration_rounded, 'Golden crowns, caps & mascot halos', AppColors.butterText),
                    const Divider(height: 18, color: AppColors.border),
                    _vipRow(Icons.mark_email_unread_rounded, 'Time Capsule letters & 6-slide Wrapped', AppColors.primary),
                    const Divider(height: 18, color: AppColors.border),
                    _vipRow(Icons.flight_takeoff_rounded, 'Unlimited trips & flight tracker passes', AppColors.partner),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                text: 'Start Exploring VIP Perks ✨',
                onPressed: () {
                  VibrationService.success();
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vipRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 13),
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
      ],
    );
  }
}
