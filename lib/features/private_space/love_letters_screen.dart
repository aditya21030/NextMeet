import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';
import 'letter_detail_screen.dart';

class LoveLettersScreen extends StatefulWidget {
  const LoveLettersScreen({super.key});

  @override
  State<LoveLettersScreen> createState() => _LoveLettersScreenState();
}

class _LoveLettersScreenState extends State<LoveLettersScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  void _addLetter(String relId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    VibrationService.medium();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write a Love Letter 📖', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: titleController,
              decoration: AppInputs.premiumInput('Title (e.g. To my soulmate)'),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: AppInputs.premiumInput('Pour your heart out...'),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'SEND LETTER',
              onPressed: () async {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  await _cloudService.addLoveLetter(relId, titleController.text, contentController.text);
                  VibrationService.success();
      // ignore: use_build_context_synchronously
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, relSnapshot) {
        final relId = relSnapshot.data?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context), 
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            ),
            title: Text('Love Letters ❤️', style: AppTextStyles.h3),
            centerTitle: true,
            actions: [
              IconButton(onPressed: () => VibrationService.light(), icon: const Icon(Icons.search, color: AppColors.textPrimary, size: 20)),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: relId == null 
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamLoveLetters(relId),
              builder: (context, snapshot) {
                final letters = snapshot.data?.docs ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Letters', style: AppTextStyles.h2),
                            _buildCountBadge('${letters.length} Letters'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      if (letters.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 100),
                              Icon(Icons.edit_note_rounded, size: 64, color: AppColors.divider),
                              const SizedBox(height: 16),
                              Text('No letters yet. Start writing!', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: letters.length,
                          itemBuilder: (context, index) {
                            final doc = letters[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 100),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                                child: GestureDetector(
                                  onTap: () {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final bool isMine = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                                    final timestamp = data['timestamp'] as Timestamp?;
                                    String dateStr = timestamp != null ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}' : 'Recently';
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LetterDetailScreen(
                                          title: data['title'] ?? '',
                                          content: data['content'] ?? '',
                                          date: dateStr,
                                          sender: isMine ? 'You' : (data['senderName'] ?? 'Partner'),
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () => _deleteLetter(relId, doc.id),
                                  child: _buildLetterCard(doc),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          floatingActionButton: relId == null ? null : FloatingActionButton.extended(
            onPressed: () => _addLetter(relId),
            backgroundColor: AppColors.primary,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            label: const Text('Write Letter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        );
      }
    );
  }

  Widget _buildCountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1FFF5E7D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFF5E7D)),
      ),
      child: Text(
        text, 
        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildLetterCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final senderId = data['senderId'];
    final bool isMine = senderId == _currentUserId;
    
    String dateStr = 'Recently';
    if (timestamp != null) {
      final date = timestamp.toDate();
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: const Color(0x0DFF5252)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['title'] ?? '', style: AppTextStyles.h3),
              if (isMine) _buildBadge('SENT'),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            data['content'] ?? '',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(isMine ? 'You' : (data['senderName'] ?? 'Partner'), style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                ],
              ),
              Text(dateStr, style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(6),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Text(
        text, 
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Future<void> _deleteLetter(String relId, String letterId) async {
    VibrationService.medium();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Love Letter?'),
        content: const Text('Are you sure you want to permanently delete this letter?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cloudService.deleteLoveLetter(relId, letterId);
      VibrationService.success();
    }
  }
}
