import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Live Flight & Travel Tracker Screen
/// Strictly following NextMeet Redesign.pdf (Page 46)
class TravelTrackerScreen extends StatefulWidget {
  const TravelTrackerScreen({super.key});

  @override
  State<TravelTrackerScreen> createState() => _TravelTrackerScreenState();
}

class _TravelTrackerScreenState extends State<TravelTrackerScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  bool _notifyBoarding = true;
  bool _notifyLanding = true;
  bool _syncHome = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        final rel = snapshot.data;
        final partnerName = rel?.getPartnerName(_cloudService.currentUid) ?? 'Partner';
        final dest = rel?.tripDestination != null && rel!.tripDestination!.isNotEmpty
            ? rel.tripDestination!
            : 'Goa';
        final daysToMeet = rel?.nextMeetingDate != null
            ? rel!.nextMeetingDate.difference(DateTime.now()).inDays
            : 18;

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
                      Text('Live Travel Tracker', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.mint, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'In Flight',
                              style: AppTextStyles.caption.copyWith(color: AppColors.mintText, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Hero Flight Status Card (Page 46)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // Carrier & Flight Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.partnerSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.flight_rounded, color: AppColors.partner, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Flight to $dest', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                    Text('Couple Reunion Route', style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mintSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text('ON TIME', style: AppTextStyles.label.copyWith(color: AppColors.mintText, fontSize: 10)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Airport Code Route
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DEP', style: AppTextStyles.display.copyWith(fontSize: 32, color: AppColors.partner)),
                                Text('Origin', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                const SizedBox(height: 4),
                                Text('10:45 AM', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                                Text('Gate B24', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 28),
                                const SizedBox(height: 4),
                                Text('$daysToMeet days left', style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('ARR', style: AppTextStyles.display.copyWith(fontSize: 32, color: AppColors.primary)),
                                Text(dest, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                const SizedBox(height: 4),
                                Text('11:30 PM', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                                Text('Terminal 4', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Flight Route Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: const LinearProgressIndicator(
                                value: 0.68,
                                minHeight: 10,
                                backgroundColor: AppColors.pinkSoft,
                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Departed 5h 30m ago', style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11)),
                                Text('Landing soon 🛬', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Reunion Countdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pinkSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const MascotHeart(color: MascotColor.pink, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$partnerName is reuniting with you!', style: AppTextStyles.heading.copyWith(fontSize: 15, color: AppColors.primary)),
                              const SizedBox(height: 2),
                              Text(
                                daysToMeet > 0
                                    ? '$daysToMeet days until your next reunion in $dest ❤️'
                                    : 'Reunion day is here! ❤️',
                                style: AppTextStyles.caption.copyWith(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 20),

              // Alert Toggles (Page 46)
              Text('Tracker Alerts', style: AppTextStyles.heading.copyWith(fontSize: 16)),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _notifyBoarding,
                      activeColor: AppColors.primary,
                      title: Text('Notify when $partnerName boards', style: AppTextStyles.body),
                      subtitle: Text('Instant notification as gates close', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                      onChanged: (val) {
                        VibrationService.light();
                        setState(() => _notifyBoarding = val);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SwitchListTile.adaptive(
                      value: _notifyLanding,
                      activeColor: AppColors.primary,
                      title: Text('Notify on touchdown', style: AppTextStyles.body),
                      subtitle: Text('Triggers gentle heart haptic pulse', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                      onChanged: (val) {
                        VibrationService.light();
                        setState(() => _notifyLanding = val);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    SwitchListTile.adaptive(
                      value: _syncHome,
                      activeColor: AppColors.primary,
                      title: Text('Sync to Home Dashboard', style: AppTextStyles.body),
                      subtitle: Text('Shows live flight arc on the main map', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                      onChanged: (val) {
                        VibrationService.light();
                        setState(() => _syncHome = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
