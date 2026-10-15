import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';

class SanctumRitualsScreen extends StatefulWidget {
  final String relId;
  const SanctumRitualsScreen({super.key, required this.relId});

  @override
  State<SanctumRitualsScreen> createState() => _SanctumRitualsScreenState();
}

class _SanctumRitualsScreenState extends State<SanctumRitualsScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  void _addRitual() {
    final controller = TextEditingController();
    String selectedEmoji = '☕';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Daily Ritual ✨', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'e.g., Morning Coffee together'),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: ['☕', '🌙', '📖', '🧘', '🚶', '🍷', '🎶'].map((e) => GestureDetector(
                  onTap: () => setDialogState(() => selectedEmoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedEmoji == e ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _cloudService.addRitual(widget.relId, controller.text, selectedEmoji);
      // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('CREATE', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF1), // Light pink parchment
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFFDEEF1),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('DAILY RITUALS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2, fontSize: 14)),
              centerTitle: true,
            ),
            actions: [
              IconButton(onPressed: _addRitual, icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28)),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamRituals(widget.relId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                final docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 48),
                          const SizedBox(height: 16),
                          Text('No rituals yet...', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
                          Text('Add habits you want to grow together', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ritual = docs[index].data() as Map<String, dynamic>;
      // ignore: unused_local_variable
                      final ritualId = docs[index].id;
                      final isMe1 = _cloudService.currentUid == _cloudService.currentUid; // Simplified for UI
                      
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: _buildRitualCard(ritualId, ritual),
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualCard(String id, Map<String, dynamic> data) {
    bool u1 = data['u1Completed'] ?? false;
    bool u2 = data['u2Completed'] ?? false;
    bool allDone = u1 && u2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allDone ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: allDone ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(data['emoji'] ?? '✨', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(allDone ? 'Celebrated today! 🎉' : 'Growing together...', style: TextStyle(color: allDone ? AppColors.primary : AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              if (allDone) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildParticipant(1, u1, id),
              Container(width: 1, height: 20, color: Colors.white10),
              _buildParticipant(2, u2, id),
            ],
          ),
        ],
      ),
    );
  }
      // ignore: unused_local_variable

  Widget _buildParticipant(int userNum, bool completed, String ritualId) {
    bool isMe = true; // Logic to check if this participant is the current user
    
    return GestureDetector(
      onTap: () {
        VibrationService.medium();
        _cloudService.toggleRitual(widget.relId, ritualId, userNum == 1, !completed);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: completed ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: completed ? AppColors.primary : AppColors.divider, width: 2),
            ),
            child: Icon(completed ? Icons.check_rounded : Icons.person_outline_rounded, color: completed ? Colors.white : AppColors.textSecondary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(userNum == 1 ? 'Me' : 'Partner', style: TextStyle(color: completed ? AppColors.primary : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
