import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/models/relationship_model.dart';
import '../../core/models/calendar_event_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../plan/new_event_screen.dart';

/// NextMeet Shared Calendar Screen
/// Strictly following NextMeet Redesign.pdf (Page 35)
class CalendarScreen extends StatefulWidget {
  final String? relationshipId;
  const CalendarScreen({super.key, this.relationshipId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    VibrationService.light();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    VibrationService.light();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  Map<String, dynamic> _getCategoryStyle(String type) {
    switch (type.toLowerCase()) {
      case 'reunion':
        return {'emoji': '🌴', 'color': AppColors.mintSoft, 'textColor': AppColors.mintText};
      case 'flight':
      case 'travel':
        return {'emoji': '✈️', 'color': AppColors.partnerSoft, 'textColor': AppColors.partnerText};
      case 'call':
        return {'emoji': '📞', 'color': AppColors.butterSoft, 'textColor': AppColors.butterText};
      case 'milestone':
        return {'emoji': '🏆', 'color': AppColors.butterSoft, 'textColor': AppColors.butterText};
      case 'date':
      default:
        return {'emoji': '🍷', 'color': AppColors.pinkSoft, 'textColor': AppColors.primary};
    }
  }

  void _showEventDetail(CalendarEventModel event, String relId) {
    VibrationService.light();
    final style = _getCategoryStyle(event.type);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style['color'] as Color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(style['emoji'] as String, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: AppTextStyles.title1.copyWith(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(event.type, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${DateFormat('EEEE, d MMMM yyyy').format(event.date)} at ${DateFormat('h:mm a').format(event.date)}',
                      style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Text(
                    event.notes!,
                    style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        VibrationService.medium();
                        Navigator.pop(context);
                        try {
                          await _cloudService.deleteCalendarEvent(relId, event.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event removed from couple calendar')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
                          );
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.danger, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Delete Event',
                          style: AppTextStyles.button.copyWith(color: AppColors.danger, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Done',
                          style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = widget.relationshipId ?? rel?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: relId == null
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                        child: Row(
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
                                'Calendar',
                                style: AppTextStyles.title2.copyWith(fontSize: 18),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const MascotHeart(color: MascotColor.pink, size: 54),
                      const SizedBox(height: 14),
                      Text('No couple connected yet', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Pair with your partner to share calendar events together!', style: AppTextStyles.caption),
                      const Spacer(),
                    ],
                  )
                : StreamBuilder<List<CalendarEventModel>>(
                    stream: _cloudService.streamCalendarEvents(relId),
                    builder: (context, eventsSnapshot) {
                      final allEvents = eventsSnapshot.data ?? [];
                      final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
                      final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1: Mon ... 7: Sun

                      final dayEvents = allEvents.where((e) {
                        return e.date.year == _selectedDate.year &&
                            e.date.month == _selectedDate.month &&
                            e.date.day == _selectedDate.day;
                      }).toList();

                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          // Top Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                            child: Row(
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
                                'Calendar',
                                style: AppTextStyles.title2.copyWith(fontSize: 18),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                                GestureDetector(
                                  onTap: () {
                                    VibrationService.light();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NewEventScreen(relationshipId: relId),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Scrollable Calendar & Events
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Calendar Card Container (Page 35)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.hero),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: Column(
                                      children: [
                                        // Month Navigation
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              onPressed: _previousMonth,
                                              icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.ink),
                                            ),
                                            Text(
                                              DateFormat('MMMM yyyy').format(_currentMonth),
                                              style: AppTextStyles.title2.copyWith(fontSize: 18),
                                            ),
                                            IconButton(
                                              onPressed: _nextMonth,
                                              icon: const Icon(Icons.chevron_right_rounded, size: 28, color: AppColors.ink),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Weekday Headers
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                                            return SizedBox(
                                              width: 36,
                                              child: Text(
                                                d,
                                                textAlign: TextAlign.center,
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 8),

                                        // Month Grid
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: 42,
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 7,
                                            mainAxisSpacing: 6,
                                            crossAxisSpacing: 6,
                                            childAspectRatio: 1.0,
                                          ),
                                          itemBuilder: (context, index) {
                                            final dayOffset = index - (firstWeekday - 1);
                                            if (dayOffset < 0 || dayOffset >= daysInMonth) {
                                              return const SizedBox.shrink();
                                            }
                                            final day = dayOffset + 1;
                                            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                                            final isSelected = date.year == _selectedDate.year &&
                                                date.month == _selectedDate.month &&
                                                date.day == _selectedDate.day;

                                            final hasEvent = allEvents.any((e) =>
                                                e.date.year == date.year &&
                                                e.date.month == date.month &&
                                                e.date.day == date.day);

                                            return GestureDetector(
                                              onTap: () {
                                                VibrationService.light();
                                                setState(() => _selectedDate = date);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : (hasEvent ? AppColors.pinkSoft.withValues(alpha: 0.7) : Colors.transparent),
                                                  borderRadius: BorderRadius.circular(isSelected ? 20 : 8),
                                                ),
                                                alignment: Alignment.center,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$day',
                                                      style: AppTextStyles.body.copyWith(
                                                        fontSize: 13,
                                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : (hasEvent ? AppColors.primary : AppColors.ink),
                                                      ),
                                                    ),
                                                    if (hasEvent && !isSelected)
                                                      Container(
                                                        width: 4,
                                                        height: 4,
                                                        margin: const EdgeInsets.only(top: 2),
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.primary,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Agenda Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, d MMMM').format(_selectedDate),
                                        style: AppTextStyles.heading.copyWith(fontSize: 16),
                                      ),
                                      Text(
                                        '${dayEvents.length} event${dayEvents.length == 1 ? '' : 's'}',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Day Agenda Cards
                                  if (dayEvents.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.card),
                                        border: Border.all(color: AppColors.border, width: 1.5),
                                      ),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            const MascotHeart(color: MascotColor.butter, size: 48),
                                            const SizedBox(height: 8),
                                            Text('No events on this day', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                            const SizedBox(height: 2),
                                            Text('Tap + above to plan a date or call', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ...dayEvents.map((event) {
                                      final style = _getCategoryStyle(event.type);
                                      return GestureDetector(
                                        onTap: () => _showEventDetail(event, relId),
                                        child: Container(
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
                                                  color: style['color'] as Color,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Text(style['emoji'] as String, style: const TextStyle(fontSize: 20)),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      event.title,
                                                      style: AppTextStyles.heading.copyWith(fontSize: 15),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      DateFormat('h:mm a').format(event.date),
                                                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: style['color'] as Color,
                                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                                ),
                                                child: Text(
                                                  event.type,
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: style['textColor'] as Color,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),

                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
