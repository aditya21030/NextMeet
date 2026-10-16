import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import 'create_couple_screen.dart';
import 'join_couple_screen.dart';

class SetupCoupleScreen extends StatefulWidget {
  final String? creatorName;
  final String? initialInviteCode;
  const SetupCoupleScreen({super.key, this.creatorName, this.initialInviteCode});

  @override
  State<SetupCoupleScreen> createState() => _SetupCoupleScreenState();
}

class _SetupCoupleScreenState extends State<SetupCoupleScreen> {
  String? _detectedCode;

  @override
  void initState() {
    super.initState();
    _detectedCode = widget.initialInviteCode;
    if (_detectedCode == null) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final match = RegExp(r'\b\d{6}\b').firstMatch(text);
      if (match != null && mounted) {
        setState(() {
          _detectedCode = match.group(0);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to Auth display name if not passed from registration
    final String? resolvedName = widget.creatorName ?? AuthService().currentUser?.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -100,
            right: -100,
            child: FadeIn(
              duration: const Duration(seconds: 2),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: IconButton(
                      onPressed: () {
                        VibrationService.light();
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  FadeInLeft(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Setup Your Couple ❤️', style: AppTextStyles.h1.copyWith(fontSize: 32)),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          'How would you like to bridge the gap with your favorite person?',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Detected invite code banner
                  if (_detectedCode != null)
                    FadeInDown(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.l),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F3),
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Partner Code Detected: $_detectedCode ✨',
                                    style: AppTextStyles.bodyM.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap "I Have a Partner Code" below to pair in 1 tap!',
                                    style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // PRIMARY OPTION: I Have a Partner Code (Eliminates drop-off confusion)
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: _buildOptionCard(
                      context,
                      badgeText: _detectedCode != null ? 'CODE READY TO PAIR ✨' : 'HAVE AN INVITE CODE?',
                      title: 'I Have a Partner Code',
                      description: 'Partner already shared a 6-digit code? Connect your hearts and sync your worlds permanently.',
                      icon: Icons.link_rounded,
                      actionText: 'Connect Heart',
                      isPrimary: true,
                      highlighted: _detectedCode != null,
                      onTap: () {
                        VibrationService.medium();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JoinCoupleScreen(
                              userName: resolvedName,
                              initialCode: _detectedCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // SECONDARY OPTION: I'm Starting Our Journey (Create Code)
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildOptionCard(
                      context,
                      badgeText: 'STARTING FRESH',
                      title: "I'm Starting Our Journey",
                      description: 'First one here? Build your couple profile and generate a love-code to invite your partner.',
                      icon: Icons.favorite_border_rounded,
                      actionText: 'Create Code',
                      isPrimary: false,
                      highlighted: false,
                      onTap: () {
                        VibrationService.medium();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateCoupleScreen(userName: resolvedName)),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  FadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.success.withValues(alpha: 0.6), size: 16),
                          const SizedBox(height: 4),
                          Text(
                            'ENCRYPTED & PRIVATE COUPLING',
                            style: AppTextStyles.bodyS.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.textMuted,
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
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String badgeText,
    required String title,
    required String description,
    required IconData icon,
    required String actionText,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool highlighted,
  }) {
    final cardBg = isPrimary ? const Color(0xFF1E1E2C) : Colors.white;
    final titleColor = isPrimary ? Colors.white : AppColors.textPrimary;
    final descColor = isPrimary ? Colors.white70 : AppColors.textSecondary;
    final actionColor = isPrimary ? Colors.white : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: isPrimary ? AppColors.deepShadow : AppColors.premiumShadow,
          border: highlighted
              ? Border.all(color: AppColors.primary, width: 2)
              : (isPrimary ? null : Border.all(color: AppColors.divider.withValues(alpha: 0.7))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isPrimary ? Colors.white.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : AppColors.primary,
                    size: 26,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? (highlighted ? AppColors.primary : Colors.white.withValues(alpha: 0.12))
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              description,
              style: AppTextStyles.bodyM.copyWith(
                color: descColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: actionColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
