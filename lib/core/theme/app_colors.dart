import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Blue theme)
  static const Color primary = Color(0xFF2563EB); // blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // blue-700

  // Secondary Colors
  static const Color secondary = Color(0xFF6366F1); // indigo-500
  static const Color secondaryLight = Color(0xFF8B5CF6); // violet-500
  static const Color secondaryDark = Color(0xFF4338CA); // indigo-700

  // Status Colors
  static const Color success = Color(0xFF059669); // emerald-600
  static const Color successLight = Color(0xFF10B981); // emerald-500
  static const Color successDark = Color(0xFF047857); // emerald-700

  static const Color warning = Color(0xFFD97706); // amber-600
  static const Color warningLight = Color(0xFFF59E0B); // amber-500
  static const Color warningDark = Color(0xFFB45309); // amber-700

  static const Color error = Color(0xFFDC2626); // red-600
  static const Color errorLight = Color(0xFFEF4444); // red-500
  static const Color errorDark = Color(0xFFB91C1C); // red-700

  // Info Colors (Blue/Cyan tone)
  static const Color info = Color(0xFF0284C7); // sky-600
  static const Color infoLight = Color(0xFF0EA5E9); // sky-500
  static const Color infoDark = Color(0xFF0369A1); // sky-700

  // Gray Scale with blue undertones
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // Blue variants
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  // Indigo variants
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue600, blue700],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo500, indigo600],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successLight],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, warningLight],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, errorLight],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [info, infoLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue50, indigo100],
  );

  // Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: gray900,
    outline: gray300,
    shadow: Color(0x1A000000),
  );

  // Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryLight,
    onPrimary: Colors.white,
    secondary: secondaryLight,
    onSecondary: Colors.white,
    error: errorLight,
    onError: Colors.white,
    surface: gray800,
    onSurface: gray100,
    outline: gray600,
    shadow: Color(0x33000000),
  );

  // Helper methods for creating colors with opacity
  static Color withOpacity(Color color, double opacity) {
    // Use the modern Color.withValues API to avoid deprecated withOpacity
    return color.withValues(alpha: opacity);
  }

  // Shadow colors
  static Color primaryShadow = primary.withValues(alpha: 0.2);
  static Color secondaryShadow = secondary.withValues(alpha: 0.2);
  static Color successShadow = success.withValues(alpha: 0.2);
  static Color warningShadow = warning.withValues(alpha: 0.2);
  static Color errorShadow = error.withValues(alpha: 0.2);
  static Color infoShadow = info.withValues(alpha: 0.2);
}
