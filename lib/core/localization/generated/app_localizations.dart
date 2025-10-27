import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @hello.
  ///
  /// In ar, this message translates to:
  /// **'مرحبا'**
  String get hello;

  /// No description provided for @app_name.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق شبكات'**
  String get app_name;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @confirm_password.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirm_password;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @network.
  ///
  /// In ar, this message translates to:
  /// **'الشبكة'**
  String get network;

  /// No description provided for @networks.
  ///
  /// In ar, this message translates to:
  /// **'الشبكات'**
  String get networks;

  /// No description provided for @accounts.
  ///
  /// In ar, this message translates to:
  /// **'المتاجر'**
  String get accounts;

  /// No description provided for @chat.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get chat;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب'**
  String get sort;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @success.
  ///
  /// In ar, this message translates to:
  /// **'نجح'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات'**
  String get info;

  /// No description provided for @network_owner.
  ///
  /// In ar, this message translates to:
  /// **'مالك الشبكة'**
  String get network_owner;

  /// No description provided for @pos_vendor.
  ///
  /// In ar, this message translates to:
  /// **'بائع نقطة بيع'**
  String get pos_vendor;

  /// No description provided for @packages.
  ///
  /// In ar, this message translates to:
  /// **'الباقات'**
  String get packages;

  /// No description provided for @cards.
  ///
  /// In ar, this message translates to:
  /// **'الكروت'**
  String get cards;

  /// No description provided for @sales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get sales;

  /// No description provided for @orders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get orders;

  /// No description provided for @transactions.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get transactions;

  /// No description provided for @inventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventory;

  /// No description provided for @yemeni_rial.
  ///
  /// In ar, this message translates to:
  /// **'ريال يمني'**
  String get yemeni_rial;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً'**
  String get welcome;

  /// No description provided for @enter_phone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك اليمني'**
  String get enter_phone;

  /// No description provided for @enter_password.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get enter_password;

  /// No description provided for @enter_name.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك الكامل'**
  String get enter_name;

  /// No description provided for @phone_validation.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم هاتف يمني صحيح'**
  String get phone_validation;

  /// No description provided for @password_validation.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get password_validation;

  /// No description provided for @name_validation.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get name_validation;

  /// No description provided for @login_success.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get login_success;

  /// No description provided for @login_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في تسجيل الدخول'**
  String get login_failed;

  /// No description provided for @register_success.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب بنجاح'**
  String get register_success;

  /// No description provided for @register_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في إنشاء الحساب'**
  String get register_failed;

  /// No description provided for @password_mismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمات المرور غير متطابقة'**
  String get password_mismatch;

  /// No description provided for @quick_sale.
  ///
  /// In ar, this message translates to:
  /// **'بيع سريع'**
  String get quick_sale;

  /// No description provided for @request_cards.
  ///
  /// In ar, this message translates to:
  /// **'طلب كروت'**
  String get request_cards;

  /// No description provided for @daily_sales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get daily_sales;

  /// No description provided for @available_cards.
  ///
  /// In ar, this message translates to:
  /// **'الكروت المتاحة'**
  String get available_cards;

  /// No description provided for @quick_actions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quick_actions;

  /// No description provided for @available_packages.
  ///
  /// In ar, this message translates to:
  /// **'الباقات المتاحة'**
  String get available_packages;

  /// No description provided for @sell_cards.
  ///
  /// In ar, this message translates to:
  /// **'بيع كروت للعملاء'**
  String get sell_cards;

  /// No description provided for @request_from_networks.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من الشبكات'**
  String get request_from_networks;

  /// No description provided for @start_sale.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ البيع'**
  String get start_sale;

  /// No description provided for @send_request.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب'**
  String get send_request;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @maintenance.
  ///
  /// In ar, this message translates to:
  /// **'صيانة'**
  String get maintenance;

  /// No description provided for @unavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get unavailable;

  /// No description provided for @daily_package.
  ///
  /// In ar, this message translates to:
  /// **'باقة يومية'**
  String get daily_package;

  /// No description provided for @weekly_package.
  ///
  /// In ar, this message translates to:
  /// **'باقة أسبوعية'**
  String get weekly_package;

  /// No description provided for @monthly_package.
  ///
  /// In ar, this message translates to:
  /// **'باقة شهرية'**
  String get monthly_package;

  /// No description provided for @hourly_package.
  ///
  /// In ar, this message translates to:
  /// **'باقة ساعة'**
  String get hourly_package;

  /// No description provided for @special_package.
  ///
  /// In ar, this message translates to:
  /// **'باقة خاصة'**
  String get special_package;

  /// No description provided for @gaming_package.
  ///
  /// In ar, this message translates to:
  /// **'باقة الألعاب'**
  String get gaming_package;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
