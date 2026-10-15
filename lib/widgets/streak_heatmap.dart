import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';

class StreakHeatMap extends StatelessWidget {
  final Map<DateTime, int> activityData;
  final int year;

  const StreakHeatMap({
    super.key,
    required this.activityData,
    this.year = 2026,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Activity Heatmap $year', style: AppTextStyles.h3),
            Text('Daily Consistency', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(12, (monthIndex) {
                final month = monthIndex + 1;
                final daysInMonth = DateUtils.getDaysInMonth(year, month);
                final firstDayOfMonth = DateTime(year, month, 1);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM').format(firstDayOfMonth),
                        style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: (daysInMonth / 7).ceil() * 14.0,
                        height: 7 * 14.0,
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 2,
                          runSpacing: 2,
                          children: List.generate(daysInMonth, (dayIndex) {
                            final date = DateTime(year, month, dayIndex + 1);
                            final activityLevel = activityData[DateTime(date.year, date.month, date.day)] ?? 0;
                            
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getColorForLevel(activityLevel),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        _buildLegend(),
      ],
    );
  }

  Color _getColorForLevel(int level) {
    if (level == 0) return Colors.grey.shade100;
    if (level == 1) return AppColors.primary.withValues(alpha: 0.2);
    if (level == 2) return AppColors.primary.withValues(alpha: 0.4);
    if (level == 3) return AppColors.primary.withValues(alpha: 0.7);
    return AppColors.primary;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: AppTextStyles.bodyS.copyWith(fontSize: 10)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _getColorForLevel(i),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 4),
        Text('More', style: AppTextStyles.bodyS.copyWith(fontSize: 10)),
      ],
    );
  }
}
