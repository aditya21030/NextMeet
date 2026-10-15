import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/security_service.dart';
import '../../core/models/relationship_model.dart';
import 'private_home_screen.dart';
import '../onboarding/setup_couple_screen.dart';

class PrivateSpaceLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool isTabMode;
  const PrivateSpaceLockScreen({super.key, this.onUnlocked, this.isTabMode = false});

  @override
  State<PrivateSpaceLockScreen> createState() => _PrivateSpaceLockScreenState();
}

class _PrivateSpaceLockScreenState extends State<PrivateSpaceLockScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
      // ignore: unused_field
  final SecurityService _securityService = SecurityService();
  final TextEditingController _pinController = TextEditingController();
      // ignore: unused_field
  
  bool _isSetupMode = false;
  String? _firstPin;

  @override
  void initState() {
    super.initState();
  }



  void _onPinComplete(String pin, RelationshipModel rel) async {
    if (rel.privateSpacePin == null) {
      // Setup Mode
      if (_firstPin == null) {
        setState(() {
          _firstPin = pin;
          _pinController.clear();
        });
        VibrationService.medium();
      } else {
        if (_firstPin == pin) {
          // Confirm PIN
          await _cloudService.updatePrivateSpacePin(rel.id!, pin);
          VibrationService.success();
          if (mounted) {
            if (widget.onUnlocked != null) {
              widget.onUnlocked!();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PrivateHomeScreen()),
              );
            }
          }
        } else {
          // Mismatch
          VibrationService.error();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs do not match. Try again.')),
          );
          setState(() {
            _firstPin = null;
            _pinController.clear();
          });
        }
      }
    } else {
      // Verification Mode
      final bool isApproved = rel.pinResetRequestBy == _cloudService.currentUid && rel.pinResetApproved;
      
      if (rel.privateSpacePin == pin || (isApproved && _firstPin != null && _firstPin == pin)) {
        if (isApproved) {
          await _cloudService.finalizePinReset(rel.id!, pin);
        }
      // ignore: use_build_context_synchronously
        VibrationService.success();
        if (widget.onUnlocked != null) {
          widget.onUnlocked!();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PrivateHomeScreen()),
          );
        }
      } else if (isApproved && _firstPin == null) {
        setState(() {
          _firstPin = pin;
          _pinController.clear();
        });
        VibrationService.medium();
      } else {
        VibrationService.error();
        _pinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN ❌')),
        );
      }
    }
  }

  void _showForgotPinDialog(String relId, RelationshipModel rel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Reset Private PIN? 🔐'),
        content: const Text(
          'For security, a request will be sent to your partner. You can set a new PIN once they approve it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
      // ignore: use_build_context_synchronously
              await _cloudService.requestPinReset(relId);
              VibrationService.medium();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset request sent to partner. Please wait for approval. ⏳')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
            ),
            child: const Text('SEND REQUEST', style: TextStyle(color: Colors.white)),
          ),
        ],
      // ignore: unused_element
      ),
    );
  }

  void _showResetConfirmDialog(String relId) {
    _pinController.clear();
    setState(() {
      _isSetupMode = true; // Temporary setup mode for new PIN
      _firstPin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDEEF1),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDEEF1),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('SANCTUARY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.textPrimary)),
              centerTitle: true,
              leading: widget.isTabMode
                  ? null
                  : IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_moon_rounded, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Private Couple Sanctuary', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'A private, protected space for your Love Notes and Secret Photos. Connect with your partner to unlock.',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupCoupleScreen()));
                      },
                      icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                      label: const Text('Connect with Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final rel = snapshot.data!;
        final bool needsSetup = rel.privateSpacePin == null;

        return Scaffold(
          backgroundColor: const Color(0xFFFDEEF1),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  if (!widget.isTabMode)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.m),
                  const Spacer(),
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_moon_rounded, size: 64, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeInUp(
                    child: Column(
                      children: [
                        Text(
                          rel.pinResetRequestBy == _cloudService.currentUid && rel.pinResetApproved
                            ? (_firstPin == null ? 'Approval Received! ✨' : 'Confirm New PIN')
                            : (needsSetup ? (_firstPin == null ? 'Set Up Private Space' : 'Confirm Your PIN') : 'Private Space 🔒'), 
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rel.pinResetRequestBy == _cloudService.currentUid && rel.pinResetApproved
                            ? (_firstPin == null ? 'Create a new 4-digit code' : 'Re-enter to confirm')
                            : (needsSetup ? (_firstPin == null ? 'Choose a 4-digit code' : 'Re-enter your code to confirm') : 'ENTER PIN'), 
                          style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeInUp(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Pinput(
                        length: 4,
                        controller: _pinController,
                        obscureText: true,
                        onCompleted: (pin) => _onPinComplete(pin, rel),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Spacer(),
                  if (!needsSetup)
                    Column(
                      children: [
                        if (rel.pinResetRequestBy == _cloudService.currentUid && !rel.pinResetApproved)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 12),
                             child: Column(
                               children: [
                                 const CircularProgressIndicator(strokeWidth: 2),
                                 const SizedBox(height: 12),
                                 Text(
                                   'Waiting for partner approval...',
                                   style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                 ),
                                 TextButton(
                                   onPressed: () => _cloudService.cancelPinReset(rel.id!),
                                   child: const Text('Cancel Request', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                 ),
                               ],
                             ),
                           )
                        else if (rel.pinResetRequestBy != null && rel.pinResetRequestBy != _cloudService.currentUid && !rel.pinResetApproved)
                          Column(
                            children: [
                              Text(
                                'Partner requested a PIN reset ✨',
                                style: AppTextStyles.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  VibrationService.success();
                                  _cloudService.approvePinReset(rel.id!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('APPROVE REQUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        else
                          TextButton(
                            onPressed: () => _showForgotPinDialog(rel.id!, rel),
                            child: Text('Forgot PIN?', style: AppTextStyles.bodyM.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
