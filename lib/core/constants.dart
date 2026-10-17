import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary luxury palette (Velvet Rose & Deep Wine)
  static const Color primary = Color(0xFFE11D48); // Velvet Rose
  static const Color primaryLight = Color(0xFFFB7185); // Rose Petal Glow
  static const Color primaryDark = Color(0xFF9F1239); // Deep Wine
  
  // Secondary / Milestones & Champagne Gold
  static const Color accent = Color(0xFF6366F1); // Modern Indigo
  static const Color gold = Color(0xFFF59E0B); // Champagne Gold / Candlelight Amber
  static const Color goldDark = Color(0xFFD97706);
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Rose
  
  // Social Colors
  static const Color whatsapp = Color(0xFF25D366);
  static const Color telegram = Color(0xFF0088CC);
  static const Color instagram = Color(0xFFE4405F);
  static const Color facebook = Color(0xFF1877F2);
  
  // Neutral / Luxury Canvas (Cashmere Milk & Espresso Noir)
  static const Color background = Color(0xFFFAFAF9); // Cashmere Milk / Alabaster
  static const Color surface = Colors.white;
  static const Color sanctumBackground = Color(0xFFFFF1F2); // Rose Petal Tint
  static const Color textPrimary = Color(0xFF18181B); // Espresso Noir
  static const Color textSecondary = Color(0xFF71717A); // Mocha Slate
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color divider = Color(0xFFF4E8EA);
  
  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DFFFFFF),
      Color(0x1AFFFFFF),
    ],
  );

  // Premium Shadows (Updated to const for build stability)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Color(0x1CE11D48),
      blurRadius: 40,
      offset: Offset(0, 20),
      spreadRadius: -10,
    ),
    BoxShadow(
      color: Color(0x0518181B),
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x40E11D48),
      blurRadius: 20,
      offset: Offset(0, 10),
      spreadRadius: -5,
    ),
  ];

  static const List<BoxShadow> deepShadow = [
    BoxShadow(
      color: Color(0x1F0F172A),
      blurRadius: 40,
      offset: Offset(0, 20),
      spreadRadius: -12,
    ),
  ];

  static const List<BoxShadow> inputShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 15,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double circle = 100.0;
}

class AppTextStyles {
  static TextStyle h1 = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle h3 = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyL = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyM = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyS = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle button = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}

class AppSubscription {
  // CONNECTION
  static const int freeMissYouDailyLimit = 3;
  static const int freeVirtualHugDailyLimit = 5;
  static const int freeHeartSyncDailyLimit = 2;
  
  // DAILY ENGAGEMENT
  static const int freeDateIdeasWeeklyLimit = 3;
  
  // STREAKS & GAMIFICATION
  static const int freeMaxBadges = 5;
  static const int plusStreakShieldsPerMonth = 2;
  
  // SHARED MEMORIES
  static const int freeMaxMemories = 50;
  static const int plusMaxMemories = 500;
  
  // SHARED TRIP PLANNER
  static const int freeMaxActiveTrips = 1;
  static const int plusMaxActiveTrips = 10;
  
  // PRIVATE SPACE
  static const int freeSecretPhotoVaultBytes = 20 * 1024 * 1024; // 20 MB
  static const int plusSecretPhotoVaultBytes = 150 * 1024 * 1024; // 150 MB
  static const int freeMaxLoveLetters = 3;
  
  // APP EXPERIENCE
  static const int plusMaxThemes = 12;
}

class AppLinks {
  static const String playStore = "https://play.google.com/store/apps/details?id=com.yousful.nextmeet";
  
  static String getInviteMessage(String code) {
    return "❤️ NextMeet: I've started our journey! Click below to join me and sync our hearts forever.\n\n"
           "1️⃣ Download: $playStore\n"
           "2️⃣ Enter My Magic Code: $code\n\n"
           "Wait for me there! ✨";
  }
}

class SupabaseConfig {
  static const String url = 'https://pumzmskdirdaqpbkghvl.supabase.co';
  static const String anonKey = 'sb_publishable_-Y856VjMveZ28zMyOe5-zQ_7fMYHnwC';
}

class RevenueCatConfig {
  static const String apiKey = 'goog_YDTtQiefCXZrxulXFgTSevALUwk';
  static const String entitlementId = 'plus';
  static const String monthlyPackageId = '\$rc_monthly';
  static const String annualPackageId = '\$rc_annual';
}

