import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'services/theme_service.dart';

class AppTheme {
  static ThemeData get lightTheme => getTheme(ThemeService.instance.themeIndex);

  static ThemeData getTheme(int themeIndex) {
    Color primary;
    Color background;
    Color secondary;

    switch (themeIndex) {
      case 1: // Midnight Violet
        primary = const Color(0xFF7B5CF0);
        background = const Color(0xFFF7F4FF);
        secondary = const Color(0xFFD81B6A);
        break;
      case 2: // Mint Garden
        primary = const Color(0xFF1F7A4F);
        background = const Color(0xFFF0FAF5);
        secondary = const Color(0xFF6FCFA0);
        break;
      case 3: // Sunset Glow
        primary = const Color(0xFFE65100);
        background = const Color(0xFFFFF6EE);
        secondary = const Color(0xFFFF8A6B);
        break;
      case 0: // Blush Romantic (Default)
      default:
        primary = const Color(0xFFD81B6A);
        background = const Color(0xFFFFF4F8);
        secondary = const Color(0xFF7B5CF0);
        break;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        // ignore: deprecated_member_use
        background: background,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: AppTextStyles.display,
        displayMedium: AppTextStyles.title1,
        displaySmall: AppTextStyles.title2,
        titleLarge: AppTextStyles.heading,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyM,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
        labelSmall: AppTextStyles.label,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.m,
            horizontal: AppSpacing.l,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 2.0),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        color: AppColors.card,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.5,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title1,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
