// lib/theme/colors.dart
import 'package:flutter/material.dart';
 
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF5BB7FF);
  static const Color primaryMint = Color(0xFF8CE6B8);
  static const Color accentPeach = Color(0xFFFFB49A);
  static const Color accentSun = Color(0xFFFFD37A);

  static const Color surface = Color(0xFFF5F7F9);
  static const Color surfaceAlt = Color(0xFFF1F3F6);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F1724);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color success = Color(0xFF2DD4BF);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
  static const Color divider = Color(0xFFE6E9ED);
  static const Color iconSurface = Color(0xFFECEFF3);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryMint],
  );

  static const LinearGradient warmAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPeach, accentSun],
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color.fromRGBO(4, 10, 25, 0.06),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

ColorScheme buildColorScheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final seed = const Color(0xFF5BB7FF);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    surface: AppColors.surface,
  );
  return scheme.copyWith(
    primary: seed,
    onPrimary: Colors.white,
    surface: isDark ? const Color(0xFF0F172A) : AppColors.surface,
    onSurface: isDark ? Colors.white : AppColors.textPrimary,
    error: AppColors.error,
  );
}

