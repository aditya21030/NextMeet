import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';
import 'moments_camera_screen.dart';
import 'moment_viewer_screen.dart';

/// NextMeet Moments Hub Screen (Daily Widget Photos)
/// Strictly following NextMeet Redesign.pdf (Page 26)
class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  final List<Map<String, dynamic>> _weekReel = [
    {'day': 'M', 'done': true},
    {'day': 'T', 'done': true},
    {'day': 'W', 'done': true},
    {'day': 'T', 'done': true},
    {'day': 'F', 'done': true},
    {'day': 'S', 'done': true},
    {'day': 'S', 'done': false, 'isToday': true},
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = rel?.id ?? 'default_rel';
        final myUid = _cloudService.currentUid;
        final myName = rel?.getMyName(myUid) ?? 'You';
        final partnerName = rel?.getPartnerName(myUid) ?? 'Partner';
        final streak = rel?.streakCount ?? 1;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamMoments(relId),
              builder: (context, momentSnapshot) {
                final momentDocs = momentSnapshot.data?.docs ?? [];
                Map<String, dynamic>? latestMyMoment;
                Map<String, dynamic>? latestPartnerMoment;

                for (final doc in momentDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['senderUid'] == myUid && latestMyMoment == null) {
                    latestMyMoment = data;
                  } else if (data['senderUid'] != myUid && latestPartnerMoment == null) {
                    latestPartnerMoment = data;
                  }
                  if (latestMyMoment != null && latestPartnerMoment != null) break;
                }

                final myCaption = latestMyMoment?['caption'] ?? 'Coffee time thinking of you ☕';
                final partnerCaption = latestPartnerMoment?['caption'] ?? 'Walking in autumn leaves 🍂';

                return SingleChildScrollView(
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
                          Text('Moments', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.butterSoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.butter, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak days',
                                  style: AppTextStyles.heading.copyWith(fontSize: 12, color: AppColors.butterText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 7-Day Circular Streak Reel (Page 26)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _weekReel.map((item) {
                            final isDone = item['done'] as bool;
                            final isToday = item['isToday'] == true;

                            return Column(
                              children: [
                                Text(
                                  item['day'] as String,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isToday ? AppColors.primary : AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? AppColors.primary
                                        : (isToday ? AppColors.pinkSoft : Colors.white),
                                    border: Border.all(
                                      color: isToday ? AppColors.primary : (isDone ? AppColors.primary : AppColors.border),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                        : (isToday
                                            ? const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 18)
                                            : null),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Daily Split Card (Page 26)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.hero),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Top header in card
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.widgets_outlined, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text("Today's Widget Photo", style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                    ],
                                  ),
                                  Text(
                                    momentDocs.isNotEmpty ? 'Live Sync' : 'Ready',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border, thickness: 1.5),

                            // Split Photos Row (You vs Partner)
                            SizedBox(
                              height: 200,
                              child: Row(
                                children: [
                                  // You side
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        VibrationService.light();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MomentViewerScreen(
                                              authorName: myName,
                                              caption: myCaption,
                                              color: MascotColor.pink,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        color: AppColors.pinkSoft,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const MascotHeart(color: MascotColor.pink, size: 56),
                                            Positioned(
                                              bottom: 12,
                                              left: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                                ),
                                                child: Text(myName, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(width: 2, color: AppColors.border),
                                  // Partner side
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        VibrationService.light();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MomentViewerScreen(
                                              authorName: partnerName,
                                              caption: partnerCaption,
                                              color: MascotColor.violet,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        color: AppColors.partnerSoft,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const MascotHeart(color: MascotColor.violet, size: 56),
                                            Positioned(
                                              bottom: 12,
                                              left: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                                ),
                                                child: Text(partnerName, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800)),
                                              ),
                                            ),
                                          ],
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

                      const SizedBox(height: 16),

                      // CTA to Send Today's Moment (Page 26)
                      PrimaryButton(
                        text: "Send Today's Moment 📸",
                        onPressed: () {
                          VibrationService.medium();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MomentsCameraScreen(relId: relId),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Archive Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Moments', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                          Text(
                            '${momentDocs.length} captured',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (momentDocs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              const MascotHeart(color: MascotColor.butter, size: 48),
                              const SizedBox(height: 10),
                              Text('No moments yet', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "Send Today\'s Moment" to capture a sweet daily snippet for your partner!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        )
                      else
                        ...momentDocs.map((doc) {
                          final item = doc.data() as Map<String, dynamic>;
                          final caption = item['caption'] ?? 'Thinking of you 💕';
                          final frame = item['frame'] ?? 'Plain';
                          final isMe = item['senderUid'] == myUid;
                          final author = isMe ? myName : partnerName;
                          final ts = (item['timestamp'] as Timestamp?)?.toDate();
                          final dateStr = ts != null ? DateFormat('d MMM, h:mm a').format(ts) : 'Recently';

                          return Dismissible(
                            key: ValueKey(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                            ),
                            onDismissed: (_) {
                              VibrationService.light();
                              _cloudService.deleteMoment(relId, doc.id);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
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
                                      color: isMe ? AppColors.pinkSoft : AppColors.partnerSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.photo_camera_rounded,
                                        color: isMe ? AppColors.primary : AppColors.partner,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(caption, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$author • $dateStr • $frame',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 14),
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
