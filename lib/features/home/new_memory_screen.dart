import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/app_inputs.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Add New Memory Screen
/// Strictly following NextMeet Redesign.pdf (Page 24)
class NewMemoryScreen extends StatefulWidget {
  final String? relId;

  const NewMemoryScreen({super.key, this.relId});

  @override
  State<NewMemoryScreen> createState() => _NewMemoryScreenState();
}

class _NewMemoryScreenState extends State<NewMemoryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedEmotionIndex = 0;
  bool _saveToVault = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _emotions = [
    {'label': 'Happy', 'emoji': '😊', 'color': AppColors.mintText, 'bg': AppColors.mintSoft},
    {'label': 'Missed you', 'emoji': '🥺', 'color': AppColors.primary, 'bg': AppColors.pinkSoft},
    {'label': 'Adventure', 'emoji': '✈️', 'color': AppColors.partnerText, 'bg': AppColors.partnerSoft},
    {'label': 'Cosy', 'emoji': '☕', 'color': AppColors.butterText, 'bg': AppColors.butterSoft},
    {'label': 'Romantic', 'emoji': '❤️', 'color': AppColors.primary, 'bg': AppColors.pinkSoft},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        if (!mounted) return;
        setState(() => _imageFile = File(picked.path));
        VibrationService.light();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveMemory() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a memory title')),
      );
      return;
    }
    VibrationService.medium();
    setState(() => _isSaving = true);

    try {
      String? targetRelId = widget.relId;
      if (targetRelId == null) {
        final rel = await _cloudService.streamRelationship().first;
        targetRelId = rel?.id;
      }

      if (targetRelId != null) {
        await _cloudService.createMemory(
          targetRelId,
          title,
          _selectedDate,
          _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : 'Somewhere special',
          imageFile: _imageFile,
          emotion: _emotions[_selectedEmotionIndex]['label'] as String,
          isPrivate: _saveToVault,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory saved to your couple space! 💖✨'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving memory: $e')),
      );
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
                  Text('New Memory', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveMemory,
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

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Upload Area (Page 24)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_imageFile!, fit: BoxFit.cover),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text('Change', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.pinkSoft,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 26),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Add photo', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('Tap to select from your gallery', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title Input
                    Text('Title', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dinner by the beach',
                        prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date & Location Row
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
                              Text('Location', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _locationController,
                                style: AppTextStyles.body,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Goa, India',
                                  prefixIcon: Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Emotion Selector Chips (Page 24)
                    Text('How did it feel?', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _emotions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final emotion = entry.value;
                        final isSelected = _selectedEmotionIndex == idx;

                        return GestureDetector(
                          onTap: () {
                            VibrationService.light();
                            setState(() => _selectedEmotionIndex = idx);
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emotion['emoji'] as String, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  emotion['label'] as String,
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

                    // Save to Vault Toggle (Page 24)
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
                              color: AppColors.pinkSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Save to Vault instead', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  'Hidden from public timeline, PIN protected',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _saveToVault,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              VibrationService.light();
                              setState(() => _saveToVault = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    PrimaryButton(
                      text: 'Create Memory',
                      isLoading: _isSaving,
                      onPressed: _saveMemory,
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
