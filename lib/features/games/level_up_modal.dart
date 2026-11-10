import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';
import '../../core/services/theme_service.dart';

/// NextMeet Level-Up Celebration Modal
/// Strictly following NextMeet Redesign.pdf (Page 57)
class LevelUpModal extends StatelessWidget {
  final int newLevel;
  final String rewardTitle;

  const LevelUpModal({
    super.key,
    this.newLevel = 8,
    this.rewardTitle = 'Golden Crown Accessory',
  });

  static void show(BuildContext context, {int newLevel = 8, String rewardTitle = 'Golden Crown Accessory'}) {
    VibrationService.success();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LevelUpModal(newLevel: newLevel, rewardTitle: rewardTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Two Mascots with Crowns (Page 57)
            TwoMascotsRow(
              spacing: 20,
              leftColor: ThemeService.instance.myMascotColor,
              rightColor: ThemeService.instance.partnerMascotColor,
              leftAccessory: MascotAccessory.crown,
              rightAccessory: MascotAccessory.crown,
            ),

          const SizedBox(height: 18),

          Text(
            'Level $newLevel Unlocked! 👑',
            style: AppTextStyles.title1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'You two are officially "Eternal Soulmates"',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),

          const SizedBox(height: 20),

          // Reward Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.butterSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.butter, width: 1.5),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UNLOCKED REWARD', style: AppTextStyles.label.copyWith(color: AppColors.butterText, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(rewardTitle, style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          PrimaryButton(
            text: 'Equip Crown Now 👑',
            onPressed: () {
              VibrationService.success();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Equipped Crown to your couple avatar!')),
              );
            },
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'Awesome!',
                style: AppTextStyles.button.copyWith(color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
