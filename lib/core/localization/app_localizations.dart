import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar', 'YE'), // Arabic (Yemen)
    Locale('en', 'US'), // English (US)
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Future<bool> load() async {
    try {
      final path = 'assets/translations/${locale.languageCode}.arb';
      final jsonString = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic>) {
        _localizedStrings =
            decoded.map((key, value) => MapEntry(key, value.toString()));
      } else {
        // Unexpected format, fallback to empty map
        _localizedStrings = {};
      }
      return true;
    } on Exception catch (e) {
      debugPrint('فشل في تحميل ملف الترجمة: $e');
      // Fallback to empty strings
      _localizedStrings = {};
      return false;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Shorthand method
  String t(String key) => translate(key);

  // Common translations
  String get appName => translate('app_name');
  String get login => translate('login');
  String get register => translate('register');
  String get phone => translate('phone');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get name => translate('name');
  String get email => translate('email');
  String get home => translate('home');
  String get network => translate('network');
  String get networks => translate('networks');
  String get accounts => translate('accounts');
  String get chat => translate('chat');
  String get profile => translate('profile');
  String get logout => translate('logout');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get filter => translate('filter');
  String get sort => translate('sort');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get info => translate('info');

  // Business specific
  String get networkOwner => translate('network_owner');
  String get posVendor => translate('pos_vendor');
  String get packages => translate('packages');
  String get cards => translate('cards');
  String get sales => translate('sales');
  String get orders => translate('orders');
  String get transactions => translate('transactions');
  String get inventory => translate('inventory');
  String get yemeniRial => translate('yemeni_rial');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
