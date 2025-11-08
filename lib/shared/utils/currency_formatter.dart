import 'package:intl/intl.dart';

/// Central currency formatting (Yemeni Riyal - ر.ي)
class CurrencyFormatter {
  static const String symbol = 'ر.ي';
  static final NumberFormat _intFormat = NumberFormat('#,##0', 'ar');
  static final NumberFormat _doubleFormat = NumberFormat('#,##0.##', 'ar');

  static String format(num value, {bool allowDecimals = false}) {
    if (!allowDecimals) {
      return '${_intFormat.format(value)} $symbol';
    }
    return '${_doubleFormat.format(value)} $symbol';
  }

  static String formatInt(int value) => '${_intFormat.format(value)} $symbol';

  /// Formats delta style with sign +value / -value preserving currency.
  static String formatSigned(num value, {bool allowDecimals = false}) {
    final sign = value > 0
        ? '+'
        : value < 0
            ? '-'
            : '';
    final abs = value.abs();
    final core = allowDecimals
        ? _doubleFormat.format(abs)
        : _intFormat.format(abs.round());
    return '$sign$core $symbol';
  }

  /// Formats currency in compact form (K for thousands)
  static String formatCompact(num value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      return '${thousands.toStringAsFixed(0)}K $symbol';
    }
    return '${_intFormat.format(value)} $symbol';
  }
}
