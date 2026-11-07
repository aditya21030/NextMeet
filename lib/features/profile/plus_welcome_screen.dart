import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet+ Purchase Celebration Screen ("YOU ARE IN!")
/// Strictly following NextMeet Redesign.pdf (Page 77)
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
              const SizedBox(height: 32),

              // Crown Mascots with Stars (Page 77)
              const TwoMascotsRow(
                spacing: 24,
                leftAccessory: MascotAccessory.crown,
                rightAccessory: MascotAccessory.crown,
              ),

              const SizedBox(height: 24),

              Text(
                'YOU ARE IN! 👑',
                style: AppTextStyles.display.copyWith(fontSize: 32, letterSpacing: 1.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to NextMeet+ VIP\nBoth you and your partner now enjoy unlimited perks!',
                style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Unlocked Perks Summary List (Page 77)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _vipRow(Icons.photo_library_rounded, 'Unlimited Sanctum Vault storage', AppColors.primary),
                    const Divider(height: 20, color: AppColors.border),
                    _vipRow(Icons.mic_rounded, 'Full Voice Whispers audio library', AppColors.partner),
                    const Divider(height: 20, color: AppColors.border),
                    _vipRow(Icons.celebration_rounded, 'All Mascot hats, caps & crowns', AppColors.butterText),
                    const Divider(height: 20, color: AppColors.border),
                    _vipRow(Icons.auto_stories_rounded, 'NextMeet Wrapped 2026 story recap', AppColors.mintText),
                  ],
                ),
              ),

              const SizedBox(height: 36),

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
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
        const Icon(Icons.check_rounded, color: AppColors.mint, size: 18),
      ],
    );
  }
}
