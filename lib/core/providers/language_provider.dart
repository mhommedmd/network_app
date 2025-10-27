import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  LanguageProvider() {
    _loadLanguageFromStorage();
  }
  Locale _currentLocale = const Locale('ar', 'YE'); // Arabic by default

  Locale get currentLocale => _currentLocale;
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';

  Future<void> _loadLanguageFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'ar';
      final countryCode = prefs.getString('country_code') ?? 'YE';

      _currentLocale = Locale(languageCode, countryCode);
      notifyListeners();
    } on Exception catch (e) {
      debugPrint('فشل في تحميل اللغة: $e');
    }
  }

  Future<void> _saveLanguageToStorage(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      await prefs.setString('country_code', locale.countryCode ?? '');
    } on Exception catch (e) {
      debugPrint('فشل في حفظ اللغة: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    await _saveLanguageToStorage(locale);
    notifyListeners();
  }

  Future<void> setArabic() async {
    await setLocale(const Locale('ar', 'YE'));
  }

  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }

  Future<void> toggleLanguage() async {
    if (isArabic) {
      await setEnglish();
    } else {
      await setArabic();
    }
  }

  String getLocalizedText(String arabicText, String englishText) {
    return isArabic ? arabicText : englishText;
  }

  // Getters for commonly used texts
  String get appName => getLocalizedText(
        'تطبيق شبكات',
        'Internet Cards Manager',
      );

  String get login => getLocalizedText('تسجيل الدخول', 'Login');
  String get register => getLocalizedText('إنشاء حساب', 'Register');
  String get phone => getLocalizedText('رقم الهاتف', 'Phone Number');
  String get password => getLocalizedText('كلمة المرور', 'Password');
  String get confirmPassword =>
      getLocalizedText('تأكيد كلمة المرور', 'Confirm Password');
  String get name => getLocalizedText('الاسم', 'Name');
  String get email => getLocalizedText('البريد الإلكتروني', 'Email');
  String get home => getLocalizedText('الرئيسية', 'Home');
  String get network => getLocalizedText('الشبكة', 'Network');
  String get networks => getLocalizedText('الشبكات', 'Networks');
  String get accounts => getLocalizedText('المتاجر', 'Accounts');
  String get chat => getLocalizedText('المحادثات', 'Chat');
  String get profile => getLocalizedText('الملف الشخصي', 'Profile');
  String get logout => getLocalizedText('تسجيل الخروج', 'Logout');
  String get cancel => getLocalizedText('إلغاء', 'Cancel');
  String get confirm => getLocalizedText('تأكيد', 'Confirm');
  String get save => getLocalizedText('حفظ', 'Save');
  String get delete => getLocalizedText('حذف', 'Delete');
  String get edit => getLocalizedText('تعديل', 'Edit');
  String get add => getLocalizedText('إضافة', 'Add');
  String get search => getLocalizedText('بحث', 'Search');
  String get filter => getLocalizedText('تصفية', 'Filter');
  String get sort => getLocalizedText('ترتيب', 'Sort');
  String get loading => getLocalizedText('جاري التحميل...', 'Loading...');
  String get error => getLocalizedText('خطأ', 'Error');
  String get success => getLocalizedText('نجح', 'Success');
  String get warning => getLocalizedText('تحذير', 'Warning');
  String get info => getLocalizedText('معلومات', 'Info');

  // Business specific texts
  String get networkOwner => getLocalizedText('مالك الشبكة', 'Network Owner');
  String get posVendor => getLocalizedText('بائع نقطة بيع', 'POS Vendor');
  String get packages => getLocalizedText('الباقات', 'Packages');
  String get cards => getLocalizedText('الكروت', 'Cards');
  String get sales => getLocalizedText('المبيعات', 'Sales');
  String get orders => getLocalizedText('الطلبات', 'Orders');
  String get transactions => getLocalizedText('المعاملات', 'Transactions');
  String get inventory => getLocalizedText('المخزون', 'Inventory');
  String get dailyPackage => getLocalizedText('باقة يومية', 'Daily Package');
  String get weeklyPackage =>
      getLocalizedText('باقة أسبوعية', 'Weekly Package');
  String get monthlyPackage =>
      getLocalizedText('باقة شهرية', 'Monthly Package');
  String get hourlyPackage => getLocalizedText('باقة ساعة', 'Hourly Package');
  String get specialPackage => getLocalizedText('باقة خاصة', 'Special Package');
  String get gamingPackage =>
      getLocalizedText('باقة الألعاب', 'Gaming Package');

  String get yemeniRial => getLocalizedText('ريال يمني', 'YER');
  String get gb => getLocalizedText('جيجا', 'GB');
  String get mb => getLocalizedText('ميجا', 'MB');
  String get hour => getLocalizedText('ساعة', 'Hour');
  String get day => getLocalizedText('يوم', 'Day');
  String get week => getLocalizedText('أسبوع', 'Week');
  String get month => getLocalizedText('شهر', 'Month');
}
