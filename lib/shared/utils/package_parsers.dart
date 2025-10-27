import 'dart:math';

/// Utilities for parsing and formatting package-related values.
/// Centralizing logic avoids duplicated ad-hoc regex across pages.
class PackageParsers {
  /// Parses size labels like:
  ///  - '3 جيجا'
  ///  - '1.5 جيجا'
  ///  - '500 ميجا'
  /// Returns size in megabytes (MB).
  static int parseSizeToMb(String label) {
    final number =
        double.tryParse(label.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;
    if (label.contains('جيجا')) {
      return (number * 1024).round();
    }
    return number.round();
  }

  /// Formats MB into a localized size like '3 جيجا' or '850 ميجا'.
  static String formatSizeFromMb(int sizeInMb) {
    if (sizeInMb >= 1024) {
      final gb = sizeInMb / 1024;
      if (gb % 1 == 0) return '${gb.toInt()} جيجا';
      return '${gb.toStringAsFixed(1)} جيجا';
    }
    return '$sizeInMb ميجا';
  }

  /// Parse validity string like '24 ساعة', '7 أيام', '30 يوم'.
  /// Returns the days component (0 if only hours).
  static int parseValidityDays(String validity) {
    if (validity.contains('يوم')) {
      final v = int.tryParse(validity.replaceAll(RegExp('[^0-9]'), ''));
      return v ?? 0;
    }
    return 0;
  }

  /// Parse validity hours component from strings containing 'ساعة'.
  static int parseValidityHours(String validity) {
    if (validity.contains('ساعة')) {
      final v = int.tryParse(validity.replaceAll(RegExp('[^0-9]'), ''));
      return v ?? 0;
    }
    return 0;
  }

  /// Derive an approximate human label combining days & hours if both exist.
  static String composeValidityLabel({required int days, required int hours}) {
    if (days > 0 && hours > 0) return '$days يوم / $hours ساعة';
    if (days > 0) return '$days يوم';
    if (hours > 0) return '$hours ساعة';
    return 'غير محدد';
  }

  /// Safe percentile calculation for profit margins or similar metrics.
  static double safePercent(num part, num whole) {
    if (whole == 0) return 0;
    return (part / whole) * 100;
  }

  /// Clamp helper.
  static int clampInt(int value, int minValue, int maxValue) =>
      max(minValue, min(value, maxValue));
}
