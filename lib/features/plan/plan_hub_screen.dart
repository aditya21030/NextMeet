import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/calendar_event_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../home/calendar_screen.dart';
import 'trips_hub_screen.dart';
import 'new_event_screen.dart';
import 'milestones_screen.dart';
import 'trip_detail_hub_screen.dart';

/// NextMeet Plan Tab Main Dashboard
/// Strictly following NextMeet Redesign.pdf (Page 34)
class PlanHubScreen extends StatefulWidget {
  const PlanHubScreen({super.key});

  @override
  State<PlanHubScreen> createState() => _PlanHubScreenState();
}

class _PlanHubScreenState extends State<PlanHubScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
  }

  void _showAddBucketItemDialog(String relId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to Bucket List', style: AppTextStyles.title2),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Watch Northern Lights together',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                VibrationService.light();
                Navigator.pop(context);
                await _cloudService.addBucketItem(relId, text, 'Couples');
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = rel?.id;

        final nextMeetDate = rel?.nextMeetingDate ?? DateTime.now().add(const Duration(days: 23));
        final nextMeetDays = nextMeetDate.difference(DateTime.now()).inDays;
        final nextMeetDaysStr = nextMeetDays > 0 ? '$nextMeetDays' : '0';

        final now = DateTime.now();

        return StreamBuilder<List<CalendarEventModel>>(
          stream: relId != null ? _cloudService.streamCalendarEvents(relId) : const Stream.empty(),
          builder: (context, calSnapshot) {
            final events = calSnapshot.data ?? [];

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    VibrationService.light();
                    if (mounted) setState(() {});
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // Top Bar: "Plan" + Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Plan', style: AppTextStyles.display.copyWith(fontSize: 28)),
                            ),
                            Row(
                              children: [
                                // Link to Milestones (Page 37)
                                GestureDetector(
                                  onTap: () {
                                    VibrationService.light();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MilestonesScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.butterSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.badge),
                                    ),
                                    child: Text(
                                      'Goals 🏆',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.butterText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Link to Trips Hub (Page 39)
                                GestureDetector(
                                  onTap: () {
                                    VibrationService.light();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TripsHubScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.pinkSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.badge),
                                    ),
                                    child: Text(
                                      'Trips ✈️',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    VibrationService.light();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => NewEventScreen(relationshipId: relId)),
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Hero Meetup Countdown Card (Page 34)
                        GestureDetector(
                          onTap: () async {
                            if (relId == null) return;
                            VibrationService.light();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: nextMeetDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                              builder: (context, child) => Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: AppColors.ink,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              await _cloudService.updateNextMeetingDate(relId, picked);
                              if (context.mounted) {
                                VibrationService.success();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Reunion date set for ${DateFormat("d MMM yyyy").format(picked)}! 🎉'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Next meetup', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit_calendar_outlined, size: 14, color: AppColors.muted),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintSoft,
                                        borderRadius: BorderRadius.circular(AppRadius.badge),
                                      ),
                                      child: Text(
                                        nextMeetDays > 0 ? 'Countdown live' : 'Today! 🎉',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.mintText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$nextMeetDaysStr ',
                                        style: AppTextStyles.display.copyWith(
                                          fontSize: 34,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'days, ${DateFormat("EEE d MMM").format(nextMeetDate)}',
                                        style: AppTextStyles.title2.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Mascots Connected by Airplane Trail
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const MascotHeart(color: MascotColor.pink, size: 44, leanRight: true),
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Row(
                                            children: List.generate(
                                              18,
                                              (index) => Expanded(
                                                child: Container(
                                                  height: 2,
                                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                  color: index % 2 == 0 ? AppColors.primary : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Transform.rotate(
                                            angle: 0.1,
                                            child: const Icon(Icons.send_rounded, color: AppColors.ink, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const MascotHeart(color: MascotColor.violet, size: 44, leanLeft: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Calendar Strip: Horizontal Week Strip (Page 34)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (i) {
                              final dayDate = now.add(Duration(days: i - now.weekday + 1));
                              final dayName = DateFormat('E').format(dayDate);
                              final isSelected = _selectedDay == dayDate.day;
                              final hasEvent = events.any((e) =>
                                  e.date.year == dayDate.year &&
                                  e.date.month == dayDate.month &&
                                  e.date.day == dayDate.day);
                              return _weekDayColumn(
                                dayName,
                                dayDate.day,
                                isSelected: isSelected,
                                hasDot: hasEvent,
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section: Coming up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Coming up', style: AppTextStyles.heading),
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CalendarScreen(relationshipId: relId)),
                                );
                              },
                              child: Text(
                                'See calendar',
                                style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (relId == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const MascotHeart(color: MascotColor.pink, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Connect to schedule events', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('Pair your partner to sync date nights and calls!', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (events.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('No upcoming events scheduled. Tap + to add one!', style: AppTextStyles.caption),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: () {
                              final selectedDayEvents = events.where((e) => e.date.day == _selectedDay && e.date.month == now.month).toList();
                              final displayEvents = selectedDayEvents.isNotEmpty ? selectedDayEvents : events.take(3).toList();
                              return displayEvents.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _eventRow(
                                    icon: e.type == 'Call'
                                        ? Icons.call_rounded
                                        : (e.type == 'Flight' ? Icons.flight_takeoff_rounded : Icons.favorite_rounded),
                                    iconColor: e.type == 'Flight' ? AppColors.partner : AppColors.primary,
                                    title: e.title,
                                    subtitle: '${DateFormat('EEE d MMM').format(e.date)} at ${DateFormat('h:mm a').format(e.date)}',
                                  ),
                                );
                              }).toList();
                            }(),
                          ),

                        const SizedBox(height: 20),

                  // Section: Bucket list from Cloud Stream
                  if (relId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: _cloudService.streamBucketItems(relId),
                      builder: (context, bucketSnapshot) {
                        final docs = bucketSnapshot.data?.docs ?? [];
                        final completedCount = docs.where((d) => (d.data() as Map<String, dynamic>)['isCompleted'] == true).length;
                        final ratioStr = docs.isNotEmpty ? '$completedCount/${docs.length}' : '0/0';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Circular progress ring
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.primary, width: 3.5),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          ratioStr,
                                          style: AppTextStyles.heading.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Bucket list', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                                          Text('Things to do together', style: AppTextStyles.caption),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                    onPressed: () => _showAddBucketItemDialog(relId),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (docs.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No bucket list items yet. Tap + to add dreams!',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                  ),
                                )
                              else
                                ...docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final title = data['title']?.toString() ?? 'Dream';
                                  final isDone = data['isCompleted'] == true;

                                  return Dismissible(
                                    key: Key(doc.id),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) {
                                      VibrationService.light();
                                      _cloudService.deleteBucketItem(relId, doc.id);
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        VibrationService.light();
                                        _cloudService.toggleBucketItem(relId, doc.id, !isDone);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: isDone ? AppColors.primary : Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isDone ? AppColors.primary : AppColors.border,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isDone
                                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: AppTextStyles.body.copyWith(
                                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                                  color: isDone ? AppColors.muted : AppColors.ink,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
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
    },
  );
}

  Widget _weekDayColumn(String day, int date, {bool isSelected = false, bool hasDot = false}) {
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        setState(() => _selectedDay = date);
      },
      child: Column(
        children: [
          Text(day, style: AppTextStyles.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$date',
              style: AppTextStyles.heading.copyWith(
                fontSize: 15,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (hasDot)
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.partner, shape: BoxShape.circle))
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _eventRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
        ],
      ),
    );
  }
}
