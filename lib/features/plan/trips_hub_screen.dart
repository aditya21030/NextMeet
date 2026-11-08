import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'plan_trip_screen.dart';
import 'trip_detail_hub_screen.dart';

/// NextMeet Trips Hub Screen
/// Strictly following NextMeet Redesign.pdf (Page 39)
class TripsHubScreen extends StatelessWidget {
  const TripsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cloudService = CloudRelationshipService();

    return StreamBuilder<RelationshipModel?>(
      stream: cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final relId = rel?.id;
        final hasTrip = rel != null && rel.tripDestination != null && rel.tripDestination!.isNotEmpty;
        final destination = hasTrip ? rel.tripDestination! : 'Pick a destination';
        final daysToGo = hasTrip && rel.tripDate != null ? rel.tripDate!.difference(DateTime.now()).inDays : 0;
        final dateStr = hasTrip && rel.tripDate != null && rel.tripEndDate != null
            ? '${DateFormat("d MMM").format(rel.tripDate!)} to ${DateFormat("d MMM yyyy").format(rel.tripEndDate!)}, 2 travellers'
            : (hasTrip && rel.tripDate != null
                ? DateFormat("d MMM yyyy").format(rel.tripDate!)
                : 'Tap + to choose your romantic getaway');

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
                      Expanded(
                        child: Row(
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
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Trips', style: AppTextStyles.display.copyWith(fontSize: 26)),
                                  Text(
                                    'Plan the next hello together',
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          VibrationService.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlanTripScreen(relId: relId)),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hero Card: Next Trip (Page 39)
                  GestureDetector(
                    onTap: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripDetailHubScreen(
                            destination: destination,
                            dates: dateStr,
                            relId: relId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.butter,
                              borderRadius: BorderRadius.circular(AppRadius.badge),
                            ),
                            child: Text(
                              hasTrip
                                  ? (daysToGo > 0 ? 'Next trip, $daysToGo days to go' : 'Trip in progress! ✈️')
                                  : 'Start planning together ✨',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.butterText,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasTrip ? 'Trip to $destination' : 'Plan your next trip',
                            style: AppTextStyles.title1.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Airport code flight path
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'YOU',
                                style: AppTextStyles.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Row(
                                      children: List.generate(
                                        16,
                                        (index) => Expanded(
                                          child: Container(
                                            height: 2,
                                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                            color: index % 2 == 0 ? Colors.white : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: 0.2,
                                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'HEART',
                                style: AppTextStyles.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.7,
                              minHeight: 6,
                              backgroundColor: Color(0x33FFFFFF),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.butter),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Planned 70%',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Past trips
                  Text('Past trips', style: AppTextStyles.heading),
                  const SizedBox(height: 12),

                  _pastTripCard(
                    title: 'Goa, Dec 2025',
                    subtitle: 'First reunion, 5 days',
                    cost: '₹18,400',
                    color: AppColors.coral,
                  ),
                  const SizedBox(height: 10),

                  _pastTripCard(
                    title: 'Hill trek, Jan 2026',
                    subtitle: '3 days together',
                    cost: '₹9,200',
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 24),

                  // Section: Dream trips
                  Text('Dream trips', style: AppTextStyles.heading),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _dreamTripCard('Lisbon', AppColors.butter, AppColors.butterText)),
                      const SizedBox(width: 10),
                      Expanded(child: _dreamTripCard('Kyoto', AppColors.ink, Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(child: _dreamTripCard('Iceland', AppColors.pinkLight, AppColors.primaryDark)),
                    ],
                  ),

                  const SizedBox(height: 28),

                  PrimaryButton(
                    text: 'Plan a new trip',
                    onPressed: () {
                      VibrationService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PlanTripScreen(relId: relId)),
                      );
                    },
                  ),

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

  Widget _pastTripCard({
    required String title,
    required String subtitle,
    required String cost,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.beach_access_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            cost,
            style: AppTextStyles.heading.copyWith(
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dreamTripCard(String city, Color bg, Color text) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.bottomLeft,
      child: Text(
        city,
        style: AppTextStyles.heading.copyWith(
          color: text,
          fontSize: 15,
        ),
      ),
    );
  }
}
