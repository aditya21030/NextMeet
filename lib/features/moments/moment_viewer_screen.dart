import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/services/vibration_service.dart';
import '../../widgets/flat_components.dart';

/// NextMeet Fullscreen Moment Viewer Screen
/// Strictly following NextMeet Redesign.pdf (Page 29)
class MomentViewerScreen extends StatefulWidget {
  final String authorName;
  final String caption;
  final MascotColor color;

  const MomentViewerScreen({
    super.key,
    required this.authorName,
    required this.caption,
    required this.color,
  });

  @override
  State<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends State<MomentViewerScreen> {
  final TextEditingController _replyController = TextEditingController();
  final List<Widget> _particles = [];
  final List<String> _reactions = ['❤️', '🤗', '⭐️', '🔥', '🥰'];
  final List<Timer> _activeTimers = [];

  @override
  void dispose() {
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
    _replyController.dispose();
    super.dispose();
  }

  void _triggerParticle(String emoji) {
    VibrationService.light();
    final random = math.Random();
    final key = UniqueKey();

    final particle = Positioned(
      key: key,
      bottom: 120 + (random.nextDouble() * 60),
      left: 40 + (random.nextDouble() * 260),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        builder: (context, val, child) {
          return Opacity(
            opacity: 1.0 - val,
            child: Transform.translate(
              offset: Offset(0, -val * 120),
              child: Transform.scale(
                scale: 1.0 + (val * 0.8),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
          );
        },
      ),
    );

    setState(() => _particles.add(particle));
    late final Timer timer;
    timer = Timer(const Duration(milliseconds: 1000), () {
      _activeTimers.remove(timer);
      if (mounted) {
        setState(() => _particles.remove(particle));
      }
    });
    _activeTimers.add(timer);
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    VibrationService.medium();
    _replyController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent reply to ${widget.authorName}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Photo Display Canvas
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
                decoration: BoxDecoration(
                  color: widget.color == MascotColor.pink ? AppColors.pinkSoft : AppColors.partnerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MascotHeart(color: widget.color, size: 120),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.caption,
                          style: AppTextStyles.title2.copyWith(
                            color: widget.color == MascotColor.pink ? AppColors.primary : AppColors.partnerText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Header Bar
            Positioned(
              top: 12,
              left: AppSpacing.page,
              right: AppSpacing.page,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      MascotHeart(color: widget.color, size: 36),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.authorName, style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 15)),
                          Text('Today, 2:15 PM', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Reactions Overlay
            ..._particles,

            // Bottom Reactions & Reply Bar (Page 29)
            Positioned(
              bottom: 12,
              left: AppSpacing.page,
              right: AppSpacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Reactions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _reactions.map((emoji) {
                      return GestureDetector(
                        onTap: () => _triggerParticle(emoji),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Quick Reply Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: AppTextStyles.body.copyWith(color: AppColors.ink),
                            decoration: InputDecoration(
                              hintText: 'Reply to ${widget.authorName}...',
                              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _sendReply(),
                          ),
                        ),
                        IconButton(
                          onPressed: _sendReply,
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
