import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../home/main_navigation_screen.dart';
import '../onboarding/setup_couple_screen.dart';

/// NextMeet Reset Password Screen
/// Strictly following NextMeet Redesign.pdf (Page 15)
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMin8Chars => _newPasswordController.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_newPasswordController.text);
  bool get _hasSymbol => RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_newPasswordController.text);

  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate() || !_passwordsMatch) {
      VibrationService.error();
      return;
    }

    setState(() => _isLoading = true);
    VibrationService.medium();

    try {
      await FirebaseAuthService().setNewPassword(_newPasswordController.text);
      if (!mounted) return;

      VibrationService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Welcome back ❤️'),
          backgroundColor: AppColors.mint,
        ),
      );

      final rel = await CloudRelationshipService()
          .streamRelationship()
          .first
          .timeout(const Duration(seconds: 4), onTimeout: () => null);

      if (!mounted) return;

      if (rel != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SetupCoupleScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update password: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.partner, // Violet header canvas (Page 15)
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Smiling Mascot Heart
            const Center(
              child: MascotHeart(
                color: MascotColor.pink,
                size: 88,
              ),
            ),

            const SizedBox(height: 20),

            // Form Sheet
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create a new password',
                          style: AppTextStyles.display.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Make it something only you know.',
                          style: AppTextStyles.body.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 24),

                        // New password
                        Text('New password', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.body,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'At least 8 characters',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.muted,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 8) return 'Must be at least 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm password
                        Text('Confirm password', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.body,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Type it again',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: _passwordsMatch
                                ? const Icon(Icons.check_rounded, color: AppColors.mint, size: 22)
                                : null,
                          ),
                          validator: (val) {
                            if (val != _newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Strength Indicators (Page 15)
                        Text(
                          'Strong password',
                          style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.mintText),
                        ),
                        const SizedBox(height: 8),

                        _strengthItem('At least 8 characters', _hasMin8Chars),
                        const SizedBox(height: 6),
                        _strengthItem('A number', _hasNumber),
                        const SizedBox(height: 6),
                        _strengthItem('A symbol (optional)', _hasSymbol, isOptional: true),

                        const SizedBox(height: 28),

                        PrimaryButton(
                          text: 'Save password',
                          isLoading: _isLoading,
                          onPressed: _handleUpdatePassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strengthItem(String label, bool isSatisfied, {bool isOptional = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSatisfied ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSatisfied ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: isSatisfied
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSatisfied ? AppColors.ink : AppColors.muted,
            fontWeight: isSatisfied ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
