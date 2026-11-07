import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Heartbeat Sync Fullscreen Experience
/// Strictly following NextMeet Redesign.pdf (Page 19)
class HeartbeatSyncModal extends StatefulWidget {
  final String partnerName;
  const HeartbeatSyncModal({super.key, this.partnerName = 'Partner'});

  @override
  State<HeartbeatSyncModal> createState() => _HeartbeatSyncModalState();
}

class _HeartbeatSyncModalState extends State<HeartbeatSyncModal> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _hapticTimer;
  Timer? _durationTimer;
  int _secondsElapsed = 12;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Synchronized heartbeat double-pulse haptics
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      VibrationService.light();
      Future.delayed(const Duration(milliseconds: 150), () {
        VibrationService.medium();
      });
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hapticTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  String get _formattedDuration {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(1, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Immersive Glowing Pink Canvas (Page 19)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Close (X) button and Header Title
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
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  Text(
                    'Heartbeat sync',
                    style: AppTextStyles.title2.copyWith(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pulsing Concentric Glowing Circles with Center White Heart (Page 19)
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow circle
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    // Mid glow circle
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    // Inner glow circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    // Center Heart
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mascots Smiling at Bottom of Radial Pulse (Page 19)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotHeart(color: MascotColor.pink, size: 84, leanRight: true),
                const SizedBox(width: 48),
                const MascotHeart(color: MascotColor.violet, size: 84, leanLeft: true),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Hearts in sync',
              style: AppTextStyles.display.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Both of you are holding right now',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Animated ECG Line Pulse
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomPaint(
                size: const Size(double.infinity, 36),
                painter: _EcWavePainter(),
              ),
            ),

            const SizedBox(height: 20),

            // Stats Pill: "You 72 bpm" | "Partner 74 bpm" | "0:12" (Page 19)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'You 72 bpm',
                      style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.ink),
                    ),
                    Container(width: 1, height: 16, color: AppColors.border),
                    Text(
                      '${widget.partnerName} 74 bpm',
                      style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.ink),
                    ),
                    Container(width: 1, height: 16, color: AppColors.border),
                    Text(
                      _formattedDuration,
                      style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // "Let go" Button (White Pill, Page 19)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () {
                  VibrationService.light();
                  Navigator.pop(context);
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Let go',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
}

class _EcWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, h * 0.5);
    path.lineTo(w * 0.4, h * 0.5);
    path.lineTo(w * 0.44, h * 0.2);
    path.lineTo(w * 0.48, h * 0.85);
    path.lineTo(w * 0.52, h * 0.35);
    path.lineTo(w * 0.56, h * 0.65);
    path.lineTo(w * 0.6, h * 0.5);
    path.lineTo(w, h * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
