import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Renkler ──────────────────────────────────────────────
  static const Color black      = Color(0xFF0A0A0A);
  static const Color surface    = Color(0xFF1C1C1C);
  static const Color card       = Color(0xFF242424);
  static const Color gold       = Color(0xFFD4A574);
  static const Color goldDark   = Color(0xFFB8860B);
  static const Color goldLight  = Color(0xFFEDD9A3);
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color success    = Color(0xFF4CAF50);
  static const Color error      = Color(0xFFE53935);
  static const Color slotGreen  = Color(0xFF2E7D32);
  static const Color slotRed    = Color(0xFFC62828);

  // ── Gradyanlar ───────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A574), Color(0xFF8B6914)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1C1500), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Tema ─────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: black,
    primaryColor: gold,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: goldDark,
      surface: surface,
      error: error,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.playfairDisplay(
        color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.playfairDisplay(
        color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.playfairDisplay(
        color: Colors.white, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: gold, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: const IconThemeData(color: gold),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF333333)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: gold, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: error),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: error),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    dividerColor: const Color(0xFF2A2A2A),
  );
}
