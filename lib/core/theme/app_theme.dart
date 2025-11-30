import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // 🎨 COLOR PALETTE (PREMIUM)
  // ---------------------------------------------------------------------------

  // Brand Colors
  static const Color primaryColor = Color(0xFF6C63FF); // Deep Purple
  static const Color primaryVariant = Color(0xFF5A52D5);
  static const Color secondaryColor = Color(0xFF00D9C0); // Teal/Cyan
  static const Color accentColor = Color(0xFFFFB800); // Gold
  static const Color accentVariant = Color(0xFFFFD600);

  // Semantic Colors
  static const Color successColor = Color(0xFF00E676);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Neutral Colors (Light Mode)
  static const Color backgroundLight = Color(
    0xFFF8F9FC,
  ); // Very light grey-blue
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2F5);
  static const Color textPrimaryLight = Color(0xFF1A1D1E);
  static const Color textSecondaryLight = Color(0xFF6C7278);
  static const Color textTertiaryLight = Color(0xFF9AA0A6);

  // Neutral Colors (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F1115); // Deep almost-black
  static const Color surfaceDark = Color(0xFF181A20);
  static const Color surfaceVariantDark = Color(0xFF262A34);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);
  static const Color textTertiaryDark = Color(0xFF6E7179);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFFD600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF181A20), Color(0xFF262A34)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------------------------------------------------------------------------
  // 📐 SPACING & RADIUS
  // ---------------------------------------------------------------------------

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  // ---------------------------------------------------------------------------
  // 🌓 THEME DATA BUILDERS
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      error: errorColor,
      onError: Colors.white,
      surface: isLight ? surfaceLight : surfaceDark,
      onSurface: isLight ? textPrimaryLight : textPrimaryDark,
      surfaceContainerHighest: isLight
          ? surfaceVariantLight
          : surfaceVariantDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight ? backgroundLight : backgroundDark,
      fontFamily: 'Manrope',

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isLight ? textPrimaryLight : textPrimaryDark,
        ),
        iconTheme: IconThemeData(
          color: isLight ? textPrimaryLight : textPrimaryDark,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: isLight ? textPrimaryLight : textPrimaryDark,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: isLight ? textPrimaryLight : textPrimaryDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isLight ? textPrimaryLight : textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLight ? textPrimaryLight : textPrimaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: isLight ? textSecondaryLight : textSecondaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: isLight ? textSecondaryLight : textSecondaryDark,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isLight ? textTertiaryLight : textTertiaryDark,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? surfaceVariantLight : surfaceVariantDark,
        contentPadding: const EdgeInsets.all(space16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isLight ? textTertiaryLight : textTertiaryDark,
          fontSize: 14,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isLight
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.05),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔄 BACKWARD COMPATIBILITY & ALIASES
  // ---------------------------------------------------------------------------

  // Background Colors
  static const Color backgroundColor = backgroundLight;
  static const Color surfaceColor = surfaceLight;
  static const Color surfaceVariant = surfaceVariantLight;

  // Dark Mode Colors (Legacy)
  static const Color darkBackgroundColor = backgroundDark;
  static const Color darkSurfaceColor = surfaceDark;
  static const Color darkSurfaceVariant = surfaceVariantDark;
  static const Color darkTextPrimary = textPrimaryDark;
  static const Color darkTextSecondary = textSecondaryDark;
  static const Color darkTextTertiary = textTertiaryDark;

  // Text Colors
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textTertiary = textTertiaryLight;

  // Legacy Colors
  static const Color tertiaryColor = accentColor;

  // Spacing
  static const double space2 = 2.0;
  static const double space28 = 28.0;
  static const double space40 = 40.0;
  static const double space56 = 56.0;

  // Shadows
  static List<BoxShadow> get cardShadow => softShadow;
  static List<BoxShadow> get elevatedShadow => glowShadow;

  // ---------------------------------------------------------------------------
  // 🛠 UTILITIES
  // ---------------------------------------------------------------------------

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration glassMorphism(
    BuildContext context, {
    double opacity = 0.1,
  }) {
    return glassDecoration(context);
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      ),
    );
  }
}
