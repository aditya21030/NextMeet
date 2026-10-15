import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../core/data/trip_data.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with TickerProviderStateMixin {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  String? get _currentUid => _cloudService.currentUid;
  
  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'Adventure': return const Color(0xFFF97316);
      case 'Romantic': return const Color(0xFFF43F5E);
      case 'Chill': return const Color(0xFF0EA5E9);
      case 'Foodie': return const Color(0xFFEAB308);
      default: return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Sightseeing': return Icons.camera_alt_rounded;
      case 'Stay': return Icons.hotel_rounded;
      case 'Travel': return Icons.directions_bus_rounded;
      case 'Food': return Icons.restaurant_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        if (!relSnapshot.hasData || relSnapshot.data?.id == null) {
          return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
        }

        final rel = relSnapshot.data!;
        final relId = rel.id!;
        final accent = _getMoodColor(rel.tripMood);
        final hasTrip = rel.tripDestination != null && rel.tripDestination!.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              _buildBackdrop(rel.tripMood),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(color: AppColors.background),
                      title: Text(
                        hasTrip ? rel.tripDestination!.toUpperCase() : 'PLANNER',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 16, 
                          color: AppColors.textPrimary, 
                          letterSpacing: 4, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasTrip) _buildEmptyState(relId, rel, accent)
                          else ...[
                            _buildVoyageHeader(rel, accent),
                            const SizedBox(height: 32),
                            _buildFinancialPulse(relId, rel, accent),
                            const SizedBox(height: 32),
                            if (rel.isPlus) _buildDiscoveryReel(relId, rel.tripDestination!, accent),
                            const SizedBox(height: 32),
                            _buildJourneySection(relId, rel, accent),
                            const SizedBox(height: 32),
                            _buildExpenseHistory(relId, accent),
                            const SizedBox(height: 32),
                            _buildPackingList(relId, accent),
                          ],
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (hasTrip) _buildActionPill(relId, rel, accent),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBackdrop(String? mood) {
    return const SizedBox.shrink(); // Backdrop removed for cleaner light UI
  }

  Widget _buildEmptyState(String relId, RelationshipModel rel, Color accent) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.explore_rounded, color: AppColors.primary, size: 80),
            const SizedBox(height: 24),
            Text('No Voyage Set', style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary, fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              'Your shared sanctuary needs a destination ✨',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            PrimaryButton(text: 'START PLANNING 🚀', color: accent, onPressed: () => _manageTrip(relId, rel)),
          ],
        ),
      ),
    );
  }

  Widget _buildVoyageHeader(RelationshipModel rel, Color accent) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = rel.tripDate != null ? DateTime(rel.tripDate!.year, rel.tripDate!.month, rel.tripDate!.day) : today;
    final end = rel.tripEndDate != null ? DateTime(rel.tripEndDate!.year, rel.tripEndDate!.month, rel.tripEndDate!.day) : target;
    
    final daysTo = target.difference(today).inDays;
    final isOngoing = today.isAfter(target.subtract(const Duration(seconds: 1))) && today.isBefore(end.add(const Duration(days: 1)));
    
    String rangeText = 'Set dates ✨';
    if (rel.tripDate != null) {
      final df = DateFormat('MMM d');
      rangeText = df.format(rel.tripDate!);
      if (rel.tripEndDate != null) {
        if (rel.tripDate!.month == rel.tripEndDate!.month) {
          rangeText += ' - ${rel.tripEndDate!.day}';
        } else {
          rangeText += ' - ${df.format(rel.tripEndDate!)}';
        }
      }
    }

    return FadeInDown(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOngoing ? '0' : '${daysTo < 0 ? 0 : daysTo}',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 38, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1.5),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(isOngoing ? 'ONGOING' : 'DAYS TO GO', style: TextStyle(color: AppColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 9, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      rangeText.toUpperCase(),
                      style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(rel.tripStory ?? 'Our journey together...', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFinancialPulse(String relId, RelationshipModel rel, Color accent) {
    return StreamBuilder<QuerySnapshot>(
      stream: _cloudService.streamExpenses(relId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        double spent = 0;
        for (var d in docs) {
          spent += (d['amount'] as num).toDouble();
        }
        
        final total = rel.tripBudget ?? 1;
        final remaining = total - spent;
        final progress = spent / total;

        return FadeInLeft(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60, height: 60,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REMAINING FUNDS', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,###').format(remaining)}',
                        style: AppTextStyles.h2.copyWith(fontSize: 26, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).toInt()}% UTILIZED', style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildJourneySection(String relId, RelationshipModel rel, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('JOURNEY PATH', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
            if (rel.isPlus)
              IconButton(
                icon: Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
                onPressed: () => _showSuggestionsModal(relId, rel.tripDestination!, accent, rel),
              ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: _cloudService.streamItinerary(relId),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(child: Text('Empty trail. Start your story.', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)));
            }
            final sorted = docs.toList()..sort((a,b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              itemBuilder: (context, index) => _buildPathNode(relId, sorted[index], index == sorted.length - 1, accent),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPathNode(String relId, DocumentSnapshot doc, bool isLast, Color accent) {
    final data = doc.data() as Map<String, dynamic>;
    final cat = data['category'] as String?;
    final docId = doc.id;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8)],
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.divider)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                   VibrationService.heavy();
                   _cloudService.deleteItineraryItem(relId, docId);
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _getCategoryBadge(cat, accent),
                          Text(DateFormat('h:mm a').format((data['date'] as Timestamp).toDate()), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(data['title'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      if (data['notes'] != null && data['notes'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(data['notes'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                        ),
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryBadge(String? cat, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Text(cat?.toUpperCase() ?? 'PLAN', style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildActionPill(String relId, RelationshipModel rel, Color accent) {
    return Positioned(
      bottom: 24, left: 24, right: 24,
      child: ZoomIn(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: AppColors.buttonShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallAction('ADD PLAN', Icons.add_rounded, accent, () => _showAddItineraryModal(relId, accent)),
              _buildSmallAction('EXPENSE', Icons.account_balance_wallet_rounded, AppColors.textSecondary, () => _showExpensesModal(relId, accent)),
              _buildSmallAction('EDIT', Icons.edit_note_rounded, AppColors.textSecondary, () => _manageTrip(relId, rel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        VibrationService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color == AppColors.textSecondary ? AppColors.background : color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color == AppColors.textSecondary ? AppColors.textPrimary : Colors.white),
            const SizedBox(width: 6),
            Text(
              label, 
              style: TextStyle(
                color: color == AppColors.textSecondary ? AppColors.textPrimary : Colors.white, 
                fontSize: 9, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 0.5
              )
            ),
          ],
        ),
      ),
    );
  }

  void _manageTrip(String relId, RelationshipModel rel) {
    final destController = TextEditingController(text: rel.tripDestination);
    final budgetController = TextEditingController(text: rel.tripBudget?.toString());
      // ignore: unused_local_variable
    final storyController = TextEditingController(text: rel.tripStory);
    String selectedMood = rel.tripMood ?? 'Chill';
    final Color accent = _getMoodColor(selectedMood);
    
    DateTimeRange? selectedRange = (rel.tripDate != null && rel.tripEndDate != null) 
        ? DateTimeRange(start: rel.tripDate!, end: rel.tripEndDate!) 
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('PLAN VOYAGE', style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary, fontSize: 16, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  const Text('QUICK SELECT', style: TextStyle(color: AppColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: TripData.getCities().map((city) => GestureDetector(
                        onTap: () => setModalState(() => destController.text = city),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: destController.text == city ? accent.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: destController.text == city ? accent : AppColors.divider.withValues(alpha: 0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Text(city, style: TextStyle(color: destController.text == city ? accent : AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: destController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: AppInputs.premiumInput('Destination', hint: 'Where to?'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialDateRange: selectedRange,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: accent)),
                          child: child!,
                        ),
                      );
                      if (range != null) setModalState(() => selectedRange = range);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: accent, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            selectedRange == null 
                                ? 'Set Voyage Dates' 
                                : '${DateFormat('MMM d').format(selectedRange!.start)} - ${DateFormat('MMM d').format(selectedRange!.end)}',
                            style: TextStyle(color: selectedRange == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: AppInputs.premiumInput('Budget', hint: 'Amount'),
                  ),
                  const SizedBox(height: 16),
                  const Text('TRIP MOOD', style: TextStyle(color: AppColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Adventure', 'Romantic', 'Chill', 'Foodie'].map((mood) {
                      final isSelected = selectedMood == mood;
                      return ChoiceChip(
                        label: Text(mood, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 9.5)),
                        selected: isSelected,
                        onSelected: (val) => setModalState(() => selectedMood = mood),
                        selectedColor: _getMoodColor(mood),
                        backgroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'SET SAIL ⚓',
                    color: _getMoodColor(selectedMood),
                    onPressed: () async {
                      await _cloudService.updateTripDetails(relId, 
                        dest: destController.text,
                        date: selectedRange?.start,
                        endDate: selectedRange?.end,
                        budget: double.tryParse(budgetController.text) ?? 0.0,
                        mood: selectedMood,
      // ignore: use_build_context_synchronously
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddItineraryModal(String relId, Color accent) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedTime = DateTime.now();
    String selectedCategory = 'Sightseeing';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 32, right: 32, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADD TO PATH', style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary, fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputs.premiumInput('Activity Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputs.premiumInput('Quick Notes'),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: ['Sightseeing', 'Stay', 'Travel', 'Food'].map((cat) {
                  return ChoiceChip(
                    label: Text(cat, style: TextStyle(color: selectedCategory == cat ? Colors.white : AppColors.textSecondary, fontSize: 10)),
                    selected: selectedCategory == cat,
                    onSelected: (val) {
                      if (val) setModalState(() => selectedCategory = cat);
                    },
                    selectedColor: accent,
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'ADD TO JOURNEY ✍️',
                color: accent,
                onPressed: () async {
      // ignore: use_build_context_synchronously
                  if (titleController.text.isEmpty) return;
                  await _cloudService.addItineraryItem(relId, titleController.text, notesController.text, selectedTime, category: selectedCategory);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpensesModal(String relId, Color accent, {DocumentSnapshot? existingDoc}) {
    final amtController = TextEditingController(text: existingDoc != null ? (existingDoc['amount'] as num).toString() : '');
    final descController = TextEditingController(text: existingDoc != null ? existingDoc['title'] : '');
    String selectedCategory = existingDoc != null ? existingDoc['category'] : 'Food';
    String paidBy = existingDoc != null ? existingDoc['paidBy'] : _currentUid!;
    final isEditing = existingDoc != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 32, right: 32, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'EDIT EXPENSE' : 'LOG EXPENSE', style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary, fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 24),
              TextField(
                controller: amtController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputs.premiumInput('Amount'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputs.premiumInput('Description'),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: isEditing ? 'UPDATE RECORD ✨' : 'SAVE EXPENSE 💸',
                color: accent,
                onPressed: () async {
                  final amt = double.tryParse(amtController.text) ?? 0;
                  if (amt == 0) return;
                  if (isEditing) {
                    await _cloudService.updateTripExpense(relId, existingDoc.id, descController.text, amt, selectedCategory);
      // ignore: use_build_context_synchronously
                  } else {
                    await _cloudService.addTripExpense(relId, descController.text, amt, selectedCategory, paidBy: paidBy);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuggestionsModal(String relId, String city, Color accent, RelationshipModel rel) {
    final suggestions = TripData.getSuggestionsForCity(city);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SMART PICKS', style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary, fontSize: 18, letterSpacing: 2)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSugCat('PLACES', suggestions['places']!, accent, (s) {
                     _cloudService.addItineraryItem(relId, s.title, 'Top pick', DateTime.now(), category: 'Sightseeing');
                     Navigator.pop(context);
                  }),
                  _buildSugCat('STAYS', suggestions['hotels']!, accent, (s) {
                     _cloudService.addItineraryItem(relId, s.title, 'Top Stay', DateTime.now(), category: 'Stay');
                     Navigator.pop(context);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryReel(String relId, String city, Color accent) {
    final suggestions = TripData.getSuggestionsForCity(city);
    final places = suggestions['places'] ?? [];
    final stays = suggestions['hotels'] ?? [];
    
    // Combine for a richer reel
    final allSuggestions = [...places, ...stays];
    
    if (allSuggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                const Text('DISCOVERY REEL', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('PLUS', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allSuggestions.length,
            itemBuilder: (context, index) {
              final s = allSuggestions[index];
              return _buildDiscoveryCard(relId, s, accent);
            },
          ),
        ),
        const SizedBox(height: 32),
        _buildPerfectDayPlan(relId, city, accent),
        const SizedBox(height: 32),
        _buildPremiumTipCard(city, accent),
      ],
    );
  }

  Widget _buildPerfectDayPlan(String relId, String city, Color accent) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THE PERFECT DAY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text('CURATED BY AI', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  VibrationService.success();
                  final suggestions = TripData.getSuggestionsForCity(city);
                  final places = suggestions['places'] ?? [];
                  final stays = suggestions['hotels'] ?? [];
                  final food = suggestions['food'] ?? [];
                  
                  if (places.isNotEmpty && stays.isNotEmpty) {
                    final pList = List.from(places)..shuffle();
                    final sList = List.from(stays)..shuffle();
                    final fList = food.isNotEmpty ? (List.from(food)..shuffle()) : pList;

                    final morning = pList[0];
                    final lunch = fList[0];
                    final stay = sList[0];

                    // Helper to estimate amount from price level
                    double getAmount(int lvl) => lvl == 1 ? 500 : lvl == 2 ? 1500 : 6000;

                    // Plan Itinerary
                    await _cloudService.addItineraryItem(relId, morning.title, 'Morning: ${morning.description}', DateTime.now().add(const Duration(hours: 9)), category: 'Sightseeing');
                    await _cloudService.addItineraryItem(relId, lunch.title, 'Lunch: ${lunch.description}', DateTime.now().add(const Duration(hours: 13)), category: 'Food');
                    await _cloudService.addItineraryItem(relId, stay.title, 'Stay: ${stay.description}', DateTime.now().add(const Duration(hours: 20)), category: 'Stay');

                    // Auto-log Expenses as requested
      // ignore: use_build_context_synchronously
                    await _cloudService.addTripExpense(relId, 'Morning: ${morning.title}', getAmount(morning.priceLevel), 'Sightseeing');
                    await _cloudService.addTripExpense(relId, 'Lunch: ${lunch.title}', getAmount(lunch.priceLevel), 'Food');
                    await _cloudService.addTripExpense(relId, 'Booking: ${stay.title}', getAmount(stay.priceLevel), 'Stay');

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✨ Journey & Expenses synchronized!'), 
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text('PLAN ALL', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text('Morning Walk • Cozy Lunch • Sunset Views', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(String relId, TripSuggestion s, Color accent) {
    return GestureDetector(
      onTap: () {
        VibrationService.success();
        _cloudService.addItineraryItem(relId, s.title, s.description, DateTime.now(), category: 'Sightseeing');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Added ${s.title} to Journey! ✨'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: s.dynamicImageUrl,
                fit: BoxFit.cover,
                width: 180, height: 220,
                fadeInDuration: const Duration(milliseconds: 500),
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.divider.withValues(alpha: 0.1), AppColors.divider.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.1), accent.withValues(alpha: 0.05)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_rounded, color: accent.withValues(alpha: 0.3), size: 32),
                      const SizedBox(height: 8),
                      Text('Image unavailable', style: TextStyle(color: accent.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                ),
              ),
              Positioned(
                bottom: 20, left: 16, right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.vibe, style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(s.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Positioned(
                top: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.add_rounded, color: accent, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTipCard(String city, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accent.withValues(alpha: 0.1)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.tips_and_updates_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRO VOYAGE TIP', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(
                  'Best time to visit ${city.toUpperCase()} landmarks is typically early morning to avoid crowds and catch the best golden-hour light for your photos! 📸',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseHistory(String relId, Color accent) {
    return StreamBuilder<QuerySnapshot>(
      stream: _cloudService.streamExpenses(relId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VOYAGE LEDGER', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 16),
            ...docs.take(10).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  _cloudService.deleteTripExpense(relId, doc.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense cleared 🧹')));
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                child: GestureDetector(
                  onTap: () => _showExpensesModal(relId, accent, existingDoc: doc),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(_getCategoryIcon(data['category']), color: accent, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? 'Expense', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('Paid by ${data['paidBy'] == _currentUid ? 'Me' : 'Partner'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                        Text('₹${(data['amount'] as num).toInt()}', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPackingList(String relId, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('VOYAGE ESSENTIALS', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: accent, size: 20),
              onPressed: () => _showPackingModal(relId, accent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _cloudService.streamPackingItems(relId),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider)),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.luggage_outlined, size: 40, color: accent.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No items packed yet. Ready to go?', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isDone = data['isCompleted'] ?? false;
                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _cloudService.deletePackingItem(relId, doc.id),
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.grey.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDone ? [] : AppColors.cardShadow,
                      border: Border.all(color: isDone ? Colors.transparent : AppColors.divider.withValues(alpha: 0.5)),
                    ),
                    child: CheckboxListTile(
                      value: isDone,
                      onChanged: (val) => _cloudService.togglePackingItem(relId, doc.id, val ?? false),
                      title: Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: data['assignedTo'] != null 
                        ? Text('For ${data['assignedTo'] == _currentUid ? 'Me' : 'Partner'}', style: TextStyle(fontSize: 10, color: accent)) 
                        : null,
                      secondary: Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: isDone ? Colors.green : accent),
                      activeColor: Colors.green,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showPackingModal(String relId, Color accent) {
    final controller = TextEditingController();
    String assignedTo = _currentUid!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 32, right: 32, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PACK ESSENTIALS', style: AppTextStyles.h2.copyWith(fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputs.premiumInput('Item Name', hint: 'e.g. Passports, Camera...'),
              ),
              const SizedBox(height: 20),
              const Text('WHO CARRIES IT?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                   ChoiceChip(
                    label: const Text('ME'),
                    selected: assignedTo == _currentUid,
                    onSelected: (val) => setModalState(() => assignedTo = _currentUid!),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('PARTNER'),
                    selected: assignedTo != _currentUid,
                    onSelected: (val) => setModalState(() => assignedTo = 'partner'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'ADD TO LIST 📦',
                color: accent,
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    _cloudService.addPackingItem(relId, controller.text, assignedTo: assignedTo == 'partner' ? null : _currentUid);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSugCat(String title, List<TripSuggestion> items, Color accent, Function(TripSuggestion) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) => ActionChip(
            label: Text(item.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
            backgroundColor: const Color(0xFFF1F5F9),
            onPressed: () => onSelect(item),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
