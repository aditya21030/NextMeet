import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Plan a Trip Screen
/// Strictly following NextMeet Redesign.pdf (Page 40)
class PlanTripScreen extends StatefulWidget {
  final String? relId;
  const PlanTripScreen({super.key, this.relId});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final TextEditingController _destinationController = TextEditingController(text: 'Goa, India');
  final TextEditingController _budgetController = TextEditingController(text: '45000');
  DateTime _startDate = DateTime.now().add(const Duration(days: 23));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  int _selectedTypeIndex = 0;
  final List<Map<String, dynamic>> _tripTypes = [
    {'name': 'Reunion', 'emoji': '❤️', 'color': AppColors.primary, 'bg': AppColors.pinkSoft},
    {'name': 'Holiday', 'emoji': '🏖️', 'color': AppColors.mintText, 'bg': AppColors.mintSoft},
    {'name': 'Weekend', 'emoji': '☕', 'color': AppColors.butterText, 'bg': AppColors.butterSoft},
    {'name': 'Surprise', 'emoji': '🎁', 'color': AppColors.partner, 'bg': AppColors.partnerSoft},
  ];

  bool _trackTransit = true;
  bool _isSaving = false;

  final List<String> _quickDestinations = ['Goa', 'Maldives', 'Paris', 'Bali', 'Dubai'];

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _createTrip() async {
    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }
    VibrationService.medium();
    setState(() => _isSaving = true);

    try {
      String? relId = widget.relId;
      if (relId == null) {
        final rel = await _cloudService.streamRelationship().first;
        relId = rel?.id;
      }
      if (relId != null) {
        final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
        final tripType = _tripTypes[_selectedTypeIndex]['name'] as String;
        await _cloudService.setTripPlan(
          relId,
          destination: _destinationController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          budget: budget,
          tripType: tripType,
          trackTransit: _trackTransit,
        );
      }
      if (!mounted) return;
      VibrationService.success();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save trip: $e')),
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
                  Text('Plan a Trip', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  GestureDetector(
                    onTap: _isSaving ? null : _createTrip,
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

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Destination Input
                    Text('Destination', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _destinationController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Goa, India',
                        prefixIcon: Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Suggestion Chips
                    Wrap(
                      spacing: 8,
                      children: _quickDestinations.map((d) {
                        return GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            setState(() => _destinationController.text = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Text(d, style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 11)),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Dates Range Selector
                    Text('Travel Dates', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDates,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Text(
                              '${_endDate.difference(_startDate).inDays} days',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Trip Type Chips (Page 40)
                    Text('Trip Style', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Row(
                      children: _tripTypes.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final type = entry.value;
                        final isSelected = _selectedTypeIndex == idx;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _selectedTypeIndex = idx);
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: idx < _tripTypes.length - 1 ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(type['emoji'] as String, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(
                                    type['name'] as String,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : AppColors.ink,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Estimated Budget Input
                    Text('Shared Budget (₹)', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 50000',
                        prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Live Transit Tracking Toggle
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.partnerSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.partner, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Transit Tracker', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  'Track partner flight & landing countdown',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _trackTransit,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              VibrationService.light();
                              setState(() => _trackTransit = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Primary Button
                    PrimaryButton(
                      text: 'Create Trip',
                      isLoading: _isSaving,
                      onPressed: _createTrip,
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
