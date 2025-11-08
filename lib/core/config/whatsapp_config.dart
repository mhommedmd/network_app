/// تكوين خدمة WhatsApp OTP
class WhatsAppConfig {
  /// API Key لخدمة wasenderapi
  ///
  /// ⚠️ ملاحظة أمنية: في الإنتاج، يجب تخزين API Key في:
  /// - متغيرات البيئة (Environment Variables)
  /// - Firebase Remote Config
  /// - ملف .env (غير مرفوع على Git)
  ///
  /// مثال استخدام .env:
  /// ```dart
  /// WASENDERAPI_KEY=your_api_key_here
  /// ```
  static const String apiKey = '8690a3071c2406d98af6ddcbb5badb3878c19f7f30299bffe117156fae7271f0';

  /// Base URL لخدمة wasenderapi
  static const String baseUrl = 'https://api.wasenderapi.com';

  /// مدة صلاحية رمز OTP بالدقائق
  static const int otpExpiryMinutes = 5;

  /// مدة الانتظار قبل إعادة إرسال OTP بالثواني
  static const int resendOtpCooldownSeconds = 60;

  /// طول رمز OTP
  static const int otpLength = 6;

  /// اسم التطبيق الظاهر في رسالة الواتساب
  static const String appName = 'تطبيق إدارة كروت الإنترنت';

  /// قالب رسالة OTP
  /// يمكن تخصيصه حسب الحاجة
  static String getOtpMessageTemplate({required String otp, String? recipientName}) {
    final greeting = recipientName != null ? 'مرحباً $recipientName،\n\n' : '';

    return '''
$greeting🔐 *رمز التحقق الخاص بك*

رمز التحقق: *$otp*

⏰ صالح لمدة $otpExpiryMinutes دقائق فقط
⚠️ لا تشارك هذا الرمز مع أي شخص

📱 *$appName*
'''
        .trim();
  }

  /// التحقق من صحة مفتاح API
  static bool isValidApiKey(String key) {
    return key.isNotEmpty && key.length >= 32;
  }

  /// تنسيق رقم الهاتف إلى E.164
  static String formatPhoneToE164(String phone) {
    // إزالة جميع الأحرف غير الرقمية
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // إذا بدأ بـ + نرجعه كما هو
    if (digits.startsWith('+')) {
      return digits;
    }

    // إذا بدأ بـ 00، نستبدلها بـ +
    if (digits.startsWith('00')) {
      return '+${digits.substring(2)}';
    }

    // إذا بدأ بـ 0، نزيله ونضيف كود اليمن
    if (digits.startsWith('0')) {
      return '+967${digits.substring(1)}';
    }

    // إذا لم يبدأ بأي شيء، نضيف كود اليمن
    if (!digits.startsWith('967')) {
      return '+967$digits';
    }

    // إذا بدأ بـ 967 بدون +
    return '+$digits';
  }
}
