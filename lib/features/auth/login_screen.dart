import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';
import 'package:flutter/services.dart';
import '../../core/models/relationship_model.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../onboarding/setup_couple_screen.dart';
import 'create_account_screen.dart';
import 'forgot_identity_screen.dart';
import '../home/main_navigation_screen.dart';

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
      final match = RegExp(r'\b\d{6}\b').firstMatch(text);
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

    if (rel != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SetupCoupleScreen(initialInviteCode: _detectedInviteCode),
        ),
      );
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      VibrationService.medium();
      
      try {
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          setState(() => _isLoading = false);
          if (user != null) {
            VibrationService.success();
            await _navigatePostAuth();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          VibrationService.error();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '').split(']').last.trim()}')),
          );
        }
      }
    } else {
      VibrationService.error();
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    VibrationService.medium();
    
    try {
      final user = await _authService.signInWithGoogle();
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          VibrationService.success();
          await _navigatePostAuth();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        VibrationService.error();
        String errorString = e.toString();
        String displayError = 'Google Sign-In failed: ${errorString.split(']').last.trim()}';
        
        if (errorString.contains('ApiException: 10')) {
          displayError = 'Google Sign-In failed: Developer must add SHA-1 fingerprint to Firebase console.';
        } else if (errorString.contains('network_error')) {
          displayError = 'Google Sign-In failed: Check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100,
            right: -50,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.05),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'NextMeet',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                          fontSize: 32,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    if (_detectedInviteCode != null) ...[
                      const SizedBox(height: 12),
                      FadeInDown(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '❤️ Partner invite detected ($_detectedInviteCode)! Sign in to connect.',
                                  style: AppTextStyles.bodyS.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Hero(
                        tag: 'auth_illustration',
                        child: Container(
                          height: 280, // Increased height for the illustration
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.12),
                                AppColors.accent.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            child: Image.asset(
                              'assets/images/auth_illustration.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Text('Welcome Back ❤️', style: AppTextStyles.h2.copyWith(fontSize: 28)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Your love story continues here',
                            style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Email Field
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildInputWrapper(
                        label: 'EMAIL ADDRESS',
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'We need your email to find your partner ❤️';
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'This doesn\'t look like a valid love-mail 💌';
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
                    const SizedBox(height: AppSpacing.m),
                    // Password Field
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: _buildInputWrapper(
                        label: 'SECURE PASSWORD',
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'A secure password keeps your space safe 🔒';
                            if (value.length < 6) return 'Love is strong, your password should be too (min 6) 💪';
                            return null;
                          },
                          decoration: AppInputs.premiumInput(
                            'Password',
                            icon: Icons.lock_outline_rounded,
                            hint: '••••••••',
                          ).copyWith(
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                onPressed: () {
                                  VibrationService.light();
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    key: ValueKey(_isPasswordVisible),
                                    size: 20,
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            VibrationService.light();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotIdentityScreen()),
                            );
                          },
                          child: Text(
                            'Forgot identity?',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: PrimaryButton(
                        text: 'Login to NextMeet',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 700),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                            child: Text('EXPLORE MORE', 
                              style: AppTextStyles.bodyS.copyWith(
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: _buildSocialButton(
                        text: 'Continue with Google',
                        icon: FontAwesomeIcons.google,
                        onPressed: _handleGoogleSignIn,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 900),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'New to NextMeet? ', 
                                style: AppTextStyles.bodyL,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CreateAccountScreen()),
                                );
                              },
                              child: Text(
                                'Join Now',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        VibrationService.light();
        onPressed();
      },
      icon: FaIcon(icon, size: 18, color: AppColors.textPrimary),
      label: Flexible(
        child: Text(
          text,
          style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8), width: 1.5),
        backgroundColor: Colors.white,
      ),
    );
  }
}
