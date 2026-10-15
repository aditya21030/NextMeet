import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';
import 'note_detail_screen.dart';

// enum NoteCategory { all, shared, personal } // Removed categories

class PrivateNotesScreen extends StatefulWidget {
  const PrivateNotesScreen({super.key});

  @override
  State<PrivateNotesScreen> createState() => _PrivateNotesScreenState();
}

class _PrivateNotesScreenState extends State<PrivateNotesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  // NoteCategory _currentCategory = NoteCategory.all; // Removed category filter

  void _addNote(String relId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    // NoteCategory selectedCategory = NoteCategory.personal; // Defaulting to shared
    VibrationService.medium();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
              Text('Create Private Note 📝', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: titleController,
                decoration: AppInputs.premiumInput(
                  'Note Title',
                  hint: 'Summarize your thought...',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: AppInputs.premiumInput(
                  'Note Content',
                  hint: 'What\'s on your mind?',
                ),
              ),
              /*
              Text('Category', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCategoryChip(NoteCategory.personal, 'Personal', selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                  const SizedBox(width: 8),
                  _buildCategoryChip(NoteCategory.shared, 'Shared', selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                ],
              ),
              */
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'SAVE NOTE',
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await _cloudService.addPrivateNote(
                      relId, 
                      titleController.text, 
                      contentController.text, 
                      'shared', // Automatically shared
                    );
                    VibrationService.success();
      // ignore: use_build_context_synchronously
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused _buildCategoryChip

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
            title: Text('Private Notes', style: AppTextStyles.h3),
            centerTitle: true,
            actions: [
              if (relId != null)
                IconButton(
                  onPressed: () => _addNote(relId),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: relId == null 
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // _buildTabs(), // Removed tabs
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _cloudService.streamPrivateNotes(relId),
                      builder: (context, snapshot) {
                        final filteredNotes = snapshot.data?.docs ?? [];
                        // final filteredNotes = allNotes.where((doc) {
                        //   final data = doc.data() as Map<String, dynamic>;
                        //   if (_currentCategory == NoteCategory.all) return true;
                        //   return data['category'] == _currentCategory.name;
                        // }).toList();

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: _buildNotesGrid(relId, filteredNotes),
                        );
                      }
                    ),
                  ),
                ],
              ),
        );
      }
    );
  }

  /*
  Widget _buildTabs() {
    ...
  }
  */

  Widget _buildNotesGrid(String relId, List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Icon(Icons.note_alt_outlined, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text('No notes in this category', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Split into two columns
    List<QueryDocumentSnapshot> col1 = [];
    List<QueryDocumentSnapshot> col2 = [];
    for (int i = 0; i < docs.length; i++) {
      if (i % 2 == 0) {
        col1.add(docs[i]);
      } else {
        col2.add(docs[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: col1.asMap().entries.map((e) => FadeInUp(
              delay: Duration(milliseconds: e.key * 100),
              child: GestureDetector(
                onTap: () {
                  final data = e.value.data() as Map<String, dynamic>;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(
                        relationshipId: relId,
                        noteId: e.value.id,
                        initialTitle: data['title'] ?? '',
                        initialContent: data['content'] ?? '',
                        category: data['category'] ?? 'shared',
                      ),
                    ),
                  );
                },
                onLongPress: () => _confirmDeletion(relId, e.value.id, 'Note'),
                child: _buildNoteCard(e.value),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: col2.asMap().entries.map((e) => FadeInUp(
              delay: Duration(milliseconds: e.key * 100 + 50),
              child: GestureDetector(
                onTap: () {
                  final data = e.value.data() as Map<String, dynamic>;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(
                        relationshipId: relId,
                        noteId: e.value.id,
                        initialTitle: data['title'] ?? '',
                        initialContent: data['content'] ?? '',
                        category: data['category'] ?? 'shared',
                      ),
                    ),
                  );
                },
                onLongPress: () => _confirmDeletion(relId, e.value.id, 'Note'),
                child: _buildNoteCard(e.value),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Color bgColor = const Color(0xFFEEF5FF); // Consistent shared color
    final timestamp = data['timestamp'] as Timestamp?;
    
    String timeStr = 'Just now';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeStr = '${date.day}/${date.month}';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeStr, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['title'] ?? '', 
            style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.bold, height: 1.4, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((data['content'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              data['content'], 
              style: AppTextStyles.bodyS.copyWith(color: Colors.black54, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeletion(String relId, String noteId, String type) async {
    VibrationService.medium();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text('Are you sure you want to permanently delete this $type?'),
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
      await _cloudService.deletePrivateNote(relId, noteId);
      VibrationService.success();
    }
  }
}
