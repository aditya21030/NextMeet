import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NextMeet Design System Color Tokens
/// Based strictly on NextMeet Redesign.pdf (Page 85)
class AppColors {
  // BRAND COLOURS
  static const Color primary = Color(0xFFD81B6A); // You, main brand colour
  static const Color primaryDark = Color(0xFFB0145A);
  static const Color you = Color(0xFFFF5C9E);
  static const Color pinkLight = Color(0xFFFFC2D9);
  static const Color pinkSoft = Color(0xFFFFE0ED);
  static const Color background = Color(0xFFFFF4F8); // Blush light canvas

  // PARTNER COLOURS
  static const Color partner = Color(0xFF7B5CF0); // Violet: Your partner
  static const Color partnerLight = Color(0xFF9B87F5);
  static const Color partnerTint = Color(0xFFC9B8FF);
  static const Color partnerSoft = Color(0xFFEDE4FF);
  static const Color partnerText = Color(0xFF4B3A8C);

  // ACCENTS
  static const Color butter = Color(0xFFFFD66B); // Reverse wordmark accent, streaks, stars
  static const Color butterSoft = Color(0xFFFFE7A3);
  static const Color butterText = Color(0xFF7A5200);
  static const Color mint = Color(0xFF6FCFA0);
  static const Color mintSoft = Color(0xFFE3F6EC);
  static const Color mintText = Color(0xFF1F7A4F);
  static const Color blue = Color(0xFF3F5FA8);
  static const Color coral = Color(0xFFFF8A6B);

  // NEUTRALS & STRUCTURE
  static const Color ink = Color(0xFF2B1B26); // Wordmark text, main headings
  static const Color muted = Color(0xFF7A6672); // Subtitles, captions, inactive state
  static const Color border = Color(0xFFF8D8E6); // Standard 1.5px card & input border
  static const Color borderStrong = Color(0xFFE7B9CE); // Active selection border
  static const Color card = Color(0xFFFFFFFF); // Solid white card fill
  static const Color danger = Color(0xFFD13A4F);

  // BACKWARDS-COMPATIBILITY ALIASES
  static const Color primarySoft = pinkSoft;
  static const Color surface = card;
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  static const Color textMuted = Color(0xFFA5929F);
  static const Color accent = partner;
  static const Color gold = butter;
  static const Color goldDark = butterText;
  static const Color success = mint;
  static const Color error = danger;
  static const Color divider = border;
  static const Color sanctumBackground = pinkSoft;

  // Social Colors
  static const Color whatsapp = Color(0xFF25D366);
  static const Color telegram = Color(0xFF0088CC);
  static const Color instagram = Color(0xFFE4405F);
  static const Color facebook = Color(0xFF1877F2);

  // Flat 1.5px Border Definition (Strict Flat Protocol)
  static const BorderSide defaultBorderSide = BorderSide(color: border, width: 1.5);
  static const BorderSide focusedBorderSide = BorderSide(color: primary, width: 2.0);

  // Gradients for backwards-compatibility (solid-fallback style)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [butter, butterText],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [partner, partnerLight],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x4DFFFFFF), Color(0x1AFFFFFF)],
  );

  // Zero-elevation shadow definitions (No shadows in new flat design)
  static const List<BoxShadow> softShadow = [];
  static const List<BoxShadow> premiumShadow = [];
  static const List<BoxShadow> buttonShadow = [];
  static const List<BoxShadow> deepShadow = [];
  static const List<BoxShadow> inputShadow = [];
  static const List<BoxShadow> cardShadow = [];
}

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double cardGap = 10.0;
  static const double sectionGap = 12.0;
  static const double m = 16.0;
  static const double page = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double badge = 12.0;
  static const double s = 12.0;
  static const double input = 18.0;
  static const double m = 18.0;
  static const double card = 22.0;
  static const double l = 22.0;
  static const double hero = 28.0;
  static const double xl = 28.0;
  static const double pill = 27.0;
  static const double xxl = 32.0;
  static const double circle = 100.0;
}

/// NextMeet Typography Scale using Nunito 600 and 800
/// Strictly adhering to NextMeet Redesign.pdf (Page 85)
class AppTextStyles {
  // New Design System Text Styles
  static TextStyle display = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  static TextStyle title1 = GoogleFonts.nunito(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static TextStyle title2 = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );

  static TextStyle heading = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static TextStyle body = GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle label = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.muted,
    letterSpacing: 1.0,
  );

  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );

  static TextStyle button = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // Backwards-compatible aliases
  static TextStyle get bodySecondary => caption;
  static TextStyle get h1 => display;
  static TextStyle get h2 => title1;
  static TextStyle get h3 => title2;
  static TextStyle get bodyL => body;
  static TextStyle get bodyM => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static TextStyle get bodyS => caption;
}

/// Paths to Brand Logo and Mascot Assets
class AppAssets {
  static const String logoHorizontalPng = 'assets/images/logo/logo-horizontal-2400.png';
  static const String logoHorizontalSvg = 'assets/images/logo/logo-horizontal.svg';
  static const String logoStackedPng = 'assets/images/logo/logo-stacked-1600.png';
  static const String logoStackedSvg = 'assets/images/logo/logo-stacked.svg';
  static const String logoMarkPng = 'assets/images/logo/logo-mark-1024.png';
  static const String logoMarkSvg = 'assets/images/logo/logo-mark.svg';
  static const String appIconPng = 'assets/images/logo/app-icon-1024.png';
  static const String appIconRoundedPng = 'assets/images/logo/app-icon-rounded-512.png';
  static const String mascotsPng = 'assets/images/mascots/mascots.png';
  static const String mascotsSvg = 'assets/images/mascots/mascots.svg';
  static const String logoWordmarkSvg = 'assets/images/logo/logo-wordmark.svg';
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
