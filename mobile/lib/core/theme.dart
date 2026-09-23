import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Soft Accents (Pastel Colorful Theme)
  static const primary = Color(0xFF9EA8FF); // Soft Periwinkle/Indigo
  static const primaryLight = Color(0xFFE0E7FF);
  static const accent = Color(0xFFFFB3B3); // Soft Coral/Pink
  
  // Backgrounds
  static const background = Color(0xFFF7F9FC); // Very light cool grey/blue
  static const surface = Color(0xFFFFFFFF); // Pure white
  static const border = Color(0xFFE2E8F0); // Light gray
  
  // Text
  static const textSecondary = Color(0xFF64748B); // Slate 500
  static const textBody = Color(0xFF475569); // Slate 600
  static const textHeader = Color(0xFF0F172A); // Slate 900
  
  // Warning/Secondary
  static const amber = Color(0xFFFFD6A5); // Soft Orange/Peach
  
  // Extra Soft Colors for UI
  static const softBlue = Color(0xFFE3F2FD);
  static const softGreen = Color(0xFFE8F5E9);
  static const softPink = Color(0xFFFCE4EC);
  static const softPurple = Color(0xFFF3E5F5);
  static const softYellow = Color(0xFFFFF9C4);
  static const softOrange = Color(0xFFFFF3E0);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textHeader,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textBody,
        displayColor: AppColors.textHeader,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textHeader),
        titleTextStyle: TextStyle(color: AppColors.textHeader, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
