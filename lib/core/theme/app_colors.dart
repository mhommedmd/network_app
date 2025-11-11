import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0082FB);
  static const Color primaryLight = Color(0xFF4DA6FF);
  static const Color primaryDark = Color(0xFF0064E0);

  // Secondary Colors
  static const Color secondary = Color(0xFF0064E0);
  static const Color secondaryLight = Color(0xFF3389FF);
  static const Color secondaryDark = Color(0xFF004BB8);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C2B33);

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
  static const Color gray50 = Color(0xFFF5F7FA);
  static const Color gray100 = Color(0xFFEFF2F6);
  static const Color gray200 = Color(0xFFE0E6EC);
  static const Color gray300 = Color(0xFFCAD4DD);
  static const Color gray400 = textPrimary;
  static const Color gray500 = textPrimary;
  static const Color gray600 = textPrimary;
  static const Color gray700 = textPrimary;
  static const Color gray800 = textPrimary;
  static const Color gray900 = textPrimary;

  // Blue variants
  static const Color blue50 = Color(0xFFE5F2FF);
  static const Color blue100 = Color(0xFFCCE6FF);
  static const Color blue200 = Color(0xFF99CDFF);
  static const Color blue300 = Color(0xFF66B4FF);
  static const Color blue400 = Color(0xFF33A0FF);
  static const Color blue500 = primary;
  static const Color blue600 = primaryDark;
  static const Color blue700 = Color(0xFF0057C0);
  static const Color blue800 = Color(0xFF004899);
  static const Color blue900 = Color(0xFF003B7A);

  // Indigo variants
  static const Color indigo50 = Color(0xFFE7F0FF);
  static const Color indigo100 = Color(0xFFD1E0FF);
  static const Color indigo200 = Color(0xFFA3C1FF);
  static const Color indigo300 = Color(0xFF75A1FF);
  static const Color indigo400 = Color(0xFF4782FF);
  static const Color indigo500 = secondary;
  static const Color indigo600 = secondaryDark;
  static const Color indigo700 = Color(0xFF003F99);
  static const Color indigo800 = Color(0xFF003580);
  static const Color indigo900 = Color(0xFF002966);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue500, blue700],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
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
    onSurface: textPrimary,
    outline: gray300,
    shadow: Color(0x1A000000),
  );

  // Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
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
