import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Emerald Green Luxury Palette - فرع القوات الجوية
  static const Color primaryBlue = Color(0xFF007A5E); // Rich Royal Emerald Green
  static const Color primaryLight = Color(0xFF00A87E); // Vibrant Emerald
  static const Color accentCyan = Color(0xFF10B981);  // Mint / Emerald Accent
  static const Color accentTeal = Color(0xFF059669);  // Deep Forest Mint
  static const Color backgroundLight = Color(0xFFF0F8F5); // Fresh Soft Mint White
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF14241E);
  static const Color textMuted = Color(0xFF5E7369);

  // Status colors
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFED6C02);
  static const Color errorRed = Color(0xFFD32F2F);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: accentCyan,
        onSecondary: Colors.white,
        tertiary: accentTeal,
        surface: surfaceWhite,
        onSurface: textDark,
        error: errorRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 1.5,
        shadowColor: primaryBlue.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blueGrey.withOpacity(0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
