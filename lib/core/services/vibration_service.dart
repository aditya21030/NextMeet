import 'package:flutter/services.dart';

class VibrationService {
  static Future<void> light() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  static Future<void> touchVibration() async {
    // A more intense/noticeable pattern for digital touches
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<void> hugVibration() async {
    // A warm, longer pulse for a hug
    await HapticFeedback.vibrate();
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 250));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heartbeat() async {
    // A robust, hardware-guaranteed dual-pulse heartbeat (Lub-dub)
    HapticFeedback.vibrate();
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> sparkle() async {
    // A quick, shimmering sequence
    for (int i = 0; i < 4; i++) {
      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  static Future<void> pulse() async {
    // A rhythmic growing pulse
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }

  static Future<void> echo() async {
    // A strong hit followed by a fading echo
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.selectionClick();
  }

  static Future<void> wave() async {
    // A smooth wave-like feel
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  // --- NextMeet+ Exclusive Luxury Rhythms ---

  static Future<void> soulmateFlutter() async {
    // Rapid, delicate flutter resembling butterflies in your stomach
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 40));
    }
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.lightImpact();
  }

  static Future<void> cosmicSurge() async {
    // Escalating electric surge culminating in a heavy vibration burst
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.vibrate();
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 140));
    await HapticFeedback.heavyImpact();
  }

  static Future<void> endlessLove() async {
    // 3 successive, rhythmic loving heartbeats
    for (int i = 0; i < 3; i++) {
      HapticFeedback.vibrate();
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.mediumImpact();
      if (i < 2) await Future.delayed(const Duration(milliseconds: 260));
    }
  }

  static Future<void> deepEmbrace() async {
    // Intense, warm sustained chest-to-chest hold
    HapticFeedback.vibrate();
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.vibrate();
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> secretWhisper() async {
    // Intimate micro-taps designed to be felt discreetly in your hand
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 130));
    await HapticFeedback.selectionClick();
  }

  /// Master dispatcher to play any pattern by its saved name
  static Future<void> playPattern(String? patternName) async {
    switch (patternName) {
      case 'Warm Hug':
        await hugVibration();
        break;
      case 'Digital Touch':
        await touchVibration();
        break;
      case 'Sparkle':
        await sparkle();
        break;
      case 'Pulse':
        await pulse();
        break;
      case 'Echo':
        await echo();
        break;
      case 'Wave':
        await wave();
        break;
      // Plus Exclusives
      case 'Soulmate Flutter':
        await soulmateFlutter();
        break;
      case 'Cosmic Surge':
        await cosmicSurge();
        break;
      case 'Endless Love':
        await endlessLove();
        break;
      case 'Deep Embrace':
        await deepEmbrace();
        break;
      case 'Secret Whisper':
        await secretWhisper();
        break;
      case 'Heartbeat':
      default:
        await heartbeat();
        break;
    }
  }
}
