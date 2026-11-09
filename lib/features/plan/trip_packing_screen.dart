import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Trip Packing Checklist Screen
/// Strictly following NextMeet Redesign.pdf (Page 43)
class TripPackingScreen extends StatefulWidget {
  final String? relId;
  const TripPackingScreen({super.key, this.relId});

  @override
  State<TripPackingScreen> createState() => _TripPackingScreenState();
}

class _TripPackingScreenState extends State<TripPackingScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final TextEditingController _addItemController = TextEditingController();
  int _selectedFilterIndex = 0;

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  void _addItem(String relId, String ownerLabel) async {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;
    VibrationService.light();
    _addItemController.clear();
    try {
      await _cloudService.addPackingItem(
        relId,
        text,
        assignedTo: ownerLabel,
        category: 'Essentials',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final rel = relSnapshot.data;
        final relId = widget.relId ?? rel?.id;
        final partnerName = rel?.getPartnerName(currentUid) ?? 'Partner';
        final filters = ['All', 'Mine', "$partnerName's", 'Shared'];

        if (relId == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Packing Checklist', style: AppTextStyles.title2.copyWith(fontSize: 18)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MascotHeart(color: MascotColor.pink, size: 54),
                    const SizedBox(height: 14),
                    Text('No active couple trip yet', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      'Connect with your partner to share packing lists and checklists together!',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamPackingItems(relId),
              builder: (context, packingSnapshot) {
                final docs = packingSnapshot.data?.docs ?? [];
                final currentFilter = filters[_selectedFilterIndex];

                final filteredDocs = docs.where((doc) {
                  if (currentFilter == 'All') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final assigned = data['assignedTo']?.toString() ?? 'Shared';
                  return assigned == currentFilter;
                }).toList();

                final packedCount = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isCompleted'] == true;
                }).length;

                final progress = docs.isEmpty ? 0.0 : (packedCount / docs.length).clamp(0.0, 1.0);

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
                              'Packing Checklist',
                              style: AppTextStyles.title2.copyWith(fontSize: 18),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.mint, width: 1),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}% ready',
                              style: AppTextStyles.caption.copyWith(color: AppColors.mintText, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Progress Banner Card (Page 43)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$packedCount of ${docs.length} items packed',
                                  style: AppTextStyles.heading.copyWith(fontSize: 14),
                                ),
                                Text(
                                  '${docs.length - packedCount} remaining',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: AppColors.pinkSoft,
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filter Tabs Row
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                        itemCount: filters.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFilterIndex == index;
                          return GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _selectedFilterIndex = index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                filters[index],
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

                    const SizedBox(height: 12),

                    // Checklist Items List
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const MascotHeart(color: MascotColor.mint, size: 56),
                                  const SizedBox(height: 12),
                                  Text('No packing items in this tab', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('Add what you need for the trip below', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 4),
                              itemCount: filteredDocs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final title = data['title']?.toString() ?? 'Item';
                                final isPacked = data['isCompleted'] == true;
                                final owner = data['assignedTo']?.toString() ?? 'Shared';

                                return Dismissible(
                                  key: Key(doc.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) {
                                    VibrationService.light();
                                    _cloudService.deletePackingItem(relId, doc.id);
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
                                  child: GestureDetector(
                                    onTap: () {
                                      VibrationService.light();
                                      _cloudService.togglePackingItem(relId, doc.id, !isPacked);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppRadius.card),
                                        border: Border.all(color: AppColors.border, width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isPacked ? AppColors.primary : Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isPacked ? AppColors.primary : AppColors.border,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isPacked
                                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: AppTextStyles.body.copyWith(
                                                decoration: isPacked ? TextDecoration.lineThrough : null,
                                                color: isPacked ? AppColors.muted : AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: owner == 'Mine'
                                                  ? AppColors.pinkSoft
                                                  : (owner.contains(partnerName) ? AppColors.partnerSoft : AppColors.mintSoft),
                                              borderRadius: BorderRadius.circular(AppRadius.pill),
                                            ),
                                            child: Text(
                                              owner,
                                              style: AppTextStyles.caption.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: owner == 'Mine'
                                                    ? AppColors.primary
                                                    : (owner.contains(partnerName) ? AppColors.partnerText : AppColors.mintText),
                                              ),
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

                    // Bottom Add Item Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppRadius.input),
                                border: Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: TextField(
                                controller: _addItemController,
                                style: AppTextStyles.body.copyWith(color: AppColors.ink),
                                decoration: const InputDecoration(
                                  hintText: 'Add an item to pack...',
                                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addItem(
                                  relId,
                                  filters[_selectedFilterIndex] == 'All' ? 'Shared' : filters[_selectedFilterIndex],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _addItem(
                              relId,
                              filters[_selectedFilterIndex] == 'All' ? 'Shared' : filters[_selectedFilterIndex],
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
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
