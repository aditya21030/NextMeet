import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

enum MascotColor { pink, violet, butter, mint }
enum MascotAccessory { none, partyHat, cap, crown }

/// Kawaii Heart Mascot Widget with Expressive Faces & Accessories
/// Strictly following NextMeet Design System (Page 85 & 86)
class MascotHeart extends StatelessWidget {
  final MascotColor color;
  final double size;
  final bool leanRight;
  final bool leanLeft;
  final MascotAccessory accessory;
  final bool isWinking;

  const MascotHeart({
    super.key,
    this.color = MascotColor.pink,
    this.size = 64.0,
    this.leanRight = false,
    this.leanLeft = false,
    this.accessory = MascotAccessory.none,
    this.isWinking = false,
  });

  Color get _fillColor {
    switch (color) {
      case MascotColor.pink:
        return AppColors.you;
      case MascotColor.violet:
        return AppColors.partnerLight;
      case MascotColor.butter:
        return AppColors.butter;
      case MascotColor.mint:
        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    double rotation = 0.0;
    if (leanRight) rotation = 0.12; // ~7 degrees
    if (leanLeft) rotation = -0.12;

    final bool hasAccessory = accessory != MascotAccessory.none;
    final double accessoryHeadroom = hasAccessory ? size * 0.32 : 0.0;

    return Padding(
      padding: EdgeInsets.only(top: accessoryHeadroom),
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _HeartMascotPainter(
                  fillColor: _fillColor,
                  isWinking: isWinking,
                ),
              ),
              if (hasAccessory)
                Positioned(
                  top: -size * 0.22,
                  child: _buildAccessory(size),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessory(double s) {
    switch (accessory) {
      case MascotAccessory.partyHat:
        return CustomPaint(
          size: Size(s * 0.35, s * 0.35),
          painter: _PartyHatPainter(),
        );
      case MascotAccessory.crown:
        return CustomPaint(
          size: Size(s * 0.45, s * 0.3),
          painter: _CrownPainter(),
        );
      case MascotAccessory.cap:
        return CustomPaint(
          size: Size(s * 0.4, s * 0.25),
          painter: _CapPainter(),
        );
      case MascotAccessory.none:
        return const SizedBox.shrink();
    }
  }
}

class _HeartMascotPainter extends CustomPainter {
  final Color fillColor;
  final bool isWinking;

  _HeartMascotPainter({
    required this.fillColor,
    required this.isWinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Heart Body
    final path = Path();
    path.moveTo(w / 2, h * 0.88);
    path.cubicTo(w * 0.1, h * 0.65, 0, h * 0.35, 0, h * 0.25);
    path.cubicTo(0, h * 0.05, w * 0.25, 0, w / 2, h * 0.25);
    path.cubicTo(w * 0.75, 0, w, h * 0.05, w, h * 0.25);
    path.cubicTo(w, h * 0.35, w * 0.9, h * 0.65, w / 2, h * 0.88);
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Draw Kawaii Cheeks (Blush)
    final blushPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.22, h * 0.48), width: w * 0.16, height: h * 0.1),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.78, h * 0.48), width: w * 0.16, height: h * 0.1),
      blushPaint,
    );

    // 3. Draw Eyes (Ink)
    final eyePaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill;

    // Left Eye
    canvas.drawCircle(Offset(w * 0.34, h * 0.42), w * 0.055, eyePaint);
    // Eye shine
    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.32, h * 0.40), w * 0.02, shinePaint);

    // Right Eye
    if (isWinking) {
      final winkPaint = Paint()
        ..color = AppColors.ink
        ..strokeWidth = w * 0.04
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final winkPath = Path();
      winkPath.moveTo(w * 0.61, h * 0.44);
      winkPath.quadraticBezierTo(w * 0.66, h * 0.38, w * 0.71, h * 0.44);
      canvas.drawPath(winkPath, winkPaint);
    } else {
      canvas.drawCircle(Offset(w * 0.66, h * 0.42), w * 0.055, eyePaint);
      canvas.drawCircle(Offset(w * 0.64, h * 0.40), w * 0.02, shinePaint);
    }

    // 4. Draw Smile Mouth (Ink)
    final mouthPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = w * 0.045
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    mouthPath.moveTo(w * 0.44, h * 0.49);
    mouthPath.quadraticBezierTo(w * 0.50, h * 0.55, w * 0.56, h * 0.49);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _HeartMascotPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor || oldDelegate.isWinking != isWinking;
}

class _PartyHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hatPath = Path();
    hatPath.moveTo(w / 2, 0);
    hatPath.lineTo(w, h);
    hatPath.lineTo(0, h);
    hatPath.close();

    final hatPaint = Paint()..color = AppColors.butter;
    canvas.drawPath(hatPath, hatPaint);

    final borderPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(hatPath, borderPaint);

    // Pom-pom at top
    canvas.drawCircle(Offset(w / 2, 0), 3, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final crownPath = Path();
    crownPath.moveTo(0, h);
    crownPath.lineTo(0, h * 0.3);
    crownPath.lineTo(w * 0.25, h * 0.6);
    crownPath.lineTo(w * 0.5, 0);
    crownPath.lineTo(w * 0.75, h * 0.6);
    crownPath.lineTo(w, h * 0.3);
    crownPath.lineTo(w, h);
    crownPath.close();

    final crownPaint = Paint()..color = AppColors.butter;
    canvas.drawPath(crownPath, crownPaint);

    final strokePaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(crownPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final domePath = Path();
    domePath.moveTo(w * 0.1, h);
    domePath.quadraticBezierTo(w * 0.5, 0, w * 0.9, h);
    domePath.close();

    canvas.drawPath(domePath, Paint()..color = AppColors.blue);
    canvas.drawPath(
      domePath,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Visor
    final visorPath = Path();
    visorPath.moveTo(w * 0.2, h);
    visorPath.quadraticBezierTo(w * 0.6, h * 1.2, w, h * 0.85);
    canvas.drawPath(
      visorPath,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The Iconic Leaning Two Hearts Lockup (Pink & Violet)
class TwoMascotsRow extends StatelessWidget {
  final double size;
  final MascotColor leftColor;
  final MascotColor rightColor;
  final MascotAccessory leftAccessory;
  final MascotAccessory rightAccessory;
  final double spacing;

  const TwoMascotsRow({
    super.key,
    this.size = 80.0,
    this.leftColor = MascotColor.pink,
    this.rightColor = MascotColor.violet,
    this.leftAccessory = MascotAccessory.none,
    this.rightAccessory = MascotAccessory.none,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MascotHeart(
          color: leftColor,
          size: size,
          leanRight: true,
          accessory: leftAccessory,
        ),
        SizedBox(width: spacing),
        MascotHeart(
          color: rightColor,
          size: size,
          leanLeft: true,
          accessory: rightAccessory,
        ),
      ],
    );
  }
}

/// NextMeet Flat Card Component with 1.5px Border & Zero Shadow
class NextMeetCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const NextMeetCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius = AppRadius.card,
    this.padding = const EdgeInsets.all(AppSpacing.page),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderWidth,
        ),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}

/// Reusable Tag Chip Component (Page 86)
class TagChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor ?? AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}

/// Stat Metric Tile (e.g. "Together 2y 8m", "8,400 km")
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: iconColor ?? AppColors.partner),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.label.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.heading.copyWith(
                fontSize: 16,
                color: AppColors.ink,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
