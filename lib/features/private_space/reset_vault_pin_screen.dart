import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/flat_components.dart';
import 'create_vault_pin_screen.dart';

/// NextMeet 2-Person Vault PIN Reset Screen
/// Strictly following NextMeet Redesign.pdf (Page 60)
class ResetVaultPinScreen extends StatefulWidget {
  final String partnerName;
  final String? relId;
  const ResetVaultPinScreen({super.key, this.partnerName = 'Partner', this.relId});

  @override
  State<ResetVaultPinScreen> createState() => _ResetVaultPinScreenState();
}

class _ResetVaultPinScreenState extends State<ResetVaultPinScreen> {
  bool _requestSent = false;
  int _secondsRemaining = 900; // 15 mins
  Timer? _countdownTimer;
  StreamSubscription<RelationshipModel?>? _relSubscription;
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  void _checkInitialStatus() {
    _relSubscription = _cloudService.streamRelationship().listen((rel) {
      if (!mounted || rel == null) return;
      if (rel.pinResetRequestBy == _cloudService.currentUid && !rel.pinResetApproved) {
        if (!_requestSent) {
          setState(() => _requestSent = true);
          _startTimer();
        }
      } else if (rel.pinResetRequestBy == _cloudService.currentUid && rel.pinResetApproved) {
        _countdownTimer?.cancel();
        VibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.partnerName} approved your reset request! 🎉')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreateVaultPinScreen(relId: rel.id)),
        );
      } else if (_requestSent && rel.pinResetRequestBy == null) {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _requestSent = false;
            _secondsRemaining = 900;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _relSubscription?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining -= 1);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendResetRequest() async {
    VibrationService.medium();
    final targetRelId = widget.relId ?? _cloudService.cachedRelationship?.id;
    if (targetRelId != null && targetRelId.isNotEmpty) {
      await _cloudService.requestPinReset(targetRelId);
    }

    if (!mounted) return;
    setState(() {
      _requestSent = true;
    });

    _startTimer();
  }

  Future<void> _cancelResetRequest() async {
    VibrationService.light();
    final targetRelId = widget.relId ?? _cloudService.cachedRelationship?.id;
    if (targetRelId != null && targetRelId.isNotEmpty) {
      await _cloudService.cancelPinReset(targetRelId);
    }
    _countdownTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _requestSent = false;
      _secondsRemaining = 900;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top Bar
              Row(
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
                  Text('Reset PIN', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 24),

              // Shield Illustration (Page 60)
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.partnerSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.partner, width: 2),
                  ),
                  child: const Center(
                    child: MascotHeart(color: MascotColor.violet, size: 44),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                '2-Person PIN Reset',
                style: AppTextStyles.title1.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Because your Vault is private, resetting your PIN requires authorization from ${widget.partnerName}.',
                style: AppTextStyles.body.copyWith(color: AppColors.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Security Guarantee Card (Page 60)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.mint, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('100% Zero-Knowledge Privacy', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.partnerName} can only approve the reset. They can NEVER view your photos, love letters, or whispers.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('15-Minute Expiry Window', style: AppTextStyles.heading.copyWith(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'For safety, the authorization token automatically expires after 15 minutes.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Request state or Send Button
              if (_requestSent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.partnerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.partner, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.partner,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Waiting for ${widget.partnerName}'s approval...",
                            style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.partnerText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Time remaining: $timeStr', style: AppTextStyles.caption.copyWith(color: AppColors.partnerText)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _cancelResetRequest,
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                        label: const Text('Cancel Request', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                PrimaryButton(
                  text: 'Request Approval from ${widget.partnerName} 📲',
                  onPressed: _sendResetRequest,
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
