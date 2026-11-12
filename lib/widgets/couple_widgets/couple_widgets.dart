import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flat_components.dart';

Widget _withClampedTextScale(BuildContext context, Widget child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.12),
    ),
    child: child,
  );
}

/// Available Color Palettes for Widgets (from WIDGET_SPEC.md)
enum WidgetPalette { pink, violet, butter, mint, ink }

class WidgetPaletteColors {
  final Color primary;
  final Color accent;
  final Color subtext;
  final Color track;
  final Color fill;
  final Color text;

  const WidgetPaletteColors({
    required this.primary,
    required this.accent,
    required this.subtext,
    required this.track,
    required this.fill,
    required this.text,
  });

  static WidgetPaletteColors of(WidgetPalette palette) {
    switch (palette) {
      case WidgetPalette.pink:
        return const WidgetPaletteColors(
          primary: Color(0xFFD81B6A),
          accent: Color(0xFFE8478A),
          subtext: Color(0xFFFFEEF5),
          track: Color(0xFFE8478A),
          fill: Color(0xFFFFD66B),
          text: Colors.white,
        );
      case WidgetPalette.violet:
        return const WidgetPaletteColors(
          primary: Color(0xFF7B5CF0),
          accent: Color(0xFF9B87F5),
          subtext: Color(0xFFF3EEFF),
          track: Color(0xFF9B87F5),
          fill: Color(0xFFFFD66B),
          text: Colors.white,
        );
      case WidgetPalette.butter:
        return const WidgetPaletteColors(
          primary: Color(0xFFFFD66B),
          accent: Color(0xFFFFE7A3),
          subtext: Color(0xFF5C4300),
          track: Color(0xFFFFE7A3),
          fill: Color(0xFFD81B6A),
          text: Color(0xFF2B1B26),
        );
      case WidgetPalette.mint:
        return const WidgetPaletteColors(
          primary: Color(0xFF6FCFA0),
          accent: Color(0xFF8DDCB8),
          subtext: Color(0xFF1B4D37),
          track: Color(0xFF8DDCB8),
          fill: Colors.white,
          text: Color(0xFF2B1B26),
        );
      case WidgetPalette.ink:
        return const WidgetPaletteColors(
          primary: Color(0xFF2B1B26),
          accent: Color(0xFF4A3A44),
          subtext: Color(0xFFFFC2D9),
          track: Color(0xFF4A3A44),
          fill: Color(0xFFFFD66B),
          text: Colors.white,
        );
    }
  }
}

// ============================================================================
// 1. DISTANCE & BATTERY WIDGET (Medium 4x2: 358 x 174)
// ============================================================================

enum DistanceBatteryState { normal, lowBattery, asleep }

class DistanceBatteryWidget extends StatelessWidget {
  final String distance;
  final String fromCity;
  final String toCity;
  final String partnerName;
  final int battery;
  final String timeText;
  final DistanceBatteryState state;
  final VoidCallback? onTap;

  const DistanceBatteryWidget({
    super.key,
    this.distance = '8,420 km',
    this.fromCity = 'Chennai',
    this.toCity = 'Frankfurt',
    this.partnerName = 'Rahul',
    this.battery = 64,
    this.timeText = 'CET, 9:42 PM',
    this.state = DistanceBatteryState.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int displayBattery = (state == DistanceBatteryState.lowBattery
            ? 12
            : (state == DistanceBatteryState.asleep ? 88 : battery))
        .clamp(0, 100);
    final String displayTime = state == DistanceBatteryState.asleep ? 'CET, 2:10 AM' : timeText;
    final Color batteryBarColor = state == DistanceBatteryState.lowBattery
        ? const Color(0xFFD13A4F)
        : const Color(0xFF6FCFA0);

    return _withClampedTextScale(
      context,
      GestureDetector(
      onTap: onTap,
      child: Container(
        width: 358,
        height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
        ),
        child: Stack(
          children: [
            // Left Column: Distance & Flight Arc
            Positioned(
              left: 16,
              top: 14,
              child: Text(
                'DISTANCE',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7A6672),
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 30,
              child: SizedBox(
                width: 170,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    distance,
                    style: GoogleFonts.nunito(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: const Color(0xFFD81B6A),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 82,
              child: SizedBox(
                width: 170,
                height: 40,
                child: CustomPaint(
                  painter: _FlightArcPainter(),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 132,
              child: SizedBox(
                width: 170,
                child: Text(
                  '$fromCity to $toCity',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A6672),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Dashed Vertical Divider
            Positioned(
              left: 196,
              top: 16,
              bottom: 16,
              child: CustomPaint(
                painter: _DashedLinePainter(
                  color: const Color(0xFFF1D3E0),
                  dashWidth: 4,
                  dashSpace: 4,
                ),
              ),
            ),

            // Right Column: Partner Status
            Positioned(
              left: 214,
              right: 12,
              top: 14,
              child: Row(
                children: [
                  const MascotHeart(
                    color: MascotColor.violet,
                    size: 38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partnerName,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2B1B26),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 214,
              top: 64,
              child: Row(
                children: [
                  // Battery Shell
                  Container(
                    width: 54,
                    height: 22,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2B1B26), width: 2.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (displayBattery.clamp(5, 100)) / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: batteryBarColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 3.5,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2B1B26),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$displayBattery%',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2B1B26),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 214,
              right: 12,
              top: 98,
              child: Text(
                displayTime,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7A6672),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              left: 214,
              right: 12,
              top: 126,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusPill(state),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusPill(DistanceBatteryState state) {
    String text;
    Color bg;
    Color fg;

    switch (state) {
      case DistanceBatteryState.normal:
        text = 'Online now';
        bg = const Color(0xFFE3F6EC);
        fg = const Color(0xFF1F7A4F);
        break;
      case DistanceBatteryState.lowBattery:
        text = 'Low battery';
        bg = const Color(0xFFFFE0E3);
        fg = const Color(0xFFB3263E);
        break;
      case DistanceBatteryState.asleep:
        text = 'Probably asleep';
        bg = const Color(0xFFEDE4FF);
        fg = const Color(0xFF4B3A8C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ============================================================================
// 2. LIVE HEARTBEAT SYNC WIDGET (Small 2x2: 174 x 174)
// ============================================================================

enum HeartbeatWidgetState { touching, idle, offline }

class HeartbeatSyncWidget extends StatelessWidget {
  final String partnerName;
  final int bpm;
  final HeartbeatWidgetState state;
  final VoidCallback? onTap;

  const HeartbeatSyncWidget({
    super.key,
    this.partnerName = 'Rahul',
    this.bpm = 74,
    this.state = HeartbeatWidgetState.touching,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color ambientColor;
    Color headerColor;
    Color r1Color;
    Color r2Color;
    Color r3Color;
    Color heartColor;
    String line1;
    String line2;
    Color line1Color;
    Color line2Color;

    switch (state) {
      case HeartbeatWidgetState.touching:
        bg = const Color(0xFFD81B6A);
        ambientColor = const Color(0xFFE8478A);
        headerColor = const Color(0xFFFFD6E7);
        r1Color = const Color(0xFFE8478A);
        r2Color = const Color(0xFFEE5C9A);
        r3Color = Colors.white;
        heartColor = const Color(0xFFD81B6A);
        line1 = '$partnerName is here';
        line2 = '$bpm bpm, live';
        line1Color = Colors.white;
        line2Color = const Color(0xFFFFD6E7);
        break;
      case HeartbeatWidgetState.idle:
        bg = const Color(0xFFFFE0ED);
        ambientColor = const Color(0xFFFFC2D9);
        headerColor = const Color(0xFFB0145A);
        r1Color = Colors.white;
        r2Color = const Color(0xFFFFD6E7);
        r3Color = const Color(0xFFD81B6A);
        heartColor = Colors.white;
        line1 = 'Tap to send yours';
        line2 = '$partnerName felt it 2 min ago';
        line1Color = const Color(0xFF2B1B26);
        line2Color = const Color(0xFF7A6672);
        break;
      case HeartbeatWidgetState.offline:
        bg = const Color(0xFFF1E4EA);
        ambientColor = const Color(0xFFE7DDE2);
        headerColor = const Color(0xFF7A6672);
        r1Color = Colors.white;
        r2Color = const Color(0xFFE7DDE2);
        r3Color = const Color(0xFFB7A7B4);
        heartColor = Colors.white;
        line1 = '$partnerName is offline';
        line2 = 'Last seen 2 hours ago';
        line1Color = const Color(0xFF7A6672);
        line2Color = const Color(0xFF7A6672);
        break;
    }

    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 174,
          height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            // Ambient corner circle
            Positioned(
              left: 106,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ambientColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Header
            Positioned(
              left: 14,
              top: 12,
              child: Text(
                'HEARTBEAT',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: headerColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            // Concentric Heart Rings
            Positioned(
              left: 0,
              right: 0,
              top: 30,
              child: Center(
                child: SizedBox(
                  width: 110,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(color: r1Color, shape: BoxShape.circle),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(color: r2Color, shape: BoxShape.circle),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: r3Color, shape: BoxShape.circle),
                      ),
                      Icon(Icons.favorite_rounded, color: heartColor, size: 24),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom text
            Positioned(
              left: 8,
              right: 8,
              bottom: 12,
              child: Column(
                children: [
                  Text(
                    line1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: line1Color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    line2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: line2Color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 3. REUNION COUNTDOWN WIDGET (Medium 4x2: 358 x 174)
// ============================================================================

enum CountdownWidgetState { daysHours, tomorrow, today }

class ReunionCountdownWidget extends StatelessWidget {
  final CountdownWidgetState state;
  final WidgetPalette palette;
  final String partnerName;
  final String countdownText;
  final String subText;
  final String originAirport;
  final String destAirport;
  final double progress;
  final VoidCallback? onTap;

  const ReunionCountdownWidget({
    super.key,
    this.state = CountdownWidgetState.daysHours,
    this.palette = WidgetPalette.pink,
    this.partnerName = 'Rahul',
    this.countdownText = '23d 14h',
    this.subText = 'Wed 25 Nov, Frankfurt to Chennai',
    this.originAirport = 'FRA',
    this.destAirport = 'MAA',
    this.progress = 0.70,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = WidgetPaletteColors.of(palette);

    String displayMain = countdownText;
    String displaySub = subText;
    double displayProgress = progress;

    if (state == CountdownWidgetState.tomorrow) {
      displayMain = 'Tomorrow';
      displaySub = '$partnerName flies at 10:30 PM tonight';
      displayProgress = 0.92;
    } else if (state == CountdownWidgetState.today) {
      displayMain = 'Today!';
      displaySub = '$partnerName lands at 12:30 PM';
      displayProgress = 1.0;
    }

    return _withClampedTextScale(
      context,
      GestureDetector(
      onTap: onTap,
      child: Container(
        width: 358,
        height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            // Ambient corner circle
            Positioned(
              left: 250,
              top: -60,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Confetti shapes if Today!
            if (state == CountdownWidgetState.today) ...[
              Positioned(
                left: 196,
                top: 20,
                child: Transform.rotate(
                  angle: 0.35,
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFFFD66B), borderRadius: BorderRadius.circular(3))),
                ),
              ),
              Positioned(
                left: 306,
                top: 60,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC9B8FF), shape: BoxShape.circle)),
              ),
              Positioned(
                left: 240,
                top: 100,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(width: 9, height: 9, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3))),
                ),
              ),
            ],

            // Top Header
            Positioned(
              left: 16,
              top: 14,
              child: Text(
                'NEXT MEETUP',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.subtext,
                  letterSpacing: 0.4,
                ),
              ),
            ),

            // Main Countdown Number / Text
            Positioned(
              left: 16,
              top: 30,
              child: SizedBox(
                width: 250,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayMain,
                    style: GoogleFonts.nunito(
                      fontSize: state == CountdownWidgetState.daysHours ? 58 : 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      color: colors.text,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
            ),

            // Subtitle
            Positioned(
              left: 16,
              right: 16,
              top: 100,
              child: Text(
                displaySub,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.subtext,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Dual Mascots in Top Right
            Positioned(
              right: 18,
              top: 16,
              child: Row(
                children: [
                  const MascotHeart(color: MascotColor.pink, size: 44),
                  Transform.translate(
                    offset: const Offset(-12, 0),
                    child: const MascotHeart(color: MascotColor.violet, size: 44),
                  ),
                ],
              ),
            ),

            // Bottom Route Progress Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Text(
                    originAirport,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.track,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: displayProgress.clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.fill,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    destAirport,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 4. DAILY MOMENTS PHOTO WIDGET (Large 4x4: 358 x 358)
// ============================================================================

enum MomentsWidgetState { partnerMoment, waiting, sent }

class DailyMomentsPhotoWidget extends StatelessWidget {
  final MomentsWidgetState state;
  final String partnerName;
  final String timeText;
  final String caption;
  final VoidCallback? onHeartReact;
  final VoidCallback? onSendFirst;

  const DailyMomentsPhotoWidget({
    super.key,
    this.state = MomentsWidgetState.partnerMoment,
    this.partnerName = 'Rahul',
    this.timeText = 'Today, 9:30 PM',
    this.caption = 'Sunset without you. Miss you.',
    this.onHeartReact,
    this.onSendFirst,
  });

  @override
  Widget build(BuildContext context) {
    if (state == MomentsWidgetState.waiting) {
      return _withClampedTextScale(
        context,
        Container(
          width: 358,
          height: 358,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0ED),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 240,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC2D9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 40,
              child: Center(
                child: MascotHeart(color: MascotColor.violet, size: 104),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 165,
              child: Column(
                children: [
                  Text(
                    'Waiting for $partnerName',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2B1B26),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "$partnerName's moment will appear here",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A6672),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 44,
              right: 44,
              bottom: 40,
              child: GestureDetector(
                onTap: onSendFirst,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD81B6A),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Send yours first',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      );
    }

    // Partner moment or Your moment sent
    final bool isSent = state == MomentsWidgetState.sent;

    return _withClampedTextScale(
      context,
      Container(
        width: 358,
        height: 358,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF5C65B),
          borderRadius: BorderRadius.circular(36),
        ),
      child: Stack(
        children: [
          // Scenic sunset background art
          Positioned.fill(
            child: CustomPaint(
              painter: _ScenicSunsetPainter(),
            ),
          ),

          // Top-Left User/Partner Pill
          Positioned(
            left: 14,
            right: 80,
            top: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MascotHeart(
                      color: isSent ? MascotColor.pink : MascotColor.violet,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSent ? 'You' : partnerName,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2B1B26),
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isSent ? 'Sent $timeText, seen by $partnerName' : timeText,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF7A6672),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top-Right Inset Thumbnail
          if (!isSent)
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                width: 64,
                height: 64,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CustomPaint(
                  painter: _MiniCoffeeCupPainter(),
                ),
              ),
            ),

          // Bottom Caption Bubble
          if (!isSent)
            Positioned(
              left: 14,
              bottom: 14,
              child: Container(
                width: 230,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  caption,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B1B26),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Bottom-Right Heart Reaction Button
          if (!isSent)
            Positioned(
              right: 14,
              bottom: 14,
              child: GestureDetector(
                onTap: onHeartReact,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFD81B6A),
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ============================================================================
// 5. TOGETHER COUNTER WIDGET (Small 2x2: 174 x 174)
// ============================================================================

class TogetherCounterWidget extends StatelessWidget {
  final int days;
  final String breakdown;
  final VoidCallback? onTap;

  const TogetherCounterWidget({
    super.key,
    this.days = 992,
    this.breakdown = '2y 8m 24d',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 174,
          height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE4FF),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 14,
              child: Text(
                'TOGETHER',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4B3A8C),
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 146,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$days',
                        style: GoogleFonts.nunito(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4B3A8C),
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'days',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4B3A8C),
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: SizedBox(
                width: 96,
                child: Text(
                  breakdown,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4B3A8C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Leaning Mascots at Bottom Right
            Positioned(
              right: 28,
              bottom: 8,
              child: Transform.rotate(
                angle: -0.14,
                child: const MascotHeart(color: MascotColor.pink, size: 44),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Transform.rotate(
                angle: 0.14,
                child: const MascotHeart(color: MascotColor.violet, size: 40),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 6. QUICK TOUCH WIDGET (Small 2x2: 174 x 174)
// ============================================================================

class QuickTouchWidget extends StatelessWidget {
  final String partnerName;
  final Function(String action)? onAction;

  const QuickTouchWidget({
    super.key,
    this.partnerName = 'Rahul',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _withClampedTextScale(
      context,
      Container(
        width: 174,
        height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
        ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: Text(
              'SEND TO ${partnerName.toUpperCase()}',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7A6672),
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            left: 13,
            right: 13,
            top: 34,
            bottom: 12,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTouchBtn(
                        title: 'Miss you',
                        icon: Icons.favorite_rounded,
                        bg: const Color(0xFFFFE0ED),
                        fg: const Color(0xFFD81B6A),
                        onTap: () => onAction?.call('miss_you'),
                      ),
                      const SizedBox(width: 8),
                      _buildTouchBtn(
                        title: 'Hug',
                        icon: Icons.all_inclusive_rounded,
                        bg: const Color(0xFFEDE4FF),
                        fg: const Color(0xFF7B5CF0),
                        onTap: () => onAction?.call('hug'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _buildTouchBtn(
                        title: 'Touch',
                        icon: Icons.touch_app_rounded,
                        bg: const Color(0xFFFFE7A3),
                        fg: const Color(0xFF7A5200),
                        onTap: () => onAction?.call('touch'),
                      ),
                      const SizedBox(width: 8),
                      _buildTouchBtn(
                        title: 'Cheer',
                        icon: Icons.star_rounded,
                        bg: const Color(0xFFE3F6EC),
                        fg: const Color(0xFF1F7A4F),
                        onTap: () => onAction?.call('cheer'),
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

  Widget _buildTouchBtn({
    required String title,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. TWO CLOCKS WIDGET (Wide 4x1: 358 x 84)
// ============================================================================

class TwoClocksWidget extends StatelessWidget {
  final String myName;
  final String myTime;
  final String partnerName;
  final String partnerTime;
  final String distance;
  final VoidCallback? onTap;

  const TwoClocksWidget({
    super.key,
    this.myName = 'You',
    this.myTime = '8:12 PM',
    this.partnerName = 'Rahul',
    this.partnerTime = '9:42 PM',
    this.distance = '8,420 km',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 358,
          height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
        ),
        child: Row(
          children: [
            // Left: User Time
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE7A3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF7A5200), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    myName,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A6672),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      myTime,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2B1B26),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center: Distance with Dotted Path
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        distance,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB0145A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomPaint(
                      size: const Size(double.infinity, 3),
                      painter: _DottedHorizontalLinePainter(
                        color: const Color(0xFFD81B6A),
                        dotRadius: 1.5,
                        spacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Partner Time
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    partnerName,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A6672),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      partnerTime,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2B1B26),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.nightlight_round, color: Color(0xFF4B3A8C), size: 18),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 8. NEXT MILESTONE WIDGET (Small 2x2: 174 x 174)
// ============================================================================

class NextMilestoneWidget extends StatelessWidget {
  final int daysLeft;
  final String targetMilestone;
  final double progress;
  final VoidCallback? onTap;

  const NextMilestoneWidget({
    super.key,
    this.daysLeft = 8,
    this.targetMilestone = '1000 days',
    this.progress = 0.92,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 174,
          height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD66B),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 12,
              child: Text(
                'NEXT MILESTONE',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5C4300),
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Positioned(
              left: 39,
              top: 34,
              child: SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: _MilestoneRingPainter(
                        trackColor: const Color(0xFFFFE7A3),
                        fillColor: const Color(0xFFD81B6A),
                        progress: progress,
                        strokeWidth: 10,
                      ),
                    ),
                    SizedBox(
                      width: 66,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$daysLeft',
                          style: GoogleFonts.nunito(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2B1B26),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 12,
              child: Text(
                'days to $targetMilestone',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B1B26),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 9. GAME STATUS WIDGET (Small 2x2: 174 x 174)
// ============================================================================

enum GameWidgetState { yourMove, partnerTurn }

class GameStatusWidget extends StatelessWidget {
  final String partnerName;
  final GameWidgetState state;
  final VoidCallback? onAction;

  const GameStatusWidget({
    super.key,
    this.partnerName = 'Rahul',
    this.state = GameWidgetState.yourMove,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isYourMove = state == GameWidgetState.yourMove;

    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onAction,
        child: Container(
          width: 174,
          height: 174,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF7B5CF0),
            borderRadius: BorderRadius.circular(32),
          ),
        child: Stack(
          children: [
            // Ambient corner circle
            Positioned(
              left: 110,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF9B87F5),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Mini Tic-Tac-Toe Board Art
            Positioned(
              left: 14,
              top: 14,
              child: SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _MiniTicTacToePainter(),
                ),
              ),
            ),

            // Live tag
            Positioned(
              left: 78,
              top: 22,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6FCFA0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Main Text
            Positioned(
              left: 14,
              right: 14,
              top: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYourMove ? 'Your move' : "$partnerName's turn",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isYourMove ? '$partnerName is waiting' : 'You played X',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEDE4FF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action Button
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: isYourMove ? Colors.white : const Color(0xFF9B87F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isYourMove ? 'Play' : 'Nudge',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isYourMove ? const Color(0xFF4B3A8C) : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 10. LOVE NOTE WIDGET (Medium 4x2: 358 x 174)
// ============================================================================

enum LoveNoteWidgetState { normal, sealed }

class LoveNoteWidget extends StatelessWidget {
  final String partnerName;
  final String noteSnippet;
  final String timeAgo;
  final LoveNoteWidgetState state;
  final VoidCallback? onTap;

  const LoveNoteWidget({
    super.key,
    this.partnerName = 'Rahul',
    this.noteSnippet = 'Thinking of you, always.',
    this.timeAgo = '1 hr ago',
    this.state = LoveNoteWidgetState.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSealed = state == LoveNoteWidgetState.sealed;

    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 358,
          height: 174,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE4FF),
            borderRadius: BorderRadius.circular(32),
          ),
        child: Stack(
          children: [
            // Left photo / envelope thumbnail
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                width: 122,
                height: 150,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A58A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: isSealed
                    ? Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD81B6A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
                        ),
                      )
                    : CustomPaint(
                        painter: _ScenicSunsetPainter(),
                      ),
              ),
            ),

            // Right header: LOVE NOTE
            Positioned(
              left: 152,
              right: 14,
              top: 16,
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Color(0xFFD81B6A), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'LOVE NOTE',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4B3A8C),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Note snippet
            Positioned(
              left: 152,
              top: 44,
              right: 14,
              child: Text(
                isSealed ? 'A sealed whisper waits for you.' : noteSnippet,
                style: GoogleFonts.nunito(
                  fontSize: isSealed ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B1B26),
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Footer
            Positioned(
              left: 152,
              right: 14,
              bottom: 16,
              child: Text(
                isSealed ? 'Tap to break seal' : 'From $partnerName, $timeAgo',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4B3A8C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 11. TRIP TRACKER WIDGET (Medium 4x2: 358 x 174)
// ============================================================================

enum TripWidgetState { inTheAir, scheduled, landed }

class TripTrackerWidget extends StatelessWidget {
  final TripWidgetState state;
  final String partnerName;
  final String flightNumber;
  final String originCode;
  final String originCity;
  final String destCode;
  final String destCity;
  final String timeText;
  final VoidCallback? onTap;

  const TripTrackerWidget({
    super.key,
    this.state = TripWidgetState.inTheAir,
    this.partnerName = 'Rahul',
    this.flightNumber = 'Flight XX 214',
    this.originCode = 'FRA',
    this.originCity = 'Frankfurt',
    this.destCode = 'MAA',
    this.destCity = 'Chennai',
    this.timeText = '12:30 PM',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String badgeText;
    Color badgeBg;
    Color badgeFg;
    String bottomMain;
    double progress;

    switch (state) {
      case TripWidgetState.inTheAir:
        badgeText = 'In the air, on time';
        badgeBg = const Color(0xFFE3F6EC);
        badgeFg = const Color(0xFF1F7A4F);
        bottomMain = 'Lands in 3h 42m';
        progress = 0.62;
        break;
      case TripWidgetState.scheduled:
        badgeText = 'Departs in 2 h';
        badgeBg = const Color(0xFFFFE7A3);
        badgeFg = const Color(0xFF7A5200);
        bottomMain = 'Boarding 9:50 PM';
        progress = 0.0;
        break;
      case TripWidgetState.landed:
        badgeText = 'Landed';
        badgeBg = const Color(0xFFE3F6EC);
        badgeFg = const Color(0xFF1F7A4F);
        bottomMain = '$partnerName is on the way';
        progress = 1.0;
        break;
    }

    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 358,
          height: 174,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
          ),
        child: Stack(
          children: [
            // Top row
            Positioned(
              left: 16,
              right: 16,
              top: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: badgeFg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    flightNumber,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A6672),
                    ),
                  ),
                ],
              ),
            ),

            // Airport Codes & Cities
            Positioned(
              left: 16,
              right: 16,
              top: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 68,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            originCode,
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2B1B26),
                              height: 1.0,
                            ),
                          ),
                        ),
                        Text(
                          originCity,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7A6672),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 68,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            destCode,
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2B1B26),
                              height: 1.0,
                            ),
                          ),
                        ),
                        Text(
                          destCity,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7A6672),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Flight Progress Track with Plane
            Positioned(
              left: 86,
              top: 64,
              child: SizedBox(
                width: 186,
                height: 22,
                child: CustomPaint(
                  painter: _FlightTrackPainter(progress: progress),
                ),
              ),
            ),

            // Bottom row
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      bottomMain,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2B1B26),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB0145A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// 12. NEXT EVENT WIDGET (Medium 4x2: 358 x 174)
// ============================================================================

class NextEventWidget extends StatelessWidget {
  final String event1Title;
  final String event1Sub;
  final String event1Time;
  final Color event1Color;
  final String event2Title;
  final String event2Sub;
  final String event2Time;
  final Color event2Color;
  final VoidCallback? onTap;

  const NextEventWidget({
    super.key,
    this.event1Title = 'Video call night',
    this.event1Sub = 'Tonight',
    this.event1Time = '9:30 PM',
    this.event1Color = const Color(0xFFD81B6A),
    this.event2Title = 'Movie night',
    this.event2Sub = 'Fri 6 Nov, watch together',
    this.event2Time = '8:00 PM',
    this.event2Color = const Color(0xFF7B5CF0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _withClampedTextScale(
      context,
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 358,
          height: 174,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
          ),
        child: Stack(
          children: [
            // Top Header: UP NEXT
            Positioned(
              left: 16,
              top: 12,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE0ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFB0145A), size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'UP NEXT',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A6672),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Events List
            Positioned(
              left: 16,
              right: 16,
              top: 46,
              child: Column(
                children: [
                  _buildEventRow(
                    barColor: event1Color,
                    title: event1Title,
                    subtitle: event1Sub,
                    time: event1Time,
                  ),
                  const Divider(color: Color(0xFFF8D8E6), height: 1.5, thickness: 1.5),
                  _buildEventRow(
                    barColor: event2Color,
                    title: event2Title,
                    subtitle: event2Sub,
                    time: event2Time,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEventRow({
    required Color barColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 36,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B1B26),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A6672),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB0145A),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 13. MEMORY OF THE DAY WIDGET (Large 4x4: 358 x 358)
// ============================================================================

class MemoryOfTheDayWidget extends StatelessWidget {
  final String dateTitle;
  final String memoryTitle;
  final String memoryDate;
  final VoidCallback? onSeeMemory;

  const MemoryOfTheDayWidget({
    super.key,
    this.dateTitle = 'ON THIS DAY, 1 YEAR AGO',
    this.memoryTitle = 'Hill trek',
    this.memoryDate = '3 Nov 2025',
    this.onSeeMemory,
  });

  @override
  Widget build(BuildContext context) {
    return _withClampedTextScale(
      context,
      Container(
        width: 358,
        height: 358,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0ED),
          borderRadius: BorderRadius.circular(36),
        ),
      child: Stack(
        children: [
          // Ambient corner circle
          Positioned(
            left: 250,
            top: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC2D9),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Header
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Text(
              dateTitle,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFB0145A),
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Tilted Polaroid Card (-3 degrees)
          Positioned(
            left: 40,
            top: 50,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 278,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Picture inside polaroid
                    Container(
                      width: double.infinity,
                      height: 188,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFE3EE),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: CustomPaint(
                        painter: _MountainLandscapePainter(),
                      ),
                    ),

                    // Masking Tape on Top
                    Positioned(
                      top: -20,
                      left: 104,
                      child: Container(
                        width: 60,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8DB8E).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Polaroid Caption
                    Positioned(
                      left: 4,
                      right: 4,
                      bottom: -28,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              memoryTitle,
                              style: GoogleFonts.nunito(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2B1B26),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            memoryDate,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF7A6672),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: GestureDetector(
                onTap: onSeeMemory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD81B6A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'See this memory',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ============================================================================
// 14. COUPLE DASHBOARD WIDGET (Large 4x4: 358 x 358)
// ============================================================================

class CoupleDashboardWidget extends StatelessWidget {
  final String partnerName;
  final int battery;
  final int streak;
  final bool isOnline;
  final bool isPartnerHolding;
  final String myTime;
  final String partnerTime;
  final String distance;
  final String meetupCountdown;
  final String meetupDate;
  final String togetherDuration;
  final String lastMet;
  final VoidCallback? onHeartHold;
  final Function(String action)? onQuickTouch;

  const CoupleDashboardWidget({
    super.key,
    this.partnerName = 'Rahul',
    this.battery = 64,
    this.streak = 42,
    this.isOnline = true,
    this.isPartnerHolding = false,
    this.myTime = '8:12 PM',
    this.partnerTime = '9:42 PM',
    this.distance = '8,420 km',
    this.meetupCountdown = '23d 14h',
    this.meetupDate = 'Wed 25 Nov',
    this.togetherDuration = 'Together 2y 8m',
    this.lastMet = 'Last met 3 mo ago',
    this.onHeartHold,
    this.onQuickTouch,
  });

  @override
  Widget build(BuildContext context) {
    final safeBattery = battery.clamp(0, 100);
    return _withClampedTextScale(
      context,
      Container(
        width: 358,
        height: 358,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFF8D8E6), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Row 1: Partner status + streak
            Row(
              children: [
                const MascotHeart(color: MascotColor.violet, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2B1B26),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${isOnline ? 'Online now' : 'Away'}, battery $safeBattery%',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isOnline ? const Color(0xFF1F7A4F) : const Color(0xFF7A6672),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$streak-day streak',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB0145A),
                  ),
                ),
              ),
            ],
          ),

          // Row 2: 3 Mini Metric Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2B1B26))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(myTime, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2B1B26))),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partnerName, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2B1B26)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(partnerTime, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2B1B26))),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apart', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB0145A))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(distance, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFFB0145A))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Row 3: Next meetup banner
          Container(
            height: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFD81B6A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -24,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8478A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT MEETUP',
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFFD6E7),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                meetupCountdown,
                                style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              meetupDate,
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFFFD6E7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              togetherDuration,
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFFFD6E7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          // Row 4: Heart sync + 3 Quick touch buttons
          Row(
            children: [
              GestureDetector(
                onTap: onHeartHold,
                onLongPress: onHeartHold,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE0ED),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD6E7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD81B6A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hold to sync',
                      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF2B1B26)),
                      maxLines: 1,
                    ),
                    Text(
                      isPartnerHolding ? '$partnerName is holding!' : '$partnerName not holding',
                      style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: isPartnerHolding ? const Color(0xFFD81B6A) : const Color(0xFF7A6672)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildCircleBtn(
                icon: Icons.favorite_rounded,
                bg: const Color(0xFFFFE0ED),
                fg: const Color(0xFFD81B6A),
                onTap: () => onQuickTouch?.call('miss_you'),
              ),
              const SizedBox(width: 6),
              _buildCircleBtn(
                icon: Icons.all_inclusive_rounded,
                bg: const Color(0xFFEDE4FF),
                fg: const Color(0xFF7B5CF0),
                onTap: () => onQuickTouch?.call('hug'),
              ),
              const SizedBox(width: 6),
              _buildCircleBtn(
                icon: Icons.touch_app_rounded,
                bg: const Color(0xFFFFE7A3),
                fg: const Color(0xFF7A5200),
                onTap: () => onQuickTouch?.call('touch'),
              ),
            ],
          ),

          // Row 5: Tags
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    togetherDuration,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4B3A8C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7A3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lastMet,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A5200),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

class _FlightArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dashed curved arc
    final paint = Paint()
      ..color = const Color(0xFFD81B6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(14, 34);
    path.quadraticBezierTo(size.width * 0.5, -14, size.width - 14, 34);

    // Draw dashed path
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + 2);
        canvas.drawPath(extractPath, paint);
        distance += 10.0;
      }
    }

    // Left Pin (Pink #FF5C9E)
    _drawPin(canvas, const Offset(14, 34), const Color(0xFFFF5C9E));

    // Right Pin (Violet #9B87F5)
    _drawPin(canvas, Offset(size.width - 14, 34), const Color(0xFF9B87F5));
  }

  void _drawPin(Canvas canvas, Offset pos, Color color) {
    final pinPaint = Paint()..color = color;
    final whitePaint = Paint()..color = Colors.white;

    final pinPath = Path();
    pinPath.moveTo(pos.dx, pos.dy);
    pinPath.cubicTo(pos.dx - 6, pos.dy - 7, pos.dx - 8, pos.dy - 11, pos.dx - 8, pos.dy - 15);
    pinPath.arcToPoint(Offset(pos.dx + 8, pos.dy - 15), radius: const Radius.circular(8));
    pinPath.cubicTo(pos.dx + 8, pos.dy - 11, pos.dx + 6, pos.dy - 7, pos.dx, pos.dy);
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 15), 3.2, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedHorizontalLinePainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  _DottedHorizontalLinePainter({
    required this.color,
    this.dotRadius = 1.5,
    this.spacing = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height / 2), dotRadius, paint);
      startX += dotRadius * 2 + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MilestoneRingPainter extends CustomPainter {
  final Color trackColor;
  final Color fillColor;
  final double progress;
  final double strokeWidth;

  _MilestoneRingPainter({
    required this.trackColor,
    required this.fillColor,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final fillPaint = Paint()
      ..color = fillColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniTicTacToePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Grid lines
    canvas.drawLine(const Offset(18, 6), const Offset(18, 46), gridPaint);
    canvas.drawLine(const Offset(34, 6), const Offset(34, 46), gridPaint);
    canvas.drawLine(const Offset(6, 18), const Offset(46, 18), gridPaint);
    canvas.drawLine(const Offset(6, 34), const Offset(46, 34), gridPaint);

    // X in top-left
    final xPaint = Paint()
      ..color = const Color(0xFFFFD66B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(8, 8), const Offset(16, 16), xPaint);
    canvas.drawLine(const Offset(16, 8), const Offset(8, 16), xPaint);

    // O in center
    final oPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(26, 26), 5, oPaint);

    // X in bottom-right
    canvas.drawLine(const Offset(38, 38), const Offset(46, 46), xPaint);
    canvas.drawLine(const Offset(46, 38), const Offset(38, 46), xPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlightTrackPainter extends CustomPainter {
  final double progress;

  _FlightTrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final dottedPaint = Paint()
      ..color = const Color(0xFFD81B6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Dotted track across full width
    double x = 0;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, 10), 1.5, dottedPaint);
      x += 6;
    }

    // Solid progress line
    final solidWidth = size.width * progress.clamp(0.0, 1.0);
    final solidPaint = Paint()
      ..color = const Color(0xFFD81B6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 10), Offset(solidWidth, 10), solidPaint);

    // Airplane symbol rotated along path
    final planePaint = Paint()
      ..color = const Color(0xFF2B1B26)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final planeX = (solidWidth - 11).clamp(0.0, size.width - 22);
    final planePath = Path();
    planePath.moveTo(planeX + 21, 1);
    planePath.lineTo(planeX + 3, 9);
    planePath.lineTo(planeX + 10, 12);
    planePath.lineTo(planeX + 13, 19);
    planePath.close();

    canvas.drawPath(planePath, planePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ScenicSunsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    final skyPaint = Paint()..color = const Color(0xFFF4A58A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Sun
    final sunPaint = Paint()..color = const Color(0xFFF5C65B);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 55, sunPaint);

    // Sea
    final seaPaint = Paint()..color = const Color(0xFF3F5FA8);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4), seaPaint);

    // Waves
    final wavePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(20, size.height * 0.7), Offset(90, size.height * 0.7), wavePaint);
    canvas.drawLine(Offset(size.width - 110, size.height * 0.68), Offset(size.width - 30, size.height * 0.68), wavePaint);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.78), Offset(size.width * 0.65, size.height * 0.78), wavePaint);

    // Beach sand
    final sandPaint = Paint()..color = const Color(0xFFE8C48A);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.84, size.width, size.height * 0.16), sandPaint);

    // Two little figures watching sunset
    final f1Paint = Paint()..color = const Color(0xFF2E2230);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.75), 10, f1Paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.45 - 8, size.height * 0.75 + 10, 16, 26), const Radius.circular(8)), f1Paint);

    final f2Paint = Paint()..color = const Color(0xFFD1355F);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.75), 10, f1Paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.55 - 8, size.height * 0.75 + 10, 16, 26), const Radius.circular(8)), f2Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniCoffeeCupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF5C65B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawOval(Rect.fromLTWH(size.width * 0.2, size.height * 0.7, size.width * 0.6, 12), whitePaint);

    // Cup
    final cupPath = Path();
    cupPath.moveTo(size.width * 0.25, size.height * 0.4);
    cupPath.lineTo(size.width * 0.75, size.height * 0.4);
    cupPath.lineTo(size.width * 0.7, size.height * 0.7);
    cupPath.lineTo(size.width * 0.3, size.height * 0.7);
    cupPath.close();
    canvas.drawPath(cupPath, whitePaint);

    // Heart on cup
    final heartPaint = Paint()..color = const Color(0xFFD1355F);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 4, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    final skyPaint = Paint()..color = const Color(0xFFCFE3EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Sun
    final sunPaint = Paint()..color = const Color(0xFFF5C65B);
    canvas.drawCircle(Offset(size.width * 0.78, 30), 16, sunPaint);

    // Mountain peaks
    final mountainPaint = Paint()..color = const Color(0xFF6F7FB8);
    final mPath = Path();
    mPath.moveTo(0, size.height);
    mPath.lineTo(size.width * 0.28, size.height * 0.35);
    mPath.lineTo(size.width * 0.48, size.height * 0.75);
    mPath.lineTo(size.width * 0.68, size.height * 0.25);
    mPath.lineTo(size.width, size.height);
    mPath.close();
    canvas.drawPath(mPath, mountainPaint);

    // Snow caps
    final snowPaint = Paint()..color = Colors.white;
    final sPath1 = Path();
    sPath1.moveTo(size.width * 0.28, size.height * 0.35);
    sPath1.lineTo(size.width * 0.22, size.height * 0.48);
    sPath1.lineTo(size.width * 0.28, size.height * 0.44);
    sPath1.lineTo(size.width * 0.34, size.height * 0.50);
    sPath1.close();
    canvas.drawPath(sPath1, snowPaint);

    final sPath2 = Path();
    sPath2.moveTo(size.width * 0.68, size.height * 0.25);
    sPath2.lineTo(size.width * 0.61, size.height * 0.40);
    sPath2.lineTo(size.width * 0.68, size.height * 0.36);
    sPath2.lineTo(size.width * 0.75, size.height * 0.42);
    sPath2.close();
    canvas.drawPath(sPath2, snowPaint);

    // Trees
    final treePaint = Paint()..color = const Color(0xFF3E9B6E);
    canvas.drawCircle(Offset(size.width * 0.15, size.height - 10), 16, treePaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height - 8), 18, treePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
