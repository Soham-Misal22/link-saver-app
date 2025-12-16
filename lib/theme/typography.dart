// lib/theme/typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
 
class AppTypography {
  AppTypography._();
 
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme();
    final onSurface = buildColorScheme(brightness).onSurface;
    return base.copyWith(
      displaySmall: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, color: onSurface),
      headlineSmall: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, color: onSurface),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.35, color: onSurface),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.35, color: onSurface),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
    );
  }
}

