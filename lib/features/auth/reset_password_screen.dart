import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';
import '../home/main_navigation_screen.dart';
import '../onboarding/setup_couple_screen.dart';

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

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) {
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
          backgroundColor: AppColors.success,
        ),
      );

      // Check relationship status and navigate
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
          content: Text('Failed to update password: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            top: -100,
            left: -100,
            child: FadeIn(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            VibrationService.light();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                        Text(
                          'NextMeet',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 50),
                    FadeInUp(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.premiumShadow,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Text('Set New Password 🔒',
                              style: AppTextStyles.h2.copyWith(fontSize: 26)),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'Choose a strong password to protect your shared space.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyL
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // New Password Field
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildInputWrapper(
                        label: 'NEW PASSWORD',
                        child: TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.bodyL
                              .copyWith(fontWeight: FontWeight.bold),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your new password';
                            }
                            if (val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: AppInputs.premiumInput(
                            'New Password',
                            icon: Icons.lock_outline_rounded,
                            hint: '••••••••',
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    // Confirm Password Field
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: _buildInputWrapper(
                        label: 'CONFIRM PASSWORD',
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.bodyL
                              .copyWith(fontWeight: FontWeight.bold),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          decoration: AppInputs.premiumInput(
                            'Confirm Password',
                            icon: Icons.lock_clock_outlined,
                            hint: '••••••••',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: PrimaryButton(
                        text: 'Save & Enter Space',
                        isLoading: _isLoading,
                        onPressed: _handleUpdatePassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            label,
            style: AppTextStyles.bodyS.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: AppInputs.premiumInputDecoration,
          child: child,
        ),
      ],
    );
  }
}
