import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Add New Event Screen / Modal
/// Strictly following NextMeet Redesign.pdf (Page 36)
class NewEventScreen extends StatefulWidget {
  final String? relationshipId;
  final String? partnerName;

  const NewEventScreen({super.key, this.relationshipId, this.partnerName});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  int _selectedAudienceIndex = 0; // 0: Both of us, 1: You, 2: Partner
  late List<String> _audiences;

  @override
  void initState() {
    super.initState();
    _audiences = ['Both of us', 'You', widget.partnerName ?? 'Partner'];
  }

  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Date', 'emoji': '🍷', 'color': AppColors.primary, 'bg': AppColors.pinkSoft},
    {'name': 'Flight', 'emoji': '✈️', 'color': AppColors.partner, 'bg': AppColors.partnerSoft},
    {'name': 'Call', 'emoji': '📞', 'color': AppColors.mintText, 'bg': AppColors.mintSoft},
    {'name': 'Milestone', 'emoji': '🏆', 'color': AppColors.butterText, 'bg': AppColors.butterSoft},
  ];

  bool _reminder = true;
  bool _videoCall = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }
    VibrationService.medium();
    setState(() => _isSaving = true);

    try {
      String? relId = widget.relationshipId;
      if (relId == null) {
        final rel = await _cloudService.streamRelationship().first;
        relId = rel?.id;
      }
      if (relId != null) {
        final combinedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        final category = _categories[_selectedCategoryIndex]['name'] as String;
        await _cloudService.addCalendarEvent(
          relId,
          _titleController.text.trim(),
          combinedDateTime,
          category,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      }
      if (!mounted) return;
      VibrationService.success();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                  Text('Add Event', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveEvent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _isSaving ? '...' : 'Save',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Input
                    Text('Title', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Discord Movie Night',
                        prefixIcon: Icon(Icons.event_note_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Date & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.input),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_selectedDate),
                                        style: AppTextStyles.body.copyWith(color: AppColors.ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Time', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickTime,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.input),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedTime.format(context),
                                        style: AppTextStyles.body.copyWith(color: AppColors.ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Who is it for? (Page 36)
                    Text('Who is it for?', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Row(
                      children: _audiences.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final label = entry.value;
                        final isSelected = _selectedAudienceIndex == idx;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _selectedAudienceIndex = idx);
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: idx < _audiences.length - 1 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Category Chips (Page 36)
                    Text('Category', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cat = entry.value;
                        final isSelected = _selectedCategoryIndex == idx;

                        return GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            setState(() => _selectedCategoryIndex = idx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat['emoji'] as String, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  cat['name'] as String,
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Toggles (Reminder & Video Call Link)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: _reminder,
                            activeColor: AppColors.primary,
                            title: Text('Remind us 1 day before', style: AppTextStyles.body),
                            subtitle: Text('Sends push notifications to both', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                            onChanged: (val) {
                              VibrationService.light();
                              setState(() => _reminder = val);
                            },
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          SwitchListTile.adaptive(
                            value: _videoCall,
                            activeColor: AppColors.primary,
                            title: Text('Add video call link', style: AppTextStyles.body),
                            subtitle: Text('One-tap connect inside the app', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                            onChanged: (val) {
                              VibrationService.light();
                              setState(() => _videoCall = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    PrimaryButton(
                      text: 'Add to Calendar',
                      isLoading: _isSaving,
                      onPressed: _saveEvent,
                    ),

                    const SizedBox(height: 24),
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
