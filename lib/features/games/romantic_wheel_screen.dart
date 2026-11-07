import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_relationship_service.dart';
import '../../core/services/couple_game_service.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';
import '../../widgets/primary_button.dart';

/// NextMeet Romantic Wheel of Dates
/// Real-time synchronized couple spinning wheel for date night decisions & sweet dares.
class RomanticWheelScreen extends StatefulWidget {
  final String? relId;
  final String? partnerName;
  const RomanticWheelScreen({super.key, this.relId, this.partnerName});

  @override
  State<RomanticWheelScreen> createState() => _RomanticWheelScreenState();
}

class _RomanticWheelScreenState extends State<RomanticWheelScreen> with SingleTickerProviderStateMixin {
  final CoupleGameService _gameService = CoupleGameService();
  final CloudRelationshipService _cloudService = CloudRelationshipService();

  late AnimationController _animController;
  late Animation<double> _spinAnimation;

  late bool _isOnlineMode;
  bool _isSpinning = false;
  double _currentAngle = 0.0;
  int _lastSpinTimestamp = 0;

  final List<Map<String, dynamic>> _sectors = [
    {'title': '15-Min Massage', 'emoji': '💆', 'color': AppColors.primary, 'desc': 'Trade a relaxing 15-minute shoulder or foot massage next reunion!'},
    {'title': 'Cook Dinner', 'emoji': '🍳', 'color': AppColors.partner, 'desc': 'Cook or order the same recipe over video call tonight!'},
    {'title': 'Stargazing Call', 'emoji': '🌌', 'color': AppColors.mintText, 'desc': 'Step outside at night and look at the moon together while on voice call.'},
    {'title': 'Whisper 3 Secrets', 'emoji': '🤫', 'color': AppColors.butterText, 'desc': 'Send a 15-second voice whisper revealing 3 tiny secrets.'},
    {'title': 'Slow Dance', 'emoji': '💃', 'color': AppColors.primary, 'desc': 'Put on our song and slow dance together over video call.'},
    {'title': 'Dessert Surprise', 'emoji': '🍰', 'color': AppColors.partner, 'desc': 'Surprise order your partner their favorite dessert on food delivery!'},
    {'title': 'Love Poem', 'emoji': '✍️', 'color': AppColors.mintText, 'desc': 'Write a 4-line silly or sweet rhyming love poem right now.'},
    {'title': 'Virtual Movie Night', 'emoji': '🍿', 'color': AppColors.butterText, 'desc': 'Pop popcorn and watch a movie sync together this weekend.'},
  ];

  @override
  void initState() {
    super.initState();
    _lastSpinTimestamp = DateTime.now().millisecondsSinceEpoch;
    _isOnlineMode = widget.relId != null && widget.relId!.isNotEmpty;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _spinToTarget(int targetIndex, String challengeTitle, {bool triggerCloud = false}) {
    if (_isSpinning) return;
    setState(() => _isSpinning = true);
    VibrationService.heavy();

    final sectorAngle = (2 * math.pi) / _sectors.length;
    // Align indicator at top (angle -pi/2)
    final targetSectorCenter = targetIndex * sectorAngle + (sectorAngle / 2);
    final fullSpins = 5 + math.Random().nextInt(3);
    final targetFinalAngle = (fullSpins * 2 * math.pi) + (2 * math.pi - targetSectorCenter) - (math.pi / 2);

    _spinAnimation = Tween<double>(begin: _currentAngle, end: _currentAngle + targetFinalAngle).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _currentAngle = (_currentAngle + targetFinalAngle) % (2 * math.pi);
        _isSpinning = false;
      });
      VibrationService.success();
      _showResultModal(_sectors[targetIndex]);
    });

    if (triggerCloud && _isOnlineMode && widget.relId != null) {
      final myName = AuthService().currentUser?.displayName ?? 'You';
      _gameService.spinWheel(widget.relId!, targetIndex, challengeTitle, myName);
      _cloudService.addCoupleXp(widget.relId!, 50);
    }
  }

  void _onSpinPressed() {
    if (_isSpinning) return;
    _lastSpinTimestamp = DateTime.now().millisecondsSinceEpoch;
    final randomTarget = math.Random().nextInt(_sectors.length);
    final challenge = _sectors[randomTarget]['title'] as String;
    _spinToTarget(randomTarget, challenge, triggerCloud: true);
  }

  void _showResultModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(item['emoji'] as String, style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 12),
            Text(item['title'] as String, style: AppTextStyles.title1.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              item['desc'] as String,
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Accept Challenge! 🎉',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relId = widget.relId;
    final pName = widget.partnerName ?? 'Partner';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (_isOnlineMode && relId != null) ? _gameService.streamWheel(relId) : const Stream.empty(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (data != null) {
          final timestamp = (data['spinTimestamp'] as num?)?.toInt() ?? 0;
          if (timestamp > _lastSpinTimestamp && timestamp > 0) {
            _lastSpinTimestamp = timestamp;
            final targetIdx = (data['targetIndex'] as num?)?.toInt() ?? 0;
            final challengeTitle = data['challengeTitle'] as String? ?? '';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isSpinning) {
                _spinToTarget(targetIdx, challengeTitle, triggerCloud: false);
              }
            });
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink),
                        ),
                      ),
                      Text('Wheel of Dates', style: AppTextStyles.title2.copyWith(fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.pinkSoft,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          _isOnlineMode ? 'Live Sync ⚡' : 'Local 🎡',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Spin for your next romantic date or intimacy mini-dare with $pName!',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Wheel with Top Indicator Arrow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinning Wheel Canvas
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final angle = _animController.isAnimating ? _spinAnimation.value : _currentAngle;
                          return Transform.rotate(
                            angle: angle,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 310,
                          height: 310,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CustomPaint(
                              painter: _WheelPainter(sectors: _sectors),
                            ),
                          ),
                        ),
                      ),

                      // Center Hub Button
                      GestureDetector(
                        onTap: _isSpinning ? null : _onSpinPressed,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isSpinning ? '...' : 'SPIN',
                            style: AppTextStyles.heading.copyWith(fontSize: 14, color: AppColors.primary),
                          ),
                        ),
                      ),

                      // Top Indicator Arrow
                      Positioned(
                        top: -8,
                        child: Transform.rotate(
                          angle: math.pi,
                          child: const Icon(Icons.navigation_rounded, size: 36, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Spin Action Button
                  PrimaryButton(
                    text: _isSpinning ? 'Spinning together... 🎡' : 'Spin the Wheel ✨',
                    isLoading: _isSpinning,
                    onPressed: _onSpinPressed,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> sectors;
  _WheelPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / sectors.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < sectors.length; i++) {
      paint.color = i % 2 == 0 ? AppColors.pinkSoft : AppColors.partnerSoft;
      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw Emoji
      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius * 0.72;
      final x = center.dx + (textRadius * math.cos(textAngle));
      final y = center.dy + (textRadius * math.sin(textAngle));

      final textPainter = TextPainter(
        text: TextSpan(
          text: sectors[i]['emoji'] as String,
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), y - (textPainter.height / 2)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
