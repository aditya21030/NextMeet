import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_inputs.dart';
import '../../core/services/firebase_auth_service.dart';
import '../onboarding/setup_couple_screen.dart';
import 'login_screen.dart';
import '../profile/terms_policy_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final FirebaseAuthService _authService = FirebaseAuthService(); // Instantiated FirebaseAuthService

  void _handleCreateAccount() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please walk with us by agreeing to the terms ❤️')),
      );
      VibrationService.error();
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
        
        if (mounted) {
          setState(() => _isLoading = false);
          if (user != null) {
            VibrationService.success();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SetupCoupleScreen(creatorName: _nameController.text)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          VibrationService.error();
          
          String errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('email-already-in-use')) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This love-mail is already registered! ❤️ Please log in instead.'),
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration failed: ${e.toString().split(']').last.trim()}')),
            );
          }
        }
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
          // Decorative background elements
          Positioned(
            top: -50,
            left: -50,
            child: FadeIn(
              duration: const Duration(seconds: 2),
              child: Container(
                width: 250,
                height: 250,
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
          
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              VibrationService.light();
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                );
                              }
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
                    const SizedBox(height: AppSpacing.l),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Hero(
                        tag: 'auth_illustration',
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
                            Icons.favorite_rounded,
                            size: 60,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        children: [
                          Text('Create Your Account ❤️', style: AppTextStyles.h2.copyWith(fontSize: 26)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Begin your shared adventure',
                            style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Full Name Field
                    _buildField(
                      label: 'ACCOUNT NAME',
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_rounded,
                      delay: 200,
                      validator: (val) => val!.isEmpty ? 'Your partner wants to know it\'s you! 👤' : null,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    // Email Field
                    _buildField(
                      label: 'EMAIL ADDRESS',
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      delay: 300,
                      type: TextInputType.emailAddress,
                      validator: (val) {
                        if (val!.isEmpty) return 'Share your email to begin the journey ❤️';
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return 'Invalid love-mail format 💌';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    // Password Field
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('PASSWORD'),
                          Container(
                            decoration: AppInputs.premiumInputDecoration,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                              validator: (val) => val!.length < 6 ? 'Keep your space extra safe with 6+ chars 🔒' : null,
                              decoration: AppInputs.premiumInput(
                                'Password',
                                icon: Icons.lock_person_rounded,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    // Terms and Conditions checkbox
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (val) {
                                  VibrationService.light();
                                  setState(() => _agreedToTerms = val ?? false);
                                },
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodyM,
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const TermsPolicyScreen(
                                              title: 'Terms of Service',
                                              content: '', // Content is now handled internally in TermsPolicyScreen
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Terms',
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: ' & '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const TermsPolicyScreen(
                                              title: 'Privacy Policy',
                                              content: '',
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Privacy Policy',
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 700),
                      child: PrimaryButton(
                        text: 'Register Account',
                        isLoading: _isLoading,
                        onPressed: _handleCreateAccount,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Already on NextMeet? ', 
                                style: AppTextStyles.bodyL,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                VibrationService.light();
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginScreen()),
                                  );
                                }
                              },
                              child: Text(
                                'Log In',
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required int delay,
    bool obscure = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          Container(
            decoration: AppInputs.premiumInputDecoration,
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: type,
              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
              validator: validator,
              decoration: AppInputs.premiumInput(hint, icon: icon),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLabel(String label) {
    return Padding(
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
    );
  }
}
