import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  const AppColors._();

  // ---------------------------------------------------------------------------
  // PRIMARY BRAND COLORS
  // ---------------------------------------------------------------------------
  // A deep, trustworthy blue-purple for primary actions
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400

  // A vibrant but professional accent for highlights (e.g., earnings)
  static const Color accent = Color(0xFF0EA5E9); // Sky 500
  static const Color accentDark = Color(0xFF0284C7); // Sky 600

  // ---------------------------------------------------------------------------
  // SEMANTIC COLORS
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // ---------------------------------------------------------------------------
  // NEUTRAL COLORS (Light Mode)
  // ---------------------------------------------------------------------------
  static const Color backgroundLight = Color(0xFFF9FAFB); // Gray 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color surfaceVariantLight = Color(0xFFF3F4F6); // Gray 100

  static const Color textPrimaryLight = Color(0xFF111827); // Gray 900
  static const Color textSecondaryLight = Color(0xFF4B5563); // Gray 600
  static const Color textTertiaryLight = Color(0xFF9CA3AF); // Gray 400

  static const Color borderLight = Color(0xFFE5E7EB); // Gray 200

  // ---------------------------------------------------------------------------
  // NEUTRAL COLORS (Dark Mode)
  // ---------------------------------------------------------------------------
  static const Color backgroundDark = Color(0xFF111827); // Gray 900
  static const Color surfaceDark = Color(0xFF1F2937); // Gray 800
  static const Color surfaceVariantDark = Color(0xFF374151); // Gray 700

  static const Color textPrimaryDark = Color(0xFFF9FAFB); // Gray 50
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // Gray 300
  static const Color textTertiaryDark = Color(0xFF9CA3AF); // Gray 400

  static const Color borderDark = Color(0xFF374151); // Gray 700

  // ---------------------------------------------------------------------------
  // GRADIENTS (Subtle & Professional)
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
