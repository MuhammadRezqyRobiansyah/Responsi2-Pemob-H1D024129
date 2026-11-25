import 'package:flutter/material.dart';

/// Centralized color palette, glassmorphism tokens, and Material 3 Theme.
class AppTheme {
  AppTheme._();

  // Atmospheric sage-slate to deep forest teal palette
  static const Color bgTopSage = Color(0xFF6B817E);
  static const Color bgMidSlate = Color(0xFF4B6563);
  static const Color bgBottomTeal = Color(0xFF173334);
  static const Color bgDeepShadow = Color(0xFF0A1E1F);

  static const Color glowFrost = Color(0xFFD7E4E1);
  static const Color glowMist = Color(0xFF9FB4B0);

  // Primary & surface accents
  static const Color deepForestTeal = Color(0xFF0E3B3E);
  static const Color navPillDark = Color(0xFF0B3234);

  // Secondary accents
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color softSkyBlue = Color(0xFF38BDF8);
  static const Color rainBlue = Color(0xFF0284C7);
  static const Color dangerCoral = Color(0xFFEF4444);

  // Typography colors
  static const Color textPrimary = Color(0xFF0E2122);
  static const Color textSecondary = Color(0xFF213A3B);
  static const Color textMuted = Color(0xFF2E494A);
  static const Color textOnDark = Color(0xFFF3F7F6);
  static const Color textSubtleOnDark = Color(0xFFD0DFDC);

  // Glassmorphism styling
  static const double cardRadius = 24.0;
  static const double glassBlurSigma = 18.0;

  static BoxDecoration glassDecoration({
    double radius = cardRadius,
    double topAlpha = 0.40,
    double bottomAlpha = 0.25,
    double borderAlpha = 0.42,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: topAlpha),
          Colors.white.withValues(alpha: bottomAlpha),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: borderAlpha),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: bgDeepShadow.withValues(alpha: 0.14),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: deepForestTeal,
      brightness: Brightness.light,
      primary: deepForestTeal,
      secondary: softSkyBlue,
      tertiary: warmAmber,
      surface: const Color(0xFFE7EFEA),
    );

    const baseTextTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        color: textPrimary,
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: textMuted,
      ),
      labelMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: textOnDark,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'PlusJakartaSans',
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: bgTopSage,
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepForestTeal,
        contentTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: textOnDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFE7EFEC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
