import 'package:flutter/material.dart';
import 'package:klikin/core/theme/app_colors.dart';
import 'package:klikin/core/theme/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgObsidian,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricEmerald,
        surface: AppColors.surfaceSlate,
        error: AppColors.crimsonAlert,
        onPrimary: AppColors.textDark,
        onSurface: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.strokeSubtle, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgObsidian,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMd,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
