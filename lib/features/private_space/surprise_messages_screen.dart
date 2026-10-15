import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';

class SurpriseMessagesScreen extends StatefulWidget {
  const SurpriseMessagesScreen({super.key});

  @override
  State<SurpriseMessagesScreen> createState() => _SurpriseMessagesScreenState();
}

class _SurpriseMessagesScreenState extends State<SurpriseMessagesScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context, StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setModalState(() => _selectedDate = picked);
    }
  }

  void _createSurprise(String relId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    _selectedDate = null;
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
              Text('Create a Surprise 🎁', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: titleController,
                decoration: AppInputs.premiumInput('What\'s the surprise?'),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: contentController,
                maxLines: 2,
                decoration: AppInputs.premiumInput('The secret message...'),
              ),
              const SizedBox(height: AppSpacing.l),
              Text('Release Date', style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, setModalState),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null 
                          ? 'Select a future date' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', 
                        style: AppTextStyles.bodyM.copyWith(color: _selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'SET SURPRISE',
                onPressed: () async {
                  if (titleController.text.isNotEmpty && _selectedDate != null) {
                    await _cloudService.addSurprise(
                      relId, 
                      titleController.text, 
                      contentController.text, 
                      _selectedDate!, 
                      'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&h=400&fit=crop',
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
            title: Text('Surprise Messages', style: AppTextStyles.h3),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: relId == null 
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
              stream: _cloudService.streamSurprises(relId),
              builder: (context, snapshot) {
                final surprises = snapshot.data?.docs ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UPCOMING SURPRISES', style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Text('Create and schedule heartfelt messages for your loved ones.', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      if (surprises.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 100),
                              Icon(Icons.card_giftcard_rounded, size: 64, color: AppColors.divider),
                              const SizedBox(height: 16),
                              Text('No surprises scheduled yet.', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: surprises.length,
                          itemBuilder: (context, index) {
                            final doc = surprises[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 100),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                                child: GestureDetector(
                                  onLongPress: () => _deleteSurprise(relId, doc.id),
                                  child: _buildSurpriseCard(doc),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: DottedContainer(
                          child: InkWell(
                            onTap: () => _createSurprise(relId),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.l),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Create a new surprise...', style: AppTextStyles.bodyM.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                                        Text('Tap the plus button to start', style: AppTextStyles.bodyS.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.softShadow),
                                    child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
        );
      }
    );
  }

  Widget _buildSurpriseCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final unlockTimestamp = data['unlockDate'] as Timestamp?;
    final unlockDate = unlockTimestamp?.toDate() ?? DateTime.now();
    final bool isLocked = unlockDate.isAfter(DateTime.now());
    
    String lockText = 'Tap to reveal';
    if (isLocked) {
      lockText = 'Locked until ${unlockDate.day}/${unlockDate.month}';
    }

    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          VibrationService.success();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(data['title'] ?? 'Surprise! 🎁'),
              content: Text(data['content'] ?? ''),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          );
        } else {
          VibrationService.error();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This surprise is still locked! 🔒')));
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? '', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    isLocked ? 'Waiting for the perfect moment...' : (data['content'] ?? ''), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyS.copyWith(fontSize: 11, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLocked ? const Color(0x0D9E9E9E) : const Color(0x1FFF5E7D), 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isLocked ? Colors.transparent : const Color(0x1AFF5E7D)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded, 
                          size: 12, 
                          color: isLocked ? AppColors.textSecondary : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lockText, 
                          style: TextStyle(
                            color: isLocked ? AppColors.textSecondary : AppColors.primary, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Image.network(
                    data['imageUrl'] ?? 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&h=400&fit=crop', 
                    width: 80, height: 80, fit: BoxFit.cover,
                  ),
                ),
                if (isLocked)
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSurprise(String relId, String surpriseId) async {
    VibrationService.medium();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Surprise?'),
        content: const Text('Are you sure you want to permanently delete this surprise?'),
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
      await _cloudService.deleteSurprise(relId, surpriseId);
      VibrationService.success();
    }
  }
}

class DottedContainer extends StatelessWidget {
  final Widget child;
  const DottedContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1), 
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
