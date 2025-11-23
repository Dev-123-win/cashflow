import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF00D9C0);
  static const Color tertiaryColor = Color(0xFFFFB800);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF00E676);
  static const Color warningColor = Color(0xFFFFA726);

  // Light Theme Background Colors
  static const Color backgroundColor = Color(0xFFFAFAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F7);

  // Light Theme Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // Spacing
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Light Theme Only
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 1,
        centerTitle: false,
        shadowColor: const Color(0x1F000000),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Manrope',
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1,
        shadowColor: const Color(0x1F000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        contentPadding: const EdgeInsets.all(space16),
        hintStyle: const TextStyle(color: textSecondary, fontFamily: 'Manrope'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Manrope',
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Manrope',
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Manrope',
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Manrope',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          fontFamily: 'Manrope',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          fontFamily: 'Manrope',
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Manrope',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Shadows - Light theme appropriate
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x2F000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // Glass Morphism - Light theme
  static BoxDecoration glassMorphism({Color color = const Color(0xF0FFFFFF)}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: const Color(0x1F000000), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
