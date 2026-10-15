import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final String relationshipId;
  final String noteId;
  final String initialTitle;
  final String initialContent;
  final String category;

  const NoteDetailScreen({
    super.key,
    required this.relationshipId,
    required this.noteId,
    required this.initialTitle,
    required this.initialContent,
    required this.category,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
      // ignore: unused_field
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    VibrationService.medium();
    try {
      await FirebaseFirestore.instance
          .collection('relationships')
          .doc(widget.relationshipId)
          .collection('private_notes')
          .doc(widget.noteId)
          .update({
        'title': _titleController.text,
        'content': _contentController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      VibrationService.success();
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save ❌')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      // ignore: unused_local_variable
    // final bool isPersonal = widget.category == 'personal';
    const Color themeColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        actions: [
          if (!_isEditing)
             IconButton(
               onPressed: () => setState(() => _isEditing = true),
               icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 20),
             )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.category.toUpperCase(),
                  style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
            */
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: TextField(
                controller: _titleController,
                enabled: _isEditing,
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Title',
                ),
              ),
            ),
            const Divider(height: 48),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: TextField(
                controller: _contentController,
                enabled: _isEditing,
                maxLines: null,
                style: AppTextStyles.bodyM.copyWith(fontSize: 16, height: 1.6, color: Colors.black87),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
