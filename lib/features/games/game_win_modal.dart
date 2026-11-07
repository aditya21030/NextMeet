import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Game Winner Celebration Modal
/// Strictly following NextMeet Redesign.pdf (Page 54)
class GameWinModal extends StatelessWidget {
  final String gameTitle;
  final String winnerName;
  final String partnerName;
  final int score1;
  final int score2;
  final int xpEarned;
  final VoidCallback? onRematch;

  const GameWinModal({
    super.key,
    required this.gameTitle,
    required this.winnerName,
    this.partnerName = 'Partner',
    this.score1 = 3,
    this.score2 = 2,
    this.xpEarned = 120,
    this.onRematch,
  });

  static void show(
    BuildContext context, {
    required String gameTitle,
    required String winnerName,
    String partnerName = 'Partner',
    int score1 = 3,
    int score2 = 2,
    int xpEarned = 120,
    VoidCallback? onRematch,
    String? relId,
  }) {
    VibrationService.success();
    if (relId != null) {
      CloudRelationshipService().addCoupleXp(relId, xpEarned);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GameWinModal(
        gameTitle: gameTitle,
        winnerName: winnerName,
        partnerName: partnerName,
        score1: score1,
        score2: score2,
        xpEarned: xpEarned,
        onRematch: onRematch,
      ),
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

          // Two Mascots with Party Hats (Page 54)
          const TwoMascotsRow(
            spacing: 20,
            leftAccessory: MascotAccessory.crown,
            rightAccessory: MascotAccessory.partyHat,
          ),

          const SizedBox(height: 18),

          Text(
            '$winnerName Wins! 🏆',
            style: AppTextStyles.title1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Great game of $gameTitle!',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),

          const SizedBox(height: 20),

          // Score Breakdown Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('You', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('$score1', style: AppTextStyles.display.copyWith(fontSize: 28)),
                  ],
                ),
                Container(width: 1.5, height: 40, color: AppColors.border),
                Column(
                  children: [
                    Text(partnerName, style: AppTextStyles.caption.copyWith(color: AppColors.partner, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('$score2', style: AppTextStyles.display.copyWith(fontSize: 28)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // XP Award Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.butterSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.butter, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '+$xpEarned Couple XP Earned!',
                  style: AppTextStyles.heading.copyWith(fontSize: 13, color: AppColors.butterText),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          PrimaryButton(
            text: 'Play Again 🔄',
            onPressed: () {
              Navigator.pop(context);
              if (onRematch != null) onRematch!();
            },
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // close modal
              Navigator.pop(context); // back to games hub
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'Back to Games',
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
