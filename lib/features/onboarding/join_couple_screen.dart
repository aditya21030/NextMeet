import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/cloud_relationship_service.dart';
import 'connection_success_screen.dart';
import '../../core/services/auth_error_handler.dart';

class JoinCoupleScreen extends StatefulWidget {
  final String? userName;
  final String? initialCode;
  const JoinCoupleScreen({super.key, this.userName, this.initialCode});

  @override
  State<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends State<JoinCoupleScreen> {
  final _pinController = TextEditingController();
  final CloudRelationshipService _cloudService = CloudRelationshipService();
  final _focusNode = FocusNode();
  bool _isConnecting = false;
  bool _isCodeAutoDetected = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _pinController.text = widget.initialCode!;
      _isCodeAutoDetected = true;
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
            _isCodeAutoDetected = true;
          });
          VibrationService.light();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    final code = _pinController.text.trim();
    if (code.length != 6) {
      VibrationService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the invite code ❤️'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);
    VibrationService.medium();

    try {
      final rel = await _cloudService.joinJourney(
        code,
        'Our City',
        widget.userName ?? 'Partner',
        'Love',
      );

      if (!mounted) return;
      setState(() => _isConnecting = false);

      if (rel != null) {
        VibrationService.success();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectionSuccessScreen(relationship: rel),
          ),
        );
      } else {
        VibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find an active invite with this code. Please check with your partner ❤️'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      VibrationService.error();
      final friendlyMsg = AuthErrorHandler.getPairingErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMsg),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: AppTextStyles.display.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 2.0),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Mascots Header
              const Center(
                child: TwoMascotsRow(size: 88, spacing: 14),
              ),

              const SizedBox(height: 20),

              Text(
                'Enter invite code',
                style: AppTextStyles.display.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Ask your partner for their 6-digit NextMeet code.',
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              if (_isCodeAutoDetected) ...[
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, color: AppColors.mintText, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Code auto-detected from clipboard',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mintText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Pinput Box
              Center(
                child: Pinput(
                  controller: _pinController,
                  focusNode: _focusNode,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (_) => _handleJoin(),
                ),
              ),

              const SizedBox(height: 32),

              // Connect Button
              PrimaryButton(
                text: 'Connect to our space',
                isLoading: _isConnecting,
                onPressed: _handleJoin,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
