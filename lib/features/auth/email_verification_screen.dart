import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/tell_us_about_you_screen.dart';

/// NextMeet Email OTP Verification Screen
/// Strictly following NextMeet Redesign.pdf (Page 5)
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String? initialInviteCode;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    this.initialInviteCode,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<String> _enteredDigits = [];
  int _secondsRemaining = 30;
  Timer? _resendTimer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _secondsRemaining = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredDigits.length < 6) {
      VibrationService.light();
      setState(() {
        _enteredDigits.add(digit);
      });
      if (_enteredDigits.length == 6) {
        _handleVerify();
      }
    }
  }

  void _onBackspace() {
    if (_enteredDigits.isNotEmpty) {
      VibrationService.light();
      setState(() {
        _enteredDigits.removeLast();
      });
    }
  }

  Future<void> _handleVerify() async {
    setState(() => _isVerifying = true);
    VibrationService.medium();

    // Simulating verification / processing
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isVerifying = false);
    VibrationService.success();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TellUsAboutYouScreen(
          initialName: widget.name,
          initialInviteCode: widget.initialInviteCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerText = '0:${_secondsRemaining.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Envelope with Heart Seal Illustration (Page 5)
                    Center(
                      child: Container(
                        width: 140,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Envelope flap lines
                            CustomPaint(
                              size: const Size(140, 100),
                              painter: _EnvelopePainter(),
                            ),
                            // Pink heart seal
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

                    const SizedBox(height: 24),

                    Text(
                      'Check your email',
                      style: AppTextStyles.display.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We sent a 6-digit code to ${widget.email}',
                      style: AppTextStyles.body.copyWith(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // 6 OTP Code Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final hasDigit = index < _enteredDigits.length;
                        final isFocused = index == _enteredDigits.length;
                        final digit = hasDigit ? _enteredDigits[index] : '';

                        return Container(
                          width: 44,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? AppColors.primary
                                  : (hasDigit ? AppColors.ink : AppColors.border),
                              width: isFocused ? 2.0 : 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: AppTextStyles.display.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    // Resend Timer
                    if (_secondsRemaining > 0)
                      Text(
                        'Resend code in $timerText',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          _startResendTimer();
                          VibrationService.light();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('A new 6-digit code has been sent.')),
                          );
                        },
                        child: Text(
                          'Resend code now',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Verify Button
                    PrimaryButton(
                      text: 'Verify',
                      isLoading: _isVerifying,
                      onPressed: _handleVerify,
                    ),

                    const SizedBox(height: 12),

                    // Wrong email? Change it
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Wrong email? Change it',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Custom Tactile Numeric Keypad (Page 5)
            _buildNumericKeypad(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _keyButton('1'),
              const SizedBox(width: 12),
              _keyButton('2'),
              const SizedBox(width: 12),
              _keyButton('3'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _keyButton('4'),
              const SizedBox(width: 12),
              _keyButton('5'),
              const SizedBox(width: 12),
              _keyButton('6'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _keyButton('7'),
              const SizedBox(width: 12),
              _keyButton('8'),
              const SizedBox(width: 12),
              _keyButton('9'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: SizedBox(height: 52)),
              const SizedBox(width: 12),
              _keyButton('0'),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _onBackspace,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Icon(Icons.backspace_outlined, color: AppColors.ink, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyButton(String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPress(text),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTextStyles.title1.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(w / 2, h * 0.55);
    path.lineTo(w, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
