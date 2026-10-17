import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/security_service.dart';
import '../../core/models/relationship_model.dart';
import 'private_home_screen.dart';
import '../onboarding/setup_couple_screen.dart';

class PrivateSpaceLockScreen extends StatefulWidget {
  final RelationshipModel? rel;
  final VoidCallback? onUnlocked;
  final VoidCallback? onClose;
  final bool isTabMode;

  const PrivateSpaceLockScreen({
    super.key,
    this.rel,
    this.onUnlocked,
    this.onClose,
    this.isTabMode = false,
  });

  @override
  State<PrivateSpaceLockScreen> createState() => _PrivateSpaceLockScreenState();
}

class _PrivateSpaceLockScreenState extends State<PrivateSpaceLockScreen> {
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final SecurityService _securityService = SecurityService();
  String _enteredPin = '';
  String? _firstPin;
  bool _hasError = false;
  bool _biometricChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoBiometrics();
    });
  }

  Future<void> _checkAutoBiometrics() async {
    if (_biometricChecked) return;
    _biometricChecked = true;
    try {
      final targetRel = widget.rel ?? await _cloudService.streamRelationship().first;
      final localEnabled = await _securityService.isLocalBiometricEnabled();
      if (targetRel != null && (targetRel.useBiometrics || localEnabled || targetRel.isPlus) && targetRel.privateSpacePin != null) {
        final available = await _securityService.isBiometricAvailable();
        if (available && mounted) {
          final result = await _securityService.authenticateWithDetails(
            reason: 'Scan Fingerprint or Face Camera to unlock',
            biometricOnly: false,
          );
          if (result.success && mounted) {
            _handleUnlock();
          }
        }
      }
    } catch (_) {}
  }

  void _handleUnlock() {
    VibrationService.success();
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PrivateHomeScreen()),
      );
    }
  }

  void _onDigitTapped(String digit, RelationshipModel rel) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _onPinComplete(_enteredPin, rel);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      VibrationService.light();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClearAll() {
    if (_enteredPin.isNotEmpty) {
      VibrationService.medium();
      setState(() {
        _enteredPin = '';
      });
    }
  }

  void _onPinComplete(String pin, RelationshipModel rel) async {
    if (rel.privateSpacePin == null) {
      // Setup Mode
      if (_firstPin == null) {
        setState(() {
          _firstPin = pin;
          _enteredPin = '';
        });
        VibrationService.medium();
      } else {
        if (_firstPin == pin) {
          // Confirm PIN
          await _cloudService.updatePrivateSpacePin(rel.id!, pin);
          if (mounted) _handleUnlock();
        } else {
          // Mismatch
          VibrationService.error();
          setState(() {
            _hasError = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PINs do not match. Try again.')),
            );
          }
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _firstPin = null;
              _enteredPin = '';
              _hasError = false;
            });
          }
        }
      }
    } else {
      // Verification Mode
      final bool isApproved =
          rel.pinResetRequestBy == _cloudService.currentUid && rel.pinResetApproved;

      if (rel.privateSpacePin == pin ||
          (isApproved && _firstPin != null && _firstPin == pin)) {
        if (isApproved) {
          await _cloudService.finalizePinReset(rel.id!, pin);
        }
        if (mounted) _handleUnlock();
      } else if (isApproved && _firstPin == null) {
        setState(() {
          _firstPin = pin;
          _enteredPin = '';
        });
        VibrationService.medium();
      } else {
        VibrationService.error();
        setState(() {
          _hasError = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN ❌')),
          );
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _hasError = false;
          });
        }
      }
    }
  }

  void _showForgotPinSheet(String relId, RelationshipModel rel) {
    VibrationService.light();
    final partnerName = rel.getDisplayPartnerName(_cloudService.currentUid);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Forgot Sanctuary PIN? 🔐',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'To protect your private letters and secret vault, a reset request will be sent to $partnerName. Once they approve on their phone, you can set a brand new 4-digit code.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _cloudService.requestPinReset(relId);
                  VibrationService.success();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reset request sent to $partnerName! ⏳'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'SEND RESET REQUEST',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rel != null) {
      if (widget.rel!.id == null || widget.rel!.uid2 == null) {
        return _buildUnpairedScreen();
      }
      return _buildContent(widget.rel!);
    }

    return StreamBuilder<RelationshipModel?>(
      stream: _cloudService.streamRelationship(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDEEF1),
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null || snapshot.data?.uid2 == null) {
          return _buildUnpairedScreen();
        }

        return _buildContent(snapshot.data!);
      },
    );
  }

  Widget _buildUnpairedScreen() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onClose != null) {
          widget.onClose!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDEEF1),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'SANCTUARY',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              VibrationService.light();
              if (widget.onClose != null) {
                widget.onClose!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            tooltip: 'Exit Sanctuary',
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
      ),
    );
  }

  Widget _buildContent(RelationshipModel rel) {
    final bool needsSetup = rel.privateSpacePin == null;
    final bool isApproved =
        rel.pinResetRequestBy == _cloudService.currentUid && rel.pinResetApproved;

    String title;
    String subtitle;

    if (isApproved) {
      title = _firstPin == null ? 'Approval Received! ✨' : 'Confirm New PIN';
      subtitle = _firstPin == null ? 'Create a new 4-digit code' : 'Re-enter code to confirm';
    } else if (needsSetup) {
      title = _firstPin == null ? 'Private Sanctuary 🔐' : 'Confirm Your PIN';
      subtitle = _firstPin == null ? 'Create a secret 4-digit key' : 'Re-enter code to confirm';
    } else {
      title = 'Private Sanctuary 🔒';
      subtitle = 'Enter your 4-digit passcode';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onClose != null) {
          widget.onClose!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDEEF1),
        body: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        VibrationService.light();
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                      tooltip: 'Exit Sanctuary',
                    ),
                    const Spacer(),
                    Text(
                      'SANCTUARY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

                const Spacer(flex: 2),

                // Security Icon
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_moon_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h2.copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // PIN Indicators (Dots with mini heart micro-detail)
                FadeInUp(
                  duration: const Duration(milliseconds: 450),
                  child: _buildPinDots(),
                ),

                const Spacer(flex: 3),

                // On-Screen Numeric Dialpad
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildKey('1', '', () => _onDigitTapped('1', rel)),
                            _buildKey('2', 'ABC', () => _onDigitTapped('2', rel)),
                            _buildKey('3', 'DEF', () => _onDigitTapped('3', rel)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildKey('4', 'GHI', () => _onDigitTapped('4', rel)),
                            _buildKey('5', 'JKL', () => _onDigitTapped('5', rel)),
                            _buildKey('6', 'MNO', () => _onDigitTapped('6', rel)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildKey('7', 'PQRS', () => _onDigitTapped('7', rel)),
                            _buildKey('8', 'TUV', () => _onDigitTapped('8', rel)),
                            _buildKey('9', 'WXYZ', () => _onDigitTapped('9', rel)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBiometricSlot(rel),
                            _buildKey('0', '', () => _onDigitTapped('0', rel)),
                            _buildBackspaceKey(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reset / Forgot PIN Bar
                if (!needsSetup) _buildResetBar(rel),

              ],
            ),
          ),
        ),
      );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 20 : 18,
          height: isFilled ? 20 : 18,
          decoration: BoxDecoration(
            color: _hasError
                ? Colors.red
                : (isFilled ? AppColors.primary : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hasError
                  ? Colors.red
                  : (isFilled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (_hasError ? Colors.red : AppColors.primary).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: isFilled
              ? const Center(
                  child: Icon(Icons.favorite_rounded, size: 10, color: Colors.white),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildKey(String number, String letters, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          VibrationService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.pink.shade50),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricSlot(RelationshipModel rel) {
    if (rel.privateSpacePin != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            VibrationService.light();
            final result = await _securityService.authenticateWithDetails(
              reason: 'Scan Fingerprint or Face Camera to unlock',
              biometricOnly: false,
            );
            if (!result.success) {
              if (mounted && result.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              return;
            }
            if (mounted) _handleUnlock();
          },
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.fingerprint_rounded, size: 30, color: AppColors.primary),
          ),
        ),
      );
    }
    return const SizedBox(width: 70, height: 70);
  }

  Widget _buildBackspaceKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        onLongPress: _onClearAll,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.pink.shade50),
          ),
          child: const Icon(
            Icons.backspace_outlined,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildResetBar(RelationshipModel rel) {
    final isMyResetPending =
        rel.pinResetRequestBy == _cloudService.currentUid && !rel.pinResetApproved;
    final isPartnerResetPending =
        rel.pinResetRequestBy != null &&
        rel.pinResetRequestBy != _cloudService.currentUid &&
        !rel.pinResetApproved;

    if (isMyResetPending) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pink.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Waiting for partner approval...',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  VibrationService.light();
                  _cloudService.cancelPinReset(rel.id!);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isPartnerResetPending) {
      final partnerName = rel.getDisplayPartnerName(_cloudService.currentUid);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          onPressed: () {
            VibrationService.success();
            _cloudService.approvePinReset(rel.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Approved PIN reset for $partnerName! ✨')),
            );
          },
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          label: Text('Approve Reset for $partnerName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    return TextButton(
      onPressed: () => _showForgotPinSheet(rel.id!, rel),
      child: Text(
        'Forgot PIN?',
        style: AppTextStyles.bodyS.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
