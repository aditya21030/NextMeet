import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet 1,000 Days Milestone Unlocked Celebration Modal
/// Strictly following NextMeet Redesign.pdf (Page 38)
class MilestoneUnlockedModal extends StatelessWidget {
  final String partnerName;
  const MilestoneUnlockedModal({super.key, this.partnerName = 'Partner'});

  static void show(BuildContext context, {String partnerName = 'Partner'}) {
    VibrationService.success();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MilestoneUnlockedModal(partnerName: partnerName),
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

          // Celebratory Mascots with Party Hats (Page 38)
          const TwoMascotsRow(
            spacing: 24,
            leftAccessory: MascotAccessory.partyHat,
            rightAccessory: MascotAccessory.partyHat,
          ),

          const SizedBox(height: 18),

          Text(
            '1,000 Days of Love! 🎉',
            style: AppTextStyles.title1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'A thousand days of laughing, holding on through distance, and choosing each other every single morning.',
              style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 22),

          // 4 Stats Grid (Page 38)
          Row(
            children: [
              Expanded(child: _metricBox('1,000', 'Days together', AppColors.pinkSoft, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _metricBox('4,280', 'Whispers sent', AppColors.partnerSoft, AppColors.partner)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metricBox('18', 'Reunion trips', AppColors.mintSoft, AppColors.mintText)),
              const SizedBox(width: 10),
              Expanded(child: _metricBox('280', 'Memories saved', AppColors.butterSoft, AppColors.butterText)),
            ],
          ),

          const SizedBox(height: 24),

          // Primary Action: Open Secret Letter
          PrimaryButton(
            text: 'Open Secret Letter from $partnerName 💌',
            onPressed: () {
              VibrationService.heavy();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unlocked letter from $partnerName in your Sanctum Vault!')),
              );
            },
          ),
          const SizedBox(height: 10),

          // Secondary Action: Share
          GestureDetector(
            onTap: () {
              VibrationService.light();
              Navigator.pop(context);
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'Share our journey',
                style: AppTextStyles.button.copyWith(color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _metricBox(String number, String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: AppTextStyles.title1.copyWith(fontSize: 20, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
