import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../widgets/flat_components.dart';
import '../onboarding/welcome_screen.dart';

/// NextMeet Unpair Confirmation Bottom Sheet / Dialog
/// Strictly following NextMeet Redesign.pdf (Page 70)
class UnpairConfirmationModal extends StatefulWidget {
  final String partnerName;
  final String relationshipId;

  const UnpairConfirmationModal({
    super.key,
    required this.partnerName,
    required this.relationshipId,
  });

  static void show(
    BuildContext context, {
    required String partnerName,
    required String relationshipId,
  }) {
    VibrationService.heavy();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UnpairConfirmationModal(
        partnerName: partnerName,
        relationshipId: relationshipId,
      ),
    );
  }

  @override
  State<UnpairConfirmationModal> createState() =>
      _UnpairConfirmationModalState();
}

class _UnpairConfirmationModalState extends State<UnpairConfirmationModal> {
  bool _exportBackup = true;
  bool _isUnpairing = false;
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  Future<void> _handleUnpair() async {
    setState(() => _isUnpairing = true);
    VibrationService.heavy();

    try {
      await _cloudService.unpairRelationship(widget.relationshipId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUnpairing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error disconnecting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Broken Heart / Sad Mascots Graphic (Page 70)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.heart_broken_rounded,
                  color: AppColors.primary, size: 36),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Unpair from ${widget.partnerName}?',
            style: AppTextStyles.title1.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'This will disconnect your private space with ${widget.partnerName}. Both of you will lose real-time touch, heartbeat sync, and shared distance tracking.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Export Backup Checkbox Tile
          GestureDetector(
            onTap: () {
              VibrationService.light();
              setState(() => _exportBackup = !_exportBackup);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    _exportBackup
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _exportBackup ? AppColors.primary : AppColors.muted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Keep a safe local copy of all memories, letters & photos on your phone',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Keep Connected',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.ink,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _isUnpairing ? null : _handleUnpair,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: _isUnpairing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Yes, Unpair',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
