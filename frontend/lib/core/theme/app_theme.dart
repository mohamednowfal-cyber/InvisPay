import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Fintech Palette (Neo-Bank)
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color secondary = Color(0xFF1E3A8A); // Deep Blue
  static const Color accent = Color(0xFF2DD4BF); // Soft Teal
  static const Color surface = Color(0xFF1E293B); // Slate-800 Surface
  static const Color error = Color(0xFFFF5252);

  // Auth Premium Design Tokens
  static const Color authTeal = Color(0xFF0D9488); // Teal 600
  static const Color authBlue = Color(0xFF2563EB); // Blue 600
  static const Color authNeutral = Color(0xFFF1F5F9); // Slate 100
  static const Color authSurface = Colors.white;
  static const Color authBorder = Color(0xFFE2E8F0); // Slate 200

  // High-Contrast Auth Text (Refined for Dark Backdrop)
  static const Color authTitle = Colors.white; // Pure White for focus
  static const Color authBody =
      Colors.white70; // High visibility supporting text
  static const Color authTitleLight = Color(0xFF0F172A); // Slate 900
  static const Color authBodyLight = Color(0xFF475569); // Slate 600

  static const Color authPrimary = Color(0xFF10B981); // Emerald 500
  static const Color authErrorMuted = Color(0xFFF87171); // Soft red
  static const Color authInputFill = Color(0xFFF8FAFC); // Very light slate

  // Premium Auth Gradient (Light) - Breathable but themed
  static const List<Color> authGradient = [
    Color(0xFFCCFBF1), // Teal 100
    Color(0xFFDBEAFE), // Blue 100
    Color(0xFFF8FAFC), // Slate 50
  ];

  // Premium Auth Gradient (Dark) - Deeper, Smoother, No banding
  static const List<Color> authGradientDark = [
    Color(0xFF042F2C), // Deeper Teal
    Color(0xFF0F172A), // Slate 900 Hub
    Color(0xFF020617), // Deepest Marine
  ];

  static const List<Color> authButtonGradient = [
    Color(0xFF0D9488), // Teal 600
    Color(0xFF1E3A8A), // Blue 800
  ];

  // Profile Premium Design Tokens
  static const List<Color> profileHeaderGradient = [
    Color(0xFFE0F2F1), // Teal 50
    Color(0xFFE3F2FD), // Blue 50
  ];
  static const List<Color> profileCardGradient = [
    Color(0xFFF1F5F9), // Slate 100
    Color(0xFFF8FAFC), // Slate 50
  ];
  static const List<Color> qrBackgroundGradient = [
    Color(0xFFF1F5F9),
    Colors.white,
  ];

  static const List<Color> inputGradient = [
    Color(0xFFE0F2F1), // Light Teal 50
    Color(0xFFF1F5F9), // Slate 100
  ];

  static const Color backgroundLight = Color(0xFF334155); // Slate-700
  static const Color backgroundDark =
      Color(0xFF0F172A); // Slate-900 (Main Background)

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),

      // Typography Optimized for Multi-Language & RTL
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          height: 1.6,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          height: 1.6,
          letterSpacing: 0.1,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2D3E),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFF2563EB), // Blue for light mode
        surface: Color(0xFFF8FAFC), // Slate 50
        error: Color(0xFFDC2626), // Red 600
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A), // Slate 900
      ),

      // Typography for Light Mode
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFF1E293B), // Slate 800
          height: 1.6,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFF64748B), // Slate 500
          height: 1.6,
          letterSpacing: 0.1,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // Slate 400
        labelStyle: const TextStyle(color: Color(0xFF475569)), // Slate 600
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFE2E8F0), // Slate 200 border
            width: 1,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary, // Emerald green
        unselectedItemColor: Color(0xFF64748B), // Slate 500
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      iconTheme: const IconThemeData(
        color: Color(0xFF0F172A), // Dark icons for light mode
      ),
    );
  }
}
