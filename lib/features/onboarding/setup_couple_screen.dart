import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/models/relationship_model.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'tell_us_about_you_screen.dart';
import 'join_couple_screen.dart';
import 'connection_success_screen.dart';

/// NextMeet Setup Couple Screen
/// Flat, accessible, zero-friction pairing hub
class SetupCoupleScreen extends StatefulWidget {
  final String? creatorName;
  final String? initialInviteCode;
  const SetupCoupleScreen({super.key, this.creatorName, this.initialInviteCode});

  @override
  State<SetupCoupleScreen> createState() => _SetupCoupleScreenState();
}

class _SetupCoupleScreenState extends State<SetupCoupleScreen> {
  String? _detectedCode;
  StreamSubscription<RelationshipModel?>? _relSubscription;

  @override
  void initState() {
    super.initState();
    _detectedCode = widget.initialInviteCode;
    if (_detectedCode == null) {
      _checkClipboard();
    }
    _listenForRelationship();
  }

  void _listenForRelationship() {
    _relSubscription?.cancel();
    _relSubscription = CloudRelationshipService().streamRelationship().listen((rel) {
      if (!mounted) return;
      if (rel != null && rel.status == 'active' && rel.uid2 != null) {
        _relSubscription?.cancel();
        VibrationService.success();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectionSuccessScreen(relationship: rel),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _relSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final cleanText = text.replaceAll(RegExp(r'[-\s]'), '');
      final match = RegExp(r'\b\d{6}\b').firstMatch(cleanText) ?? RegExp(r'\d{6}').firstMatch(cleanText);
      if (match != null && mounted) {
        setState(() {
          _detectedCode = match.group(0);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final String? resolvedName = widget.creatorName ?? AuthService().currentUser?.displayName;

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
                  Row(
                    children: [
                      const TwoMascotsRow(size: 26, spacing: 3),
                      const SizedBox(width: 8),
                      Text(
                        'NextMeet',
                        style: AppTextStyles.title2.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  TagChip(
                    label: 'For two',
                    backgroundColor: AppColors.pinkSoft,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Mascots Leaning Header
              const Center(
                child: TwoMascotsRow(size: 92, spacing: 16),
              ),

              const SizedBox(height: 20),

              Text(
                'Connect with\nyour partner',
                style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to set up your private couple space.',
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Clipboard Banner (if detected)
              if (_detectedCode != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.butterSoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.butter, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.butterText, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code Detected: $_detectedCode',
                              style: AppTextStyles.heading.copyWith(
                                color: AppColors.butterText,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Tap below to connect instantly!',
                              style: AppTextStyles.caption.copyWith(color: AppColors.butterText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Option 1: I Have a Partner Code
              NextMeetCard(
                borderColor: _detectedCode != null ? AppColors.primary : AppColors.border,
                borderWidth: _detectedCode != null ? 2.0 : 1.5,
                color: _detectedCode != null ? AppColors.pinkSoft.withValues(alpha: 0.3) : AppColors.card,
                onTap: () {
                  VibrationService.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JoinCoupleScreen(
                        userName: resolvedName,
                        initialCode: _detectedCode,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.pinkSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('I have an invite code', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            'Enter the 6-digit code your partner shared with you.',
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Option 2: I'm Starting Our Journey
              NextMeetCard(
                onTap: () {
                  VibrationService.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TellUsAboutYouScreen(
                        initialName: resolvedName,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.partnerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: AppColors.partner, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("I'm starting our journey", style: AppTextStyles.heading.copyWith(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            'Set up our story and get a code to invite your partner.',
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
