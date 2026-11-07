import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../home/main_navigation_screen.dart';
import '../home/memories_screen.dart';

/// NextMeet Connection Success Celebration Screen
/// Strictly following NextMeet Redesign.pdf (Page 11)
class ConnectionSuccessScreen extends StatelessWidget {
  final RelationshipModel? relationship;

  const ConnectionSuccessScreen({
    super.key,
    this.relationship,
  });

  @override
  Widget build(BuildContext context) {
    final name1 = relationship?.userName1 ?? 'You';
    final name2 = relationship?.userName2 ?? 'Partner';

    final rel = relationship;
    String togetherStr = '1 day';
    String lastMetStr = 'Today';
    String distStr = 'Together';
    String nextMeetStr = 'Soon';

    if (rel != null) {
      final daysTogether = DateTime.now().difference(rel.anniversaryDate).inDays;
      if (daysTogether <= 0) {
        togetherStr = '1 day';
      } else if (daysTogether >= 365) {
        togetherStr = '${daysTogether ~/ 365}y ${(daysTogether % 365) ~/ 30}m';
      } else {
        togetherStr = '$daysTogether days';
      }

      final daysSinceMet = DateTime.now().difference(rel.lastMeetingDate).inDays;
      if (daysSinceMet <= 0) {
        lastMetStr = 'Today';
      } else if (daysSinceMet < 30) {
        lastMetStr = '${daysSinceMet}d ago';
      } else if (daysSinceMet < 365) {
        lastMetStr = '${daysSinceMet ~/ 30} mo ago';
      } else {
        lastMetStr = '${daysSinceMet ~/ 365}y ago';
      }

      final dist = rel.computedDistance > 0 ? rel.computedDistance : rel.distanceKm;
      distStr = dist > 0 ? '${dist.round()} km' : 'Together';

      final daysToNext = rel.nextMeetingDate.difference(DateTime.now()).inDays;
      nextMeetStr = daysToNext <= 0 ? 'Today!' : '$daysToNext days';
    }

    return Scaffold(
      backgroundColor: AppColors.primary, // Full pink celebration canvas
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 36),

              // Mascots Leaning Together with Floating White Heart (Page 11)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const TwoMascotsRow(size: 110, spacing: 20),
                    Positioned(
                      top: -20,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'You are connected!',
                style: AppTextStyles.display.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$name1 and $name2 now share a private space.',
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // White Bottom Card with 4 Metric Boxes (Page 11)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2x2 Metric Grid
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard('Together for', togetherStr),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard('Last met', lastMetStr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard('Distance', distStr),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard('Next meetup', nextMeetStr),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  PrimaryButton(
                    text: 'Go to Home',
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                          (route) => false,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MemoriesScreen()),
                        );
                      },
                      child: Text(
                        'Add your first memory',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _metricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.title2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
