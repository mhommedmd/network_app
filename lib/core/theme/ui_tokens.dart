import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Design system size tokens (raw logical pixels before any ScreenUtil scaling).
class UITokens {
  UITokens._();

  static const double navBarHeight = 48; // App / custom top bars
  static const double avatarSize = 32; // Standard circular avatar diameter
  static const double iconSize = 24; // Primary icon size

  // Corner radii (added for future consistency, low‑risk enhancement)
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
}

/// Centralized typography scale.
/// Only these sizes should be used directly; all custom text should derive from these.
class AppTypography {
  AppTypography._();

  static TextStyle get headline => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get subheadline => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.30,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.40,
      );

  static TextStyle get button => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.20,
        letterSpacing: 0.2,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  static TextStyle get micro => TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        height: 1.20,
      );

  /// Helper to apply a color quickly while keeping token reference explicit.
  static TextStyle withColor(TextStyle base, Color? color) =>
      color == null ? base : base.copyWith(color: color);
}

extension TypographyColorX on TextStyle {
  TextStyle colored(Color? c) => c == null ? this : copyWith(color: c);
}
