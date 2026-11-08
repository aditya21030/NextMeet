import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import 'milestone_unlocked_modal.dart';

/// NextMeet Couple Milestones Screen
/// Strictly following NextMeet Redesign.pdf (Page 37)
class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cloudService = CloudRelationshipService();

    return StreamBuilder<RelationshipModel?>(
      stream: cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final partnerName = rel?.getPartnerName(cloudService.currentUid) ?? 'Partner';
        final anniversary = rel?.anniversaryDate ?? DateTime.now().subtract(const Duration(days: 300));
        final currentDays = DateTime.now().difference(anniversary).inDays.abs();

        int totalDays = 100;
        if (currentDays >= 100 && currentDays < 250) {
          totalDays = 250;
        } else if (currentDays >= 250 && currentDays < 365) {
          totalDays = 365;
        } else if (currentDays >= 365 && currentDays < 500) {
          totalDays = 500;
        } else if (currentDays >= 500 && currentDays < 750) {
          totalDays = 750;
        } else if (currentDays >= 750 && currentDays < 1000) {
          totalDays = 1000;
        } else if (currentDays >= 1000) {
          totalDays = ((currentDays ~/ 500) + 1) * 500;
        }

        final daysLeft = (totalDays - currentDays).clamp(0, totalDays);
        final milestoneTitle = NumberFormat('#,###').format(totalDays);

        final upcoming = [
          {
            'title': 'Next Anniversary',
            'target': DateFormat('d MMM yyyy').format(DateTime(anniversary.year + ((currentDays ~/ 365) + 1), anniversary.month, anniversary.day)),
            'icon': Icons.favorite_rounded,
            'color': AppColors.primary,
            'bg': AppColors.pinkSoft,
          },
          {
            'title': '$totalDays Days Together',
            'target': 'in $daysLeft day${daysLeft == 1 ? '' : 's'}',
            'icon': Icons.stars_rounded,
            'color': AppColors.butterText,
            'bg': AppColors.butterSoft,
          },
          {
            'title': 'Next Meetup Reunion',
            'target': rel?.nextMeetingDate != null
                ? DateFormat('d MMM yyyy').format(rel!.nextMeetingDate)
                : 'Plan your next date',
            'icon': Icons.flight_rounded,
            'color': AppColors.partner,
            'bg': AppColors.partnerSoft,
          },
        ];

        final celebrated = [
          {
            'title': 'First Day Met',
            'date': DateFormat('d MMM yyyy').format(anniversary),
            'emoji': '✨',
            'bg': AppColors.mintSoft,
          },
          if (currentDays >= 100)
            {
              'title': '100 Days Milestone',
              'date': DateFormat('d MMM yyyy').format(anniversary.add(const Duration(days: 100))),
              'emoji': '🎉',
              'bg': AppColors.butterSoft,
            },
          if (currentDays >= 365)
            {
              'title': '1 Year Anniversary',
              'date': DateFormat('d MMM yyyy').format(DateTime(anniversary.year + 1, anniversary.month, anniversary.day)),
              'emoji': '💍',
              'bg': AppColors.pinkSoft,
            },
          if (currentDays >= 500)
            {
              'title': '500 Days Milestone',
              'date': DateFormat('d MMM yyyy').format(anniversary.add(const Duration(days: 500))),
              'emoji': '💌',
              'bg': AppColors.partnerSoft,
            },
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                VibrationService.light();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                        Text('Milestones', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                        GestureDetector(
                          onTap: () => MilestoneUnlockedModal.show(context, partnerName: partnerName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.butterSoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.butter, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text('Preview', style: AppTextStyles.heading.copyWith(fontSize: 12, color: AppColors.butterText)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Hero Milestone Progress Card (Page 37)
                    GestureDetector(
                      onTap: () => MilestoneUnlockedModal.show(context, partnerName: partnerName),
                      child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.pinkSoft,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  'NEXT BIG GOAL',
                                  style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 10),
                                ),
                              ),
                              Text(
                                daysLeft > 0 ? 'in $daysLeft days' : 'Milestone achieved! 🎉',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: (currentDays / totalDays).clamp(0.0, 1.0),
                                  strokeWidth: 12,
                                  backgroundColor: AppColors.pinkSoft,
                                  color: AppColors.primary,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$currentDays',
                                    style: AppTextStyles.display.copyWith(fontSize: 32, height: 1.0),
                                  ),
                                  Text(
                                    'of $totalDays days',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$milestoneTitle Days of Love',
                            style: AppTextStyles.title2.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to preview the surprise celebration',
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upcoming Milestones Section
                  Text('Coming up', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),

                  ...upcoming.map((item) {
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: item['color'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] as String, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(item['target'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Celebrated Milestones Section
                  Text('Celebrated Together', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),

                  ...celebrated.map((item) {
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(item['emoji'] as String, style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] as String, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(item['date'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
