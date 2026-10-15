import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/milestone_model.dart';
import '../core/services/vibration_service.dart';
// To reuse the Award Orb components if accessible, or I'll recreate a clean version here.

class MilestoneUnlockDialog extends StatelessWidget {
  final Milestone milestone;

  const MilestoneUnlockDialog({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    VibrationService.success();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main Card
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF16161E),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: milestone.color.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: milestone.color.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEW BADGE UNLOCKED!',
                    style: GoogleFonts.outfit(
                      color: milestone.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    milestone.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Text(
                            'NOT NOW',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [milestone.color, milestone.color.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: milestone.color.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Future: Navigate to achievements/share
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'CELEBRATE ✨',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // The Floating Badge (Orb)
          Positioned(
            top: -60,
            child: ElasticIn(
              delay: const Duration(milliseconds: 300),
              child: _UnlockBadgeOrb(milestone: milestone),
            ),
          ),
          
          // Particle/Sparkle Layer
          Positioned.fill(
            child: IgnorePointer(
              child: _SparkleLayer(color: milestone.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockBadgeOrb extends StatefulWidget {
  final Milestone milestone;
  const _UnlockBadgeOrb({required this.milestone});

  @override
  State<_UnlockBadgeOrb> createState() => _UnlockBadgeOrbState();
}

class _UnlockBadgeOrbState extends State<_UnlockBadgeOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.milestone.color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring
                Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.milestone.color.withValues(alpha: 0.5), width: 2),
                  ),
                ),
                // Inner Glow/Pattern
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [widget.milestone.color.withValues(alpha: 0.4), Colors.transparent],
                    ),
                  ),
                ),
                // Icon (Reverse rotating)
                Transform.rotate(
                  angle: -_controller.value * 2 * 3.14159,
                  child: Icon(widget.milestone.icon, color: Colors.white, size: 50),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SparkleLayer extends StatelessWidget {
  final Color color;
  const _SparkleLayer({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(12, (index) {
        return Positioned(
          left: (index % 4) * 80.0,
          top: (index / 4) * 100.0,
          child: ZoomIn(
            delay: Duration(milliseconds: 400 + (index * 100)),
            child: Icon(Icons.auto_awesome_rounded, color: color.withValues(alpha: 0.4), size: 12),
          ),
        );
      }),
    );
  }
}
