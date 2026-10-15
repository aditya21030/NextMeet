import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/constants.dart';

class LoveConstellation extends StatefulWidget {
  final Map<DateTime, int> activityData;
  final int year;
  final bool showTitle;
  final bool showLegend;

  const LoveConstellation({
    super.key,
    required this.activityData,
    this.year = 2026,
    this.showTitle = true,
    this.showLegend = true,
  });

  @override
  State<LoveConstellation> createState() => _LoveConstellationState();
}

class _LoveConstellationState extends State<LoveConstellation> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<StarNode> _stars = [];
      // ignore: unused_field
  final math.Random _random = math.Random(42); // Seed for consistency

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _generateStars();
  }

  void _generateStars() {
    _stars.clear();
    // Generate star positions for each day of the year (or just the active ones)
    // For a more aesthetic look, we spread them across a coordinate space
    final now = DateTime.now();
    final startOfYear = DateTime(widget.year, 1, 1);
    final daysInYear = DateTime(widget.year, 12, 31).difference(startOfYear).inDays + 1;

    for (int i = 0; i < daysInYear; i++) {
      final date = startOfYear.add(Duration(days: i));
      if (date.isAfter(now)) continue;

      final activityLevel = widget.activityData[DateTime(date.year, date.month, date.day)] ?? 0;
      if (activityLevel > 0) {
        // Deterministic position based on day index
        final r = math.Random(i + widget.year);
        _stars.add(StarNode(
          date: date,
          x: r.nextDouble(),
          y: r.nextDouble(),
          intensity: activityLevel,
        ));
      }
    }
    
    // Sort stars by date to connect them in order
    _stars.sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  void didUpdateWidget(LoveConstellation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityData.length != widget.activityData.length) {
      _generateStars();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Love Map ✨', style: AppTextStyles.h3),
              if (widget.showLegend)
                Text('Your Constellation', style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        if (widget.showTitle) const SizedBox(height: AppSpacing.m),
        AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Deep Night Blue
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10)),
              ],
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
                center: Alignment.center,
                radius: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ConstellationPainter(
                        stars: _stars,
                        pulse: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StarNode {
  final DateTime date;
  final double x;
  final double y;
  final int intensity;

  StarNode({required this.date, required this.x, required this.y, required this.intensity});
}

class ConstellationPainter extends CustomPainter {
  final List<StarNode> stars;
  final double pulse;

  ConstellationPainter({required this.stars, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    if (stars.isEmpty) {
      _drawPlaceholder(canvas, size);
      return;
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final starPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;

    // 1. Draw Connection Lines
    final Path path = Path();
    for (int i = 0; i < stars.length; i++) {
      final p = Offset(stars[i].x * size.width, stars[i].y * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // 2. Draw Stars with Glow
    for (final star in stars) {
      final pos = Offset(star.x * size.width, star.y * size.height);
      final double baseSize = 2.5 + (star.intensity * 1.5);
      final double currentSize = baseSize + (math.sin(pulse * math.pi * 2) * 0.8);
      
      // Glow effect
      final glowSize = currentSize * 4.0;
      final glowGradient = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4 * (0.8 + math.sin(pulse * math.pi * 2) * 0.2)),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
      
      glowPaint.shader = glowGradient.createShader(Rect.fromCircle(center: pos, radius: glowSize));
      canvas.drawCircle(pos, glowSize, glowPaint);

      // Core Star
      starPaint.color = Colors.white;
      canvas.drawCircle(pos, currentSize, starPaint);
      
      // Secondary Primary Tint Glow
      final primaryGlow = currentSize * 2.0;
      glowPaint.shader = RadialGradient(
        colors: [
           AppColors.primary.withValues(alpha: 0.3),
           AppColors.primary.withValues(alpha: 0.0),
        ]
      ).createShader(Rect.fromCircle(center: pos, radius: primaryGlow));
      canvas.drawCircle(pos, primaryGlow, glowPaint);
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Your star constellation will form here\nas you build memories together ✨',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.5),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width - 40);
    
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(ConstellationPainter oldDelegate) => true;
}
