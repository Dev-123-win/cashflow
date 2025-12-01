import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/dimensions.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // THEME DATA BUILDERS
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? AppColors.primary : AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: isLight ? AppColors.accent : AppColors.accentDark,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      onSurface: isLight
          ? AppColors.textPrimaryLight
          : AppColors.textPrimaryDark,
      surfaceContainerHighest: isLight
          ? AppColors.surfaceVariantLight
          : AppColors.surfaceVariantDark,
      outline: isLight ? AppColors.borderLight : AppColors.borderDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.backgroundLight
          : AppColors.backgroundDark,
      fontFamily: AppTypography.fontFamily,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isLight
            ? AppColors.backgroundLight
            : AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: isLight
            ? AppTypography.lightTextTheme.headlineSmall
            : AppTypography.darkTextTheme.headlineSmall,
        iconTheme: IconThemeData(
          color: isLight
              ? AppColors.textPrimaryLight
              : AppColors.textPrimaryDark,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight ? AppColors.primary : AppColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Theme
      textTheme: isLight
          ? AppTypography.lightTextTheme
          : AppTypography.darkTextTheme,

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.surfaceLight
            : AppColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.all(AppDimensions.space16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(
          color: isLight
              ? AppColors.textTertiaryLight
              : AppColors.textTertiaryDark,
          fontSize: 14,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          side: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.borderLight : AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceLight
            : AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isLight
            ? AppColors.textTertiaryLight
            : AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
