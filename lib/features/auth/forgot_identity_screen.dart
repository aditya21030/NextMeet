import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Forgot Password & Reset Sent Screen
/// Strictly following NextMeet Redesign.pdf (Pages 13 & 14)
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

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      VibrationService.medium();

      try {
        await FirebaseAuthService().sendPasswordResetEmail(_emailController.text.trim());
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isSent = true;
        });
        VibrationService.success();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else {
      VibrationService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSent) {
      return _buildCheckInboxScreen();
    }
    return _buildForgotPasswordScreen();
  }

  // Page 13: Forgot Password Screen
  Widget _buildForgotPasswordScreen() {
    return Scaffold(
      backgroundColor: AppColors.primary, // Pink canvas header
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back Button + "Oops, it happens" badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butter,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'Oops, it happens',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.butterText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Smiling Mascot Heart (Page 13)
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Text(
                        'Forgot your password?',
                        style: AppTextStyles.display.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your email and we will send you a link to reset it.',
                        style: AppTextStyles.body.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 24),

                      Text('Email', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                          hintText: 'you@email.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 22),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your email';
                          if (!val.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: 'Send reset link',
                        isLoading: _isLoading,
                        onPressed: _handleReset,
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Back to log in',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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

  // Page 14: Check Your Inbox Screen
  Widget _buildCheckInboxScreen() {
    return Scaffold(
      backgroundColor: AppColors.butter, // Yellow header canvas (Page 14)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Envelope with Heart Seal
              Center(
                child: Container(
                  width: 140,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // White Sheet
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Check your inbox',
                    style: AppTextStyles.display.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a reset link to ${_emailController.text}. It works for 30 minutes.',
                    style: AppTextStyles.body.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Open email app',
                    onPressed: () {
                      VibrationService.light();
                    },
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _handleReset,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.pinkSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Resend link',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to log in',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Spam folder notice card (Page 14)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.partnerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: AppColors.partner, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Not there? Check your spam folder.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.partnerText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
