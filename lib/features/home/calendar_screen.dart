import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/calendar_event_model.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_inputs.dart';

class CalendarScreen extends StatefulWidget {
  final String relationshipId;
  const CalendarScreen({super.key, required this.relationshipId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final List<String> _eventTypes = ['Date', 'Travel', 'Reunion', 'Special'];
  String _selectedFilter = 'All';

  void _addEvent({RelationshipModel? rel}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String tempType = 'Date';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Schedule Event 📅', style: AppTextStyles.h3),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: AppInputs.premiumInput('Event Name (e.g. Flight to Mumbai ✈️)'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat.yMMMMd().format(selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _eventTypes.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: tempType == t,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: tempType == t ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: tempType == t ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) => setModalState(() => tempType = t),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: AppInputs.premiumInput('Notes / Location (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  VibrationService.success();
                  await _cloudService.addCalendarEvent(
                    widget.relationshipId,
                    title,
                    selectedDate,
                    tempType,
                    notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('SCHEDULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      notesController.dispose();
    });
  }

  void _pickReunionDate(DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(days: 14)) : currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      VibrationService.success();
      await _cloudService.updateNextMeetingDate(widget.relationshipId, picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Next Reunion set to ${DateFormat.yMMMMd().format(picked)}! 🎉'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final nextMeetDate = rel?.nextMeetingDate ?? DateTime.now().add(const Duration(days: 30));
        final bool isPast = DateTime.now().isAfter(nextMeetDate);
        final daysUntil = isPast ? 0 : nextMeetDate.difference(DateTime.now()).inDays;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Shared Calendar 🗓️', style: AppTextStyles.h3),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
                onPressed: () => _addEvent(rel: rel),
                tooltip: 'Add Plan',
              ),
            ],
          ),
          body: StreamBuilder<List<CalendarEventModel>>(
            stream: _cloudService.streamCalendarEvents(widget.relationshipId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allEvents = snapshot.data ?? [];
              final filteredEvents = _selectedFilter == 'All'
                  ? allEvents
                  : allEvents.where((e) => e.type == _selectedFilter).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Next Reunion Hero Banner Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, 0),
                      child: FadeInDown(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF18181B), Color(0xFF27272A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.flight_takeoff_rounded, color: Color(0xFFFB7185), size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'NEXT REUNION',
                                          style: TextStyle(
                                            color: Color(0xFFFB7185),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _pickReunionDate(nextMeetDate),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit_calendar_rounded, color: Colors.white70, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change Date',
                                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat.yMMMMd().format(nextMeetDate),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isPast ? 'Ready to plan the next one!' : 'Counting down together ❤️',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: AppColors.buttonShadow,
                                    ),
                                    child: Text(
                                      isPast ? 'TODAY 🎉' : '$daysUntil DAYS LEFT',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Category Filter Pills
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.m),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', ..._eventTypes].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  VibrationService.light();
                                  setState(() => _selectedFilter = filter);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isSelected ? AppColors.buttonShadow : AppColors.softShadow,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // 3. Events List or Empty State
                  if (filteredEvents.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.calendar_month_rounded, size: 56, color: AppColors.primary),
                              ),
                              const SizedBox(height: 20),
                              Text('No ${_selectedFilter == "All" ? "" : _selectedFilter} plans yet', style: AppTextStyles.h3),
                              const SizedBox(height: 8),
                              Text(
                                'Planning dates & flights makes the distance easier ❤️',
                                style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _addEvent(rel: rel),
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                label: const Text('PLAN A DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final event = filteredEvents[index];
                            return _buildEventTile(event);
                          },
                          childCount: filteredEvents.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addEvent(rel: rel),
            backgroundColor: AppColors.primary,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('PLAN EVENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        );
      },
    );
  }

  Widget _buildEventTile(CalendarEventModel event) {
    IconData icon;
    Color color;

    switch (event.type) {
      case 'Travel':
        icon = Icons.flight_rounded;
        color = const Color(0xFF0EA5E9);
        break;
      case 'Reunion':
        icon = Icons.favorite_rounded;
        color = const Color(0xFFE11D48);
        break;
      case 'Special':
        icon = Icons.star_rounded;
        color = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.restaurant_rounded;
        color = const Color(0xFFEC4899);
    }

    final bool isToday = event.date.day == DateTime.now().day &&
        event.date.month == DateTime.now().month &&
        event.date.year == DateTime.now().year;

    final daysDiff = event.date.difference(DateTime.now()).inDays;
    final String countdownPill = isToday
        ? 'TODAY 🎉'
        : daysDiff > 0
            ? 'In $daysDiff days'
            : '${daysDiff.abs()} days ago';

    return FadeInLeft(
      delay: const Duration(milliseconds: 60),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Badge (Day + Month)
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isToday ? AppColors.buttonShadow : AppColors.softShadow,
                border: Border.all(
                  color: isToday ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat.MMM().format(event.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isToday ? Colors.white70 : AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.d().format(event.date),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isToday ? Colors.white : AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Event Details Card
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  event.type,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                countdownPill,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (event.notes != null && event.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              event.notes!,
                              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                      tooltip: 'Delete Event',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
                            title: const Text('Delete Event?'),
                            content: Text('Remove "${event.title}" from your shared calendar?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          VibrationService.medium();
                          await _cloudService.deleteCalendarEvent(widget.relationshipId, event.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
