import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'trip_packing_screen.dart';
import 'trip_budget_screen.dart';
import 'travel_tracker_screen.dart';

/// NextMeet Trip Detail & Itinerary Hub Screen
/// Strictly following NextMeet Redesign.pdf (Pages 41-42)
class TripDetailHubScreen extends StatefulWidget {
  final String destination;
  final String dates;
  final String? relId;

  const TripDetailHubScreen({
    super.key,
    this.destination = 'Goa, India',
    this.dates = '14 Oct - 20 Oct 2025',
    this.relId,
  });

  @override
  State<TripDetailHubScreen> createState() => _TripDetailHubScreenState();
}

class _TripDetailHubScreenState extends State<TripDetailHubScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  int _selectedDayIndex = 0;
  final List<String> _days = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5'];

  void _showAddActivityModal(String relId) {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '10:00 AM');
    final locController = TextEditingController();
    String selectedTag = 'Sightseeing';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 16),
                  Text('Add Trip Activity', style: AppTextStyles.title2),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: titleController,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'Activity title e.g. Rent Scooters',
                      prefixIcon: Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: timeController,
                          style: AppTextStyles.body,
                          decoration: const InputDecoration(
                            hintText: 'Time',
                            prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: locController,
                          style: AppTextStyles.body,
                          decoration: const InputDecoration(
                            hintText: 'Location',
                            prefixIcon: Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Add to Itinerary',
                    onPressed: () async {
                      if (titleController.text.trim().isNotEmpty) {
                        VibrationService.medium();
                        Navigator.pop(context);
                        try {
                          await _cloudService.addItineraryItem(
                            relId,
                            titleController.text.trim(),
                            locController.text.trim().isNotEmpty ? locController.text.trim() : widget.destination,
                            DateTime.now().add(Duration(days: _selectedDayIndex)),
                            category: selectedTag,
                            slot: timeController.text.trim(),
                          );
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      timeController.dispose();
      locController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = widget.relId ?? rel?.id;

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
                      Expanded(
                        child: Text(
                          'Trip Plan',
                          style: AppTextStyles.title2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (relId != null) {
                            VibrationService.light();
                            _showAddActivityModal(relId);
                          }
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

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Destination Banner (Page 41)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(color: AppColors.border, width: 1.5),
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
                                      color: AppColors.pinkSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      'REUNION TRIP',
                                      style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 10),
                                    ),
                                  ),
                                  Text(
                                    'Couple Getaway ✈️',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(widget.destination, style: AppTextStyles.title1.copyWith(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(widget.dates, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 3 Feature Sub-Hub Quick Nav Buttons (Page 41)
                        Row(
                          children: [
                            Expanded(
                              child: _featureNavButton(
                                title: 'Packing',
                                icon: Icons.backpack_outlined,
                                color: AppColors.primary,
                                bg: AppColors.pinkSoft,
                                onTap: () {
                                  VibrationService.light();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => TripPackingScreen(relId: relId)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _featureNavButton(
                                title: 'Budget',
                                icon: Icons.account_balance_wallet_outlined,
                                color: AppColors.partner,
                                bg: AppColors.partnerSoft,
                                onTap: () {
                                  VibrationService.light();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => TripBudgetScreen(relId: relId)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _featureNavButton(
                                title: 'Tracker',
                                icon: Icons.flight_takeoff_rounded,
                                color: AppColors.mintText,
                                bg: AppColors.mintSoft,
                                onTap: () {
                                  VibrationService.light();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TravelTrackerScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Itinerary Header & Days Carousel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Trip Itinerary', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                            if (relId != null)
                              GestureDetector(
                                onTap: () {
                                  VibrationService.light();
                                  _showAddActivityModal(relId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.pinkSoft,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add Activity',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _days.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final isSelected = _selectedDayIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  VibrationService.light();
                                  setState(() => _selectedDayIndex = index);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _days[index],
                                    style: AppTextStyles.heading.copyWith(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Real Day Activities Timeline
                        if (relId == null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                                      Text('Connect to plan your trip', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('Pair your partner to sync itineraries and activities together!', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          StreamBuilder<QuerySnapshot>(
                            stream: _cloudService.streamItinerary(relId),
                            builder: (context, itinerarySnapshot) {
                              final docs = itinerarySnapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    border: Border.all(color: AppColors.border, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const MascotHeart(color: MascotColor.pink, size: 48),
                                        const SizedBox(height: 8),
                                        Text('No activities added yet', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text('Tap "Add Activity" to plan your days together', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final title = data['title']?.toString() ?? 'Activity';
                                  final desc = data['description']?.toString() ?? widget.destination;
                                  final slot = data['slot']?.toString() ?? '10:00 AM';
                                  final cat = data['category']?.toString() ?? 'Sightseeing';

                                  return Dismissible(
                                    key: Key(doc.id),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) {
                                      VibrationService.light();
                                      _cloudService.deleteItineraryItem(relId, doc.id);
                                    },
                                    background: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(AppRadius.card),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                                    ),
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
                                              color: AppColors.pinkSoft,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      slot,
                                                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text('• $cat', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  title,
                                                  style: AppTextStyles.heading.copyWith(fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  desc,
                                                  style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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
      },
    );
  }

  Widget _featureNavButton({
    required String title,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.heading.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
