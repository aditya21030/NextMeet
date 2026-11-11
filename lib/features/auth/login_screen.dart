import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../onboarding/setup_couple_screen.dart';
import 'create_account_screen.dart';
import 'forgot_identity_screen.dart';
import '../home/main_navigation_screen.dart';
import '../../core/services/auth_error_handler.dart';
import '../profile/terms_policy_screen.dart';

/// NextMeet Login Screen
/// Strictly following NextMeet Redesign.pdf (Page 12)
class LoginScreen extends StatefulWidget {
  final String? initialInviteCode;
  const LoginScreen({super.key, this.initialInviteCode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _detectedInviteCode;

  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _detectedInviteCode = widget.initialInviteCode;
    if (_detectedInviteCode == null) {
      _checkClipboard();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          _detectedInviteCode = match.group(0);
        });
      }
    } catch (_) {}
  }

  Future<void> _navigatePostAuth() async {
    RelationshipModel? rel;
    try {
      rel = await CloudRelationshipService()
          .streamRelationship()
          .first
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
    } catch (_) {}

    if (!mounted) return;

    String? inviteCodeForSetup = _detectedInviteCode;
    if (rel != null && inviteCodeForSetup != null && rel.inviteCode == inviteCodeForSetup) {
      inviteCodeForSetup = null;
    }

    final isActivelyPaired = rel != null && rel.status == 'active' && rel.uid2 != null;
    final isWaitingState = rel != null && rel.status == 'waiting';

    if (isActivelyPaired || (isWaitingState && inviteCodeForSetup == null)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SetupCoupleScreen(initialInviteCode: inviteCodeForSetup),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      VibrationService.medium();

      try {
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (user != null) {
          VibrationService.success();
          await _navigatePostAuth();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not log in. Please check your credentials ❤️'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        VibrationService.error();
        final friendlyMsg = AuthErrorHandler.getLoginErrorMessage(e);
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
        await _navigatePostAuth();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Full pink top canvas (Page 12)
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: NextMeet Logo + "Welcome back!" chip (Page 12)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const TwoMascotsRow(size: 24, spacing: 3),
                      const SizedBox(width: 8),
                      Text(
                        'NextMeet',
                        style: AppTextStyles.title2.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butter,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'Welcome back!',
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

            // Mascots Leaning Together
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: TwoMascotsRow(size: 88, spacing: 14),
            ),

            // Main Form Sheet (Rounded Top Sheet)
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tab Selector: [Log in] [Sign up] (Page 12)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.pinkSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Log in',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateAccountScreen(
                                          initialInviteCode: _detectedInviteCode,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 44,
                                    color: Colors.transparent,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign up',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.ink,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Email Field
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

                        const SizedBox(height: 16),

                        // Password Field
                        Text('Password', style: AppTextStyles.label.copyWith(color: AppColors.ink)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            hintText: 'Your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.muted,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (val) => (val == null || val.isEmpty) ? 'Please enter your password' : null,
                        ),

                        const SizedBox(height: 12),

                        // Remember Me & Forgot Password Row (Page 12)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _rememberMe ? AppColors.primary : AppColors.card,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: _rememberMe ? AppColors.primary : AppColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _rememberMe
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Remember me', style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotIdentityScreen()),
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Log In Button
                        PrimaryButton(
                          text: 'Log in',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
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

                        // Continue with Google
                        GestureDetector(
                          onTap: _handleGoogleSignIn,
                          child: Container(
                            height: 52,
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

                        const SizedBox(height: 20),

                        // Terms and Privacy Footer
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TermsPolicyScreen()),
                              );
                            },
                            child: Text(
                              'By continuing you agree to our Terms and Privacy Policy',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
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
}
