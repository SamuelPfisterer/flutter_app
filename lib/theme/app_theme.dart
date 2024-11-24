import 'package:flutter/material.dart';

class AppColors {
  // Primary theme colors
  static const Color primary = Color(0xFF8B4513);
  static const Color surface = Color(0xFFFFF1EC);
  static const Color background = Color(0xFFFAF3F3);
  static const Color secondary = Color(0xFFFFE4D6);
  
  // User distinction colors
  static const Color userColor = Color(0xFFFFD6C4);    // Warmer, brighter peach
  static const Color partnerColor = Color(0xFFDDE8D4);  // Softer, more muted green
  
  // Text colors
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF2D2D2D);
  static const Color onBackground = Color(0xFF2D2D2D);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
        secondary: AppColors.secondary,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        onBackground: AppColors.onBackground,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppColors.secondary,
        elevation: 0,
      ),
    );
  }
} 