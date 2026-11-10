import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'level_up_modal.dart';

/// NextMeet Couple Level Progression & Quests Screen
/// Strictly following NextMeet Redesign.pdf (Page 55)
class CoupleLevelScreen extends StatelessWidget {
  final int? coupleLevel;
  final int? coupleXp;
  final String? relId;

  const CoupleLevelScreen({
    super.key,
    this.coupleLevel,
    this.coupleXp,
    this.relId,
  });

  @override
  Widget build(BuildContext context) {
    final level = coupleLevel ?? 7;
    final currentXp = coupleXp ?? 1240;
    final nextLevelXp = level * 200;
    final xpInCurrentLevel = currentXp % 200;
    final progress = (xpInCurrentLevel / 200.0).clamp(0.0, 1.0);
    final xpNeeded = (nextLevelXp - currentXp) > 0 ? (nextLevelXp - currentXp) : 0;

    final quests = [
      {'title': 'Play 3 Games Together', 'progress': '2/3', 'xp': '+60 XP', 'done': false, 'icon': Icons.videogame_asset_rounded},
      {'title': 'Send 5 Voice Whispers', 'progress': '5/5', 'xp': '+50 XP', 'done': true, 'icon': Icons.mic_rounded},
      {'title': '7-Day Heartbeat Streak', 'progress': '7/7', 'xp': '+100 XP', 'done': true, 'icon': Icons.favorite_rounded},
      {'title': 'Plan Next Reunion Activity', 'progress': '0/1', 'xp': '+40 XP', 'done': false, 'icon': Icons.flight_rounded},
    ];

    final tiers = [
      {'level': 1, 'title': 'First Spark', 'unlocked': level >= 1, 'emoji': '✨'},
      {'level': 2, 'title': 'Party Hat Accessory', 'unlocked': level >= 2, 'emoji': '🎉'},
      {'level': 3, 'title': 'Gold Map Line Color', 'unlocked': level >= 3, 'emoji': '🌟'},
      {'level': 4, 'title': 'Inseparable Hearts Title', 'unlocked': level >= 4, 'emoji': '💖'},
      {'level': 5, 'title': 'Golden Crown Accessory', 'unlocked': level >= 5, 'emoji': '👑'},
      {'level': 6, 'title': 'Custom App Icon (Blush)', 'unlocked': level >= 6, 'emoji': '🎨'},
      {'level': 7, 'title': 'Diamond Couple Trophy', 'unlocked': level >= 7, 'emoji': '💎'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Couple Level',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => LevelUpModal.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.butterSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.butter, width: 1.5),
                      ),
                      child: Text('Next Reward 👑', style: AppTextStyles.caption.copyWith(color: AppColors.butterText, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Hero Level Card (Page 55)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    TwoMascotsRow(
                      spacing: 16,
                      leftAccessory: MascotAccessory.crown,
                      rightAccessory: MascotAccessory.none,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Level $level • Inseparable Hearts',
                      style: AppTextStyles.title1.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentXp / $nextLevelXp XP ($xpNeeded XP to Level ${level + 1})',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: AppColors.pinkSoft,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Weekly Quests Section
              Text('Weekly Quests', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),

              ...quests.map((quest) {
                final isDone = quest['done'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.mintSoft : AppColors.pinkSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          quest['icon'] as IconData,
                          color: isDone ? AppColors.mintText : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest['title'] as String,
                              style: AppTextStyles.heading.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Progress: ${quest['progress']} • ${quest['xp']}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (isDone)
                        const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 22)
                      else
                        Text(
                          quest['progress'] as String,
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Tiered Unlocks Section
              Text('Level Rewards Path', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),

              ...tiers.map((tier) {
                final unlocked = tier['unlocked'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: unlocked ? Colors.white : AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: unlocked ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(tier['emoji'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${tier['level']} • ${tier['title']}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 13,
                                color: unlocked ? AppColors.ink : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: unlocked ? AppColors.mintSoft : AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          unlocked ? 'UNLOCKED' : 'LOCKED',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 9,
                            color: unlocked ? AppColors.mintText : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
