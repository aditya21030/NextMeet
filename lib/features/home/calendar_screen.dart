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
  DateTime? _selectedDate;

  late final Stream<RelationshipModel?> _relStream;
  late final Stream<List<CalendarEventModel>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _relStream = _cloudService.streamRelationship();
    _eventsStream = _cloudService.streamCalendarEvents(widget.relationshipId);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _addEvent({RelationshipModel? rel}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String tempType = 'Date';
    bool isSaving = false;

    final categories = [
      {'name': 'Date', 'emoji': '🍷'},
      {'name': 'Travel', 'emoji': '✈️'},
      {'name': 'Reunion', 'emoji': '💖'},
      {'name': 'Special', 'emoji': '✨'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: AppSpacing.l,
            left: AppSpacing.l,
            right: AppSpacing.l,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag pill
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add to Calendar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Keep upcoming plans in sync',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick Ideas Presets
                const Text(
                  'Quick Ideas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      {'title': 'Dinner Date 🍷', 'type': 'Date'},
                      {'title': 'Movie Night 🍿', 'type': 'Date'},
                      {'title': 'Flight Arrival ✈️', 'type': 'Travel'},
                      {'title': 'Video Call 📞', 'type': 'Date'},
                      {'title': 'Next Reunion 💖', 'type': 'Reunion'},
                      {'title': 'Surprise Gift 🎁', 'type': 'Special'},
                      {'title': 'Weekend Trip 🏖️', 'type': 'Travel'},
                    ].map((preset) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          VibrationService.light();
                          setModalState(() {
                            titleController.text = preset['title']!;
                            tempType = preset['type']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: titleController.text == preset['title']
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: titleController.text == preset['title']
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            preset['title']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: titleController.text == preset['title']
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: titleController.text == preset['title']
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Event Title Input
                const Text(
                  'Event Title',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Flight to Mumbai, Anniversary dinner',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Date Picker Tile
                const Text(
                  'Date',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Category Chips
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: categories.map((cat) {
                    final isSelected = tempType == cat['name'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => setModalState(() => tempType = cat['name'] as String),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                              ),
                              boxShadow: isSelected ? AppColors.buttonShadow : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cat['emoji'] as String,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat['name'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Notes / Location (Optional)
                const Text(
                  'Notes or Location (optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Flight AI-102, Terminal 2',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                InkWell(
                  onTap: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isNotEmpty) {
                            setModalState(() => isSaving = true);
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: Center(
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save to Calendar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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
      stream: _relStream,
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
          ),
          body: StreamBuilder<List<CalendarEventModel>>(
            stream: _eventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allEvents = snapshot.data ?? [];
              final filteredEvents = allEvents.where((e) {
                final matchesType = _selectedFilter == 'All' || e.type == _selectedFilter;
                final matchesDate = _selectedDate == null || _isSameDay(e.date, _selectedDate!);
                return matchesType && matchesDate;
              }).toList();

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

                  // 2. Interactive Horizontal Date Strip (Mini-Calendar Bar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat.yMMMM().format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (_selectedDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      VibrationService.light();
                                      setState(() => _selectedDate = null);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Show All Days',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(Icons.close_rounded, size: 12, color: AppColors.primary),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 72,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                              itemCount: 28, // 4 weeks
                              itemBuilder: (context, index) {
                                final day = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                                final isToday = _isSameDay(day, DateTime.now());
                                final isSelected = _selectedDate != null && _isSameDay(day, _selectedDate!);
                                final hasEvent = allEvents.any((e) => _isSameDay(e.date, day));

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      VibrationService.light();
                                      setState(() {
                                        if (isSelected) {
                                          _selectedDate = null;
                                        } else {
                                          _selectedDate = day;
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 48,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isToday ? AppColors.primary.withValues(alpha: 0.08) : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isToday ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider),
                                          width: isSelected || isToday ? 1.5 : 1,
                                        ),
                                        boxShadow: isSelected ? AppColors.buttonShadow : AppColors.softShadow,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('E').format(day).substring(0, 3).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? Colors.white70
                                                  : (isToday ? AppColors.primary : AppColors.textSecondary),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            DateFormat('d').format(day),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isToday ? AppColors.primary : AppColors.textPrimary),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: hasEvent
                                                  ? (isSelected ? Colors.white : AppColors.primary)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Category Filter Pills
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
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'UPCOMING PLANS (${filteredEvents.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            InkWell(
                              onTap: () => _addEvent(rel: rel),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add Event',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.xl),
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
                ],
              );
            },
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
        ? 'Today ✨'
        : daysDiff == 1
            ? 'Tomorrow 💖'
            : daysDiff > 1
                ? 'In $daysDiff days'
                : daysDiff == -1
                    ? 'Yesterday'
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
