import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/auth_error_handler.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import '../onboarding/tell_us_about_you_screen.dart';
import '../profile/terms_policy_screen.dart';

/// NextMeet Create Account Screen
/// Strictly following NextMeet Redesign.pdf (Page 4)
class CreateAccountScreen extends StatefulWidget {
  final String? initialInviteCode;

  const CreateAccountScreen({
    super.key,
    this.initialInviteCode,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _detectedInviteCode;

  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _detectedInviteCode = widget.initialInviteCode?.replaceAll(RegExp(r'[-\s]'), '');
    if (_detectedInviteCode == null) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final cleanText = text.replaceAll(RegExp(r'[-\s]'), '');
      final match = RegExp(r'\b\d{6}\b').firstMatch(cleanText) ?? RegExp(r'\d{6}').firstMatch(cleanText);
      if (match != null && mounted) {
        setState(() {
          _detectedInviteCode = match.group(0);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch {
    final p1 = _passwordController.text;
    final p2 = _confirmPasswordController.text;
    return p1.isNotEmpty && p2.isNotEmpty && p1 == p2;
  }

  Future<void> _handleCreateAccount() async {
    if (!_agreedToTerms) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Privacy Policy ❤️'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (!_passwordsMatch) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      VibrationService.medium();

      try {
        final user = await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (user != null) {
          VibrationService.success();
          // Seamless onboarding transition directly to Step 1: Tell Us About You
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TellUsAboutYouScreen(
                initialName: _nameController.text.trim(),
                initialInviteCode: _detectedInviteCode ?? widget.initialInviteCode,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not create account. Please check your details ❤️'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        VibrationService.error();
        final friendlyMsg = AuthErrorHandler.getRegistrationErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else {
      VibrationService.error();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    VibrationService.medium();

    try {
      final user = await _authService.signInWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        VibrationService.success();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TellUsAboutYouScreen(
              initialName: user.displayName ?? _nameController.text.trim(),
              initialInviteCode: _detectedInviteCode ?? widget.initialInviteCode,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-in failed: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.partner, // Purple/violet top area (Page 4)
      body: Stack(
        children: [
          // Peeking smiling mascot heart on top right
          Positioned(
            top: 40,
            right: 20,
            child: const MascotHeart(
              color: MascotColor.pink,
              size: 80,
              leanLeft: true,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Header Text
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create your\naccount',
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Just a minute and you are in.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Form Card (Rounded Top Sheet)
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
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Name Field
                            Text('Your name', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              style: AppTextStyles.body,
                              decoration: InputDecoration(
                                hintText: 'e.g. Alex',
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
                                fillColor: AppColors.card,
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),

                            // 2. Email Field
                            Text('Email', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.body,
                              decoration: InputDecoration(
                                hintText: 'you@email.com',
                                prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 22),
                                fillColor: AppColors.card,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Please enter your email';
                                if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3. Password Field
                            Text('Password', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
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
                                fillColor: AppColors.card,
                              ),
                              validator: (val) => (val == null || val.length < 6) ? 'Must be at least 6 characters' : null,
                            ),
                            const SizedBox(height: 16),

                            // 4. Confirm Password Field
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
                                fillColor: AppColors.card,
                              ),
                              validator: (val) {
                                if (val != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),

                            // Passwords match indicator (Page 4)
                            if (_passwordsMatch) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Passwords match',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.mintText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Terms & Privacy Agreement Checkbox
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _agreedToTerms ? AppColors.primary : AppColors.card,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _agreedToTerms ? AppColors.primary : AppColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _agreedToTerms
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const TermsPolicyScreen()),
                                      );
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTextStyles.caption.copyWith(color: AppColors.ink),
                                        children: [
                                          const TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms and Privacy Policy',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Create Account CTA Button
                            PrimaryButton(
                              text: 'Create account',
                              isLoading: _isLoading,
                              onPressed: _handleCreateAccount,
                            ),

                            const SizedBox(height: 16),

                            // "or" Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('or', style: AppTextStyles.caption),
                                ),
                                const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Continue with Google Button
                            GestureDetector(
                              onTap: _handleGoogleSignIn,
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(FontAwesomeIcons.google, color: Color(0xFF4285F4), size: 18),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.ink,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Already have an account? Log in
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                        initialInviteCode: widget.initialInviteCode,
                                      ),
                                    ),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.body.copyWith(color: AppColors.muted),
                                    children: [
                                      const TextSpan(text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Log in',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
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
        ],
      ),
    );
  }
}
