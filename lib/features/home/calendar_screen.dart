import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
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
  final String _selectedType = 'Date';

  void _addEvent() {
    final TextEditingController controller = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String tempType = _selectedType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text('Schedule Event 📅', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: AppInputs.premiumInput('Event Name (e.g. Movie Night)'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date'),
                      Text(DateFormat.yMMMMd().format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _eventTypes.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: tempType == t,
                      onSelected: (val) => setModalState(() => tempType = t),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _cloudService.addCalendarEvent(widget.relationshipId, controller.text, selectedDate, tempType);
                  VibrationService.success();
      // ignore: use_build_context_synchronously
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('SCHEDULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _cloudService.streamCalendarEvents(widget.relationshipId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeIn(child: const Icon(Icons.calendar_today_rounded, size: 64, color: AppColors.divider)),
                  const SizedBox(height: 16),
                  Text('No events scheduled.', style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Planned dates make the distance easier ❤️', style: AppTextStyles.bodyS),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final doc = events[index];
              final data = doc.data() as Map<String, dynamic>;
              final DateTime date = (data['eventDate'] as Timestamp).toDate();
              
              return _buildEventTile(doc.id, data, date);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.event_rounded, color: Colors.white),
        label: const Text('PLAN EVENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEventTile(String eventId, Map<String, dynamic> data, DateTime date) {
    String type = data['type'] ?? 'Date';
    IconData icon;
    Color color;

    switch(type) {
      case 'Travel': icon = Icons.flight_rounded; color = Colors.blue; break;
      case 'Reunion': icon = Icons.favorite_rounded; color = Colors.redAccent; break;
      case 'Special': icon = Icons.star_rounded; color = Colors.amber; break;
      default: icon = Icons.restaurant_rounded; color = Colors.pink;
    }

    final bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;

    return FadeInLeft(
      delay: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(DateFormat.MMM().format(date).toUpperCase(), style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
                Text(DateFormat.d().format(date), style: AppTextStyles.h2.copyWith(fontSize: 24, height: 1)),
                if (isToday) Container(margin: const EdgeInsets.only(top: 4), width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? '', style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold)),
                          Text(type, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Event?'),
                            content: const Text('Are you sure you want to remove this event from your shared calendar?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _cloudService.deleteCalendarEvent(widget.relationshipId, eventId);
                          VibrationService.medium();
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
