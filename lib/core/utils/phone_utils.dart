class PhoneUtils {
  const PhoneUtils._();

  static const List<String> _validYemeniPrefixes = [
    '777',
    '773',
    '770',
    '771',
    '772',
    '774',
    '775',
    '776',
    '778',
    '779',
    '733',
    '734',
    '735',
    '736',
    '737',
    '738',
    '739',
    '730',
    '731',
    '732',
    '780',
    '781',
    '782',
    '783',
    '784',
    '785',
    '786',
    '787',
    '788',
    '789',
  ];

  /// Returns the normalized 9-digit local Yemeni mobile number without the country code.
  /// Returns null when the phone number cannot be normalized to a valid Yemeni number.
  static String? normalizeYemeniPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('00967') && digits.length >= 14) {
      digits = digits.substring(5);
    } else if (digits.startsWith('967') && digits.length >= 12) {
      digits = digits.substring(3);
    }

    if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }

    if (digits.length != 9) return null;
    if (!_validYemeniPrefixes.any(digits.startsWith)) return null;

    return digits;
  }

  static bool isValidYemeniPhone(String phone) => normalizeYemeniPhone(phone) != null;

  static String? formatToE164(String phone) {
    final normalized = normalizeYemeniPhone(phone);
    if (normalized == null) return null;
    return '+967$normalized';
  }

  static List<String> get validPrefixes => List.unmodifiable(_validYemeniPrefixes);
}


