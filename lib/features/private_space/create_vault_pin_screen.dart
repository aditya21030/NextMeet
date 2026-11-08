import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Create / Change Vault PIN Screen
/// Strictly following NextMeet Redesign.pdf (Page 59)
class CreateVaultPinScreen extends StatefulWidget {
  final String? relId;
  const CreateVaultPinScreen({super.key, this.relId});

  @override
  State<CreateVaultPinScreen> createState() => _CreateVaultPinScreenState();
}

class _CreateVaultPinScreenState extends State<CreateVaultPinScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isSaving = false;

  void _onDigit(String d) {
    if (_isSaving) return;
    VibrationService.light();
    if (!_isConfirming) {
      if (_firstPin.length < 4) {
        setState(() => _firstPin += d);
        if (_firstPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (!mounted) return;
            setState(() => _isConfirming = true);
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += d);
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    }
  }

  void _onBackspace() {
    if (_isSaving) return;
    VibrationService.light();
    if (!_isConfirming) {
      if (_firstPin.isNotEmpty) {
        setState(() => _firstPin = _firstPin.substring(0, _firstPin.length - 1));
      }
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _verifyAndSave() async {
    if (_firstPin == _confirmPin) {
      setState(() => _isSaving = true);
      VibrationService.success();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('vault_pin', _firstPin);

        final rel = await CloudRelationshipService()
            .streamRelationship()
            .first
            .timeout(const Duration(seconds: 5));
        final targetRelId = widget.relId ?? rel?.id;
        if (targetRelId != null && targetRelId.isNotEmpty) {
          await CloudRelationshipService().finalizePinReset(targetRelId, _firstPin);
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault PIN successfully saved! 🔒✨'),
          backgroundColor: AppColors.mintText,
        ),
      );
      Navigator.pop(context, true);
    } else {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs did not match. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() {
        _confirmPin = '';
        _isConfirming = false;
        _firstPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
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
                  Text('Vault PIN', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 24),

              // Lock Mascot Icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 32),
              ),

              const SizedBox(height: 18),

              Text(
                _isConfirming ? 'Confirm your 4-digit PIN' : 'Create your Vault PIN',
                style: AppTextStyles.title1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                _isConfirming
                    ? 'Re-enter the same 4 numbers to confirm'
                    : 'This protects your private photos & love letters',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // 4 PIN Dots (Page 59)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: isFilled ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Custom Numeric Keypad
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    _keypadRow(['1', '2', '3']),
                    const SizedBox(height: 14),
                    _keypadRow(['4', '5', '6']),
                    const SizedBox(height: 14),
                    _keypadRow(['7', '8', '9']),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 72, height: 56),
                        _keypadButton('0'),
                        GestureDetector(
                          onTap: _onBackspace,
                          child: Container(
                            width: 72,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: const Icon(Icons.backspace_outlined, color: AppColors.ink, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security Guarantee
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    'End-to-end encrypted • Private to you',
                    style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _keypadButton(d)).toList(),
    );
  }

  Widget _keypadButton(String digit) {
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 72,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: AppTextStyles.title1.copyWith(fontSize: 22, color: AppColors.ink),
        ),
      ),
    );
  }
}
