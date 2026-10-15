import 'dart:async';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/cloud_relationship_service.dart';
import 'connection_success_screen.dart';

class JoinCoupleScreen extends StatefulWidget {
  final String? userName;
  final String? initialCode;
  const JoinCoupleScreen({super.key, this.userName, this.initialCode});

  @override
  State<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends State<JoinCoupleScreen> {
  final _pinController = TextEditingController();
  final _partnerPetNameController = TextEditingController(); // Your nickname for partner
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final _focusNode = FocusNode();
  final String _selectedCity = 'Remote';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _pinController.text = widget.initialCode!;
    } else {
      _checkClipboardForCode();
    }
  }

  Future<void> _checkClipboardForCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        final match = RegExp(r'\b\d{6}\b').firstMatch(text);
        if (match != null && mounted) {
          final code = match.group(0)!;
          setState(() {
            _pinController.text = code;
          });
          VibrationService.light();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found invite code $code from clipboard! ✨'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pinController.dispose();
    _partnerPetNameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    if (_pinController.text.length < 6) {
      VibrationService.error();
      return;
    }

    setState(() => _isSearching = true);
    VibrationService.medium();
    
    try {
      final relationship = await _cloudService.joinJourney(
        _pinController.text, 
        _selectedCity,
        widget.userName ?? 'Partner',
        _partnerPetNameController.text.trim().isEmpty ? 'Partner' : _partnerPetNameController.text.trim(),
      );
      
      if (mounted) {
        if (relationship != null) {
          VibrationService.success();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ConnectionSuccessScreen()),
          );
        } else {
          setState(() => _isSearching = false);
          VibrationService.error();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid code or connection expired ❤️')),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
      VibrationService.error();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 44,
      height: 50,
      textStyle: AppTextStyles.h2.copyWith(color: AppColors.primary, fontSize: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            bottom: -50,
            left: -50,
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  FadeInLeft(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect Hearts ❤️', style: AppTextStyles.h1.copyWith(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'Join your partner\'s journey with the secret code.',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Pin Card First (Zero Friction)
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        boxShadow: AppColors.softShadow,
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Love Invite Code',
                                style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Enter the 6-digit code shared by your partner',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const Divider(height: 32, color: AppColors.divider),
                          const SizedBox(height: AppSpacing.m),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Pinput(
                              length: 6,
                              controller: _pinController,
                              focusNode: _focusNode,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              hapticFeedbackType: HapticFeedbackType.mediumImpact,
                              onCompleted: (pin) => _handleJoin(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Optional Partner Nickname
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildInteractiveCard(
                      title: 'Partner Nickname (Optional)',
                      subtitle: 'A sweet nickname just for you ❤️',
                      icon: Icons.favorite_outline_rounded,
                      child: TextField(
                        controller: _partnerPetNameController,
                        style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'e.g. My Soulmate',
                          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),

                  if (_isSearching)
                    FadeInUp(
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'Syncing your hearts...',
                              style: AppTextStyles.bodyM.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: PrimaryButton(
                        text: 'Connect Hearts ✨',
                        onPressed: _handleJoin,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Don't have a code? Create journey",
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildInteractiveCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
            ),
            const Divider(height: 32, color: AppColors.divider),
            child,
          ],
        ),
      ),
    );
  }
}
