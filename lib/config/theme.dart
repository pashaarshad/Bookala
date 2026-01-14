import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette - "Cool & Simple"
  // Primary: Sophisticated Midnight Blue
  static const Color primaryColor = Color(
    0xFF3B82F6,
  ); // Bright Royal Blue for visibility
  static const Color secondaryColor = Color(0xFF6366F1); // Indigo accent

  // Background: Deep, rich dark mode (not just flat black)
  static const Color backgroundColor = Color(0xFF0F1117); // darker, cooler
  static const Color surfaceColor = Color(0xFF181B24); // slightly lighter
  static const Color cardColor = Color(0xFF222530); // for cards

  // Functional Colors
  static const Color creditColor = Color(0xFF10B981); // Emerald
  static const Color debitColor = Color(0xFFEF4444); // Red
  static const Color nearbyColor = Color(0xFFF59E0B); // Amber
  static const Color successColor = Color(0xFF22C55E);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Gradients - Subtle and Premium
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue to Darker Blue
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF222530), Color(0xFF1F222C)],
  );

  static const LinearGradient creditGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  static const LinearGradient debitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  );

  // Border Radius - Rounded but cleanly
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusXL = 32.0;

  // Shadows - Soft and ambient
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.25),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Theme Data with Serif Fonts (Merriweather)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: debitColor,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),

    // TYPOGRAPHY - "Times Roman letters" -> Merriweather (Classic Serif)
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.merriweather(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.merriweather(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.lato(
        // Clean sans for UI elements
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.merriweather(
        // Serif for body text for readability and style
        fontSize: 16,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.merriweather(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.lato(
        // Sans for small labels/metadata
        fontSize: 12,
        color: textMuted,
        fontWeight: FontWeight.w500,
      ),
    ),

    appBarTheme: AppBarThemeData(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: debitColor, width: 1),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: GoogleFonts.lato(color: textMuted),
      labelStyle: GoogleFonts.lato(color: textSecondary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor,
      contentTextStyle: GoogleFonts.lato(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    ),
  );
}
