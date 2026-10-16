import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';
import '../../core/services/firebase_auth_service.dart';

class ForgotIdentityScreen extends StatefulWidget {
  const ForgotIdentityScreen({super.key});

  @override
  State<ForgotIdentityScreen> createState() => _ForgotIdentityScreenState();
}

class _ForgotIdentityScreenState extends State<ForgotIdentityScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      VibrationService.medium();
      
      try {
        await FirebaseAuthService().sendPasswordResetEmail(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSent = true;
          });
          VibrationService.success();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
          );
        }
        VibrationService.error();
      }
    } else {
      VibrationService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background accents
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
                      AppColors.primary.withValues(alpha: 0.05),
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
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              VibrationService.light();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
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
                    ),
                    const SizedBox(height: 60),
                    
                    if (!_isSent) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppColors.premiumShadow,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            size: 60,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Text('Forgot Identity? ❤️', style: AppTextStyles.h2.copyWith(fontSize: 26)),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              'Enter your email to recover your digital space.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildInputWrapper(
                          label: 'EMAIL ADDRESS',
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                            validator: (val) {
                              if (val!.isEmpty) return 'We need your email to find your space ❤️';
                              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return 'This doesn\'t look like a valid email 💌';
                              return null;
                            },
                            decoration: AppInputs.premiumInput(
                              'Email Address',
                              icon: Icons.alternate_email_rounded,
                              hint: 'Enter your email',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: PrimaryButton(
                          text: 'Recover Account',
                          isLoading: _isLoading,
                          onPressed: _handleReset,
                        ),
                      ),
                    ] else ...[
                      _buildSuccessState(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final email = _emailController.text.trim();
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppColors.premiumShadow,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Reset Link Sent! 💌', style: AppTextStyles.h2.copyWith(fontSize: 26)),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'We sent a password reset link to:\n$email\n\nTap the link in your email on this phone to open NextMeet directly and set your new password.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 36),
          PrimaryButton(
            text: 'Back to Login',
            onPressed: () {
              VibrationService.light();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _isLoading ? null : _handleReset,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
            label: Text(
              'Resend Reset Link',
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
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
