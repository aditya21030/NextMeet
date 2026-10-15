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
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heartbeat() async {
    // A robust, dual-pulse heartbeat that works on most devices
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
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
}
