import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Manrope';

  // ---------------------------------------------------------------------------
  // TEXT STYLES (Light Mode)
  // ---------------------------------------------------------------------------
  static TextTheme get lightTextTheme => TextTheme(
    displayLarge: _baseStyle(
      32,
      FontWeight.w800,
      AppColors.textPrimaryLight,
      -1.0,
    ),
    displayMedium: _baseStyle(
      28,
      FontWeight.w700,
      AppColors.textPrimaryLight,
      -0.5,
    ),
    displaySmall: _baseStyle(
      24,
      FontWeight.w700,
      AppColors.textPrimaryLight,
      0,
    ),

    headlineMedium: _baseStyle(
      20,
      FontWeight.w600,
      AppColors.textPrimaryLight,
      0,
    ),
    headlineSmall: _baseStyle(
      18,
      FontWeight.w600,
      AppColors.textPrimaryLight,
      0,
    ),

    titleLarge: _baseStyle(16, FontWeight.w600, AppColors.textPrimaryLight, 0),
    titleMedium: _baseStyle(
      14,
      FontWeight.w600,
      AppColors.textPrimaryLight,
      0.1,
    ),
    titleSmall: _baseStyle(
      12,
      FontWeight.w600,
      AppColors.textSecondaryLight,
      0.1,
    ),

    bodyLarge: _baseStyle(
      16,
      FontWeight.w400,
      AppColors.textSecondaryLight,
      0,
      height: 1.5,
    ),
    bodyMedium: _baseStyle(
      14,
      FontWeight.w400,
      AppColors.textSecondaryLight,
      0,
      height: 1.5,
    ),
    bodySmall: _baseStyle(
      12,
      FontWeight.w400,
      AppColors.textTertiaryLight,
      0,
      height: 1.5,
    ),

    labelLarge: _baseStyle(14, FontWeight.w600, AppColors.primary, 0.5),
    labelMedium: _baseStyle(
      12,
      FontWeight.w600,
      AppColors.textSecondaryLight,
      0.5,
    ),
    labelSmall: _baseStyle(
      10,
      FontWeight.w700,
      AppColors.textTertiaryLight,
      0.5,
    ),
  );

  // ---------------------------------------------------------------------------
  // TEXT STYLES (Dark Mode)
  // ---------------------------------------------------------------------------
  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: _baseStyle(
      32,
      FontWeight.w800,
      AppColors.textPrimaryDark,
      -1.0,
    ),
    displayMedium: _baseStyle(
      28,
      FontWeight.w700,
      AppColors.textPrimaryDark,
      -0.5,
    ),
    displaySmall: _baseStyle(24, FontWeight.w700, AppColors.textPrimaryDark, 0),

    headlineMedium: _baseStyle(
      20,
      FontWeight.w600,
      AppColors.textPrimaryDark,
      0,
    ),
    headlineSmall: _baseStyle(
      18,
      FontWeight.w600,
      AppColors.textPrimaryDark,
      0,
    ),

    titleLarge: _baseStyle(16, FontWeight.w600, AppColors.textPrimaryDark, 0),
    titleMedium: _baseStyle(
      14,
      FontWeight.w600,
      AppColors.textPrimaryDark,
      0.1,
    ),
    titleSmall: _baseStyle(
      12,
      FontWeight.w600,
      AppColors.textSecondaryDark,
      0.1,
    ),

    bodyLarge: _baseStyle(
      16,
      FontWeight.w400,
      AppColors.textSecondaryDark,
      0,
      height: 1.5,
    ),
    bodyMedium: _baseStyle(
      14,
      FontWeight.w400,
      AppColors.textSecondaryDark,
      0,
      height: 1.5,
    ),
    bodySmall: _baseStyle(
      12,
      FontWeight.w400,
      AppColors.textTertiaryDark,
      0,
      height: 1.5,
    ),

    labelLarge: _baseStyle(14, FontWeight.w600, AppColors.primaryLight, 0.5),
    labelMedium: _baseStyle(
      12,
      FontWeight.w600,
      AppColors.textSecondaryDark,
      0.5,
    ),
    labelSmall: _baseStyle(
      10,
      FontWeight.w700,
      AppColors.textTertiaryDark,
      0.5,
    ),
  );

  static TextStyle _baseStyle(
    double size,
    FontWeight weight,
    Color color,
    double letterSpacing, {
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
