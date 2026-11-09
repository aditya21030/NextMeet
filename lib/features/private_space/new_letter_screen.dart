import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Write Love Letter Screen with Stationery & Wax Seal
/// Strictly following NextMeet Redesign.pdf (Page 63)
class NewLetterScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;

  const NewLetterScreen({super.key, this.relId, this.partnerName});

  @override
  State<NewLetterScreen> createState() => _NewLetterScreenState();
}

class _NewLetterScreenState extends State<NewLetterScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final TextEditingController _titleController = TextEditingController(text: 'To my soulmate ✨');
  final TextEditingController _bodyController = TextEditingController();
  int _selectedSealIndex = 0;
  DateTime? _sealedUntilDate;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _seals = [
    {'name': 'Blush Rose', 'color': AppColors.primary, 'emoji': '❤️'},
    {'name': 'Imperial Violet', 'color': AppColors.partner, 'emoji': '💜'},
    {'name': 'Golden Sun', 'color': AppColors.butterText, 'emoji': '✨'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickSealedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
      setState(() => _sealedUntilDate = picked);
    }
  }

  Future<void> _sendLetter() async {
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your heartfelt letter first')),
      );
      return;
    }
    VibrationService.heavy();
    setState(() => _isSaving = true);

    try {
      String? targetRelId = widget.relId;
      if (targetRelId == null) {
        final rel = await _cloudService
            .streamRelationship()
            .first
            .timeout(const Duration(seconds: 5));
        targetRelId = rel?.id;
      }

      if (targetRelId != null) {
        final seal = _seals[_selectedSealIndex]['name'] as String;
        await _cloudService.addLoveLetter(
          targetRelId,
          _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : 'To my soulmate ✨',
          _bodyController.text.trim(),
          sealColor: seal,
          unlockDate: _sealedUntilDate,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_sealedUntilDate == null
              ? 'Sealed and delivered to ${widget.partnerName ?? 'your love'}! 💌'
              : 'Time-locked letter sealed until ${DateFormat('dd MMM yyyy').format(_sealedUntilDate!)}! 🔒'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deliver letter: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5), // Warm stationery parchment
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
                      'New Love Letter',
                      style: AppTextStyles.title2.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : _sendLetter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _isSaving ? '...' : 'Seal & Send',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Letter Parchment (Page 63)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stationery Paper Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        border: Border.all(color: const Color(0xFFE8D7CA), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Letter Title
                          TextField(
                            controller: _titleController,
                            style: AppTextStyles.title1.copyWith(fontSize: 20, color: AppColors.ink),
                            decoration: const InputDecoration(
                              hintText: 'Letter title...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Divider(height: 24, color: Color(0xFFE8D7CA), thickness: 1),

                          // Letter Body
                          TextField(
                            controller: _bodyController,
                            maxLines: 8,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 15,
                              height: 1.6,
                              color: AppColors.ink,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Pour your heart out here...\n\nEvery sweet thought, quiet moment, or missing piece of distance.',
                              hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Sign-off
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '— Always yours ❤️',
                              style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Wax Seal Color Picker (Page 63)
                    Text('Choose Wax Seal', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: _seals.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final seal = entry.value;
                        final isSelected = _selectedSealIndex == idx;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              VibrationService.light();
                              setState(() => _selectedSealIndex = idx);
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: idx < _seals.length - 1 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(
                                  color: isSelected ? seal['color'] as Color : AppColors.border,
                                  width: isSelected ? 2.0 : 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: seal['color'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(seal['emoji'] as String, style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    seal['name'] as String,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
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

                    // Delivery / Time Lock Scheduler
                    Text('Delivery Timing', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                    const SizedBox(height: 10),

                    Container(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _sealedUntilDate == null ? 'Deliver immediately' : 'Time-locked letter',
                                    style: AppTextStyles.heading.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _sealedUntilDate == null
                                        ? '${widget.partnerName ?? "Partner"} can open as soon as sent'
                                        : 'Sealed until ${DateFormat('dd MMM yyyy').format(_sealedUntilDate!)}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _pickSealedDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.pinkSoft,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    _sealedUntilDate == null ? 'Set Date 🔒' : 'Change',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_sealedUntilDate != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => setState(() => _sealedUntilDate = null),
                                child: Text('Clear lock (send now)', style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Primary Button
                    PrimaryButton(
                      text: 'Seal & Send Letter 💌',
                      isLoading: _isSaving,
                      onPressed: _sendLetter,
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
