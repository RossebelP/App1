// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color bgDark = Color(0xFF0d0d1a);
  static const Color bgHeader = Color(0xFF1a1a2e);
  static const Color bgCard = Color(0xFF16213e);
  static const Color bgCardAlt = Color(0xFF1a1a2e);
  static const Color surface = Color(0xFF0f3460);
  static const Color primary = Color(0xFF1d9e75);
  static const Color primaryLight = Color(0xFF26c48f);
  static const Color primaryDim = Color(0xFF0d5c43);
  static const Color danger = Color(0xFFe74c6f);
  static const Color dangerDim = Color(0xFF6b1e33);
  static const Color warning = Color(0xFFf39c12);
  static const Color warningDim = Color(0xFF7a4d06);
  static const Color textPrimary = Color(0xFFf0f0f5);
  static const Color textSecondary = Color(0xFF8888aa);
  static const Color textMuted = Color(0xFF555577);
  static const Color border = Color(0xFF252545);
  static const Color uberEats = Color(0xFF06C167);
  static const Color rappi = Color(0xFFFF441F);
  static const Color didi = Color(0xFFFF6900);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgCard,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgHeader,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgHeader,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        overlayColor: Color(0x331d9e75),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryDim : AppColors.bgCard),
      ),
      dividerColor: AppColors.border,
    );
  }
}

class AppIcons {
  static const String uberEats = '🛵';
  static const String rappi = '🎒';
  static const String didi = '🍊';
  static const String check = '✓';
  static const String close = '✗';
}
