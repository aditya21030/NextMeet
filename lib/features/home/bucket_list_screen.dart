import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_inputs.dart';
import '../../widgets/primary_button.dart';

class BucketListScreen extends StatefulWidget {
  final String relationshipId;
  const BucketListScreen({super.key, required this.relationshipId});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final String _selectedCategory = 'Travel';
  final List<String> _categories = ['Travel', 'Home', 'Fun', 'Career'];

  void _addItem() {
    final TextEditingController controller = TextEditingController();
    String tempCat = _selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text('New Shared Goal ✨', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
                controller: controller,
                decoration: AppInputs.premiumInput('What do we want to do? ✨'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: tempCat == c,
                      onSelected: (val) => setModalState(() => tempCat = c),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('CANCEL', style: TextStyle(color: AppColors.textSecondary))
            ),
            SizedBox(
              width: 120,
              child: PrimaryButton(
                text: 'ADD',
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await _cloudService.addBucketItem(widget.relationshipId, controller.text, tempCat);
                    VibrationService.success();
      // ignore: use_build_context_synchronously
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
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
        title: Text('Shared Bucket List 🏆', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cloudService.streamBucketItems(widget.relationshipId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(child: Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2))),
                  const SizedBox(height: 16),
                  Text('No goals added yet!', style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Start building your future together ❤️', style: AppTextStyles.bodyS),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildGoalCard(doc.id, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('NEW GOAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGoalCard(String id, Map<String, dynamic> data) {
    bool isDone = data['isCompleted'] ?? false;
    String category = data['category'] ?? 'Travel';
    
    IconData icon;
    Color color;
    switch(category) {
      case 'Travel': icon = Icons.flight_takeoff_rounded; color = Colors.blue; break;
      case 'Home': icon = Icons.home_rounded; color = Colors.orange; break;
      case 'Fun': icon = Icons.celebration_rounded; color = Colors.pink; break;
      default: icon = Icons.trending_up_rounded; color = Colors.green;
    }

    return FadeInUp(
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '', 
                    style: AppTextStyles.bodyL.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  Text(category, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Checkbox(
              value: isDone,
              activeColor: AppColors.primary,
              onChanged: (val) {
                VibrationService.medium();
                _cloudService.toggleBucketItem(widget.relationshipId, id, val ?? false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              onPressed: () {
                _cloudService.deleteBucketItem(widget.relationshipId, id);
                VibrationService.medium();
              },
            ),
          ],
        ),
      ),
    );
  }
}
