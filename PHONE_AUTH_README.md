# 📱 Phone Authentication - Firebase SMS Verification

## نظرة عامة

تم تنفيذ خاصية **التحقق من رقم الهاتف عبر رسائل SMS** في عملية التسجيل (Register) باستخدام **Firebase Phone Authentication**.

### ✨ الميزات
- ✅ إرسال رمز OTP المكون من 6 أرقام عبر SMS
- ✅ واجهة مستخدم جميلة لإدخال OTP
- ✅ إعادة إرسال الرمز مع مؤقت 60 ثانية
- ✅ التحقق الإلزامي في Production
- ✅ وضع Debug للاختبار السريع
- ✅ دعم Test Phone Numbers
- ✅ معالجة شاملة للأخطاء
- ✅ تجربة مستخدم سلسة

## 📁 هيكل المشروع

```
network_app/
├── lib/
│   ├── features/auth/presentation/pages/
│   │   ├── register_page.dart          ✏️ معدّل
│   │   ├── otp_verification_page.dart  ✨ جديد
│   │   └── ...
│   └── core/
│       ├── providers/
│       │   └── auth_provider.dart      ✏️ معدّل
│       └── router/
│           └── app_router.dart         ✏️ معدّل
│
├── FIREBASE_PHONE_AUTH_SETUP.md        📘 دليل الإعداد (عربي)
├── FIREBASE_SETUP_GUIDE.md             📗 Setup Guide (English)
├── QUICK_TEST_GUIDE.md                 🧪 دليل الاختبار السريع
├── PHONE_AUTH_PRODUCTION_CHECKLIST.md  ✅ قائمة مهام الإنتاج
└── PHONE_AUTH_README.md                📖 هذا الملف
```

## 🚀 البدء السريع

### 1. متطلبات أساسية

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
```

### 2. إعداد Firebase (خطوات سريعة)

1. **تفعيل Phone Authentication**
   ```
   Firebase Console → Authentication → Sign-in method → Phone → Enable
   ```

2. **إضافة SHA-1 (Android)**
   ```bash
   cd android && .\gradlew signingReport
   # انسخ SHA-1 وأضفه في Firebase Console
   ```

3. **ترقية إلى Blaze Plan**
   ```
   Firebase Console → Usage and billing → Upgrade to Blaze
   ```

### 3. الاختبار

```bash
# اختبار سريع في Debug mode (بدون SMS فعلي)
flutter run

# اختبار مع SMS فعلي
flutter run --release
```

## 📚 الوثائق

### للمطورين

| الملف | الوصف | اللغة |
|------|-------|------|
| [FIREBASE_PHONE_AUTH_SETUP.md](FIREBASE_PHONE_AUTH_SETUP.md) | دليل الإعداد الشامل | 🇸🇦 عربي |
| [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md) | Complete Setup Guide | 🇬🇧 English |
| [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md) | دليل الاختبار السريع | 🇸🇦 عربي |
| [PHONE_AUTH_PRODUCTION_CHECKLIST.md](PHONE_AUTH_PRODUCTION_CHECKLIST.md) | قائمة مهام الإنتاج | 🇸🇦 عربي |

### اقرأ أولاً

#### إذا كنت مطور:
👉 **ابدأ بـ:** [FIREBASE_PHONE_AUTH_SETUP.md](FIREBASE_PHONE_AUTH_SETUP.md)

#### إذا كنت تريد الاختبار:
👉 **ابدأ بـ:** [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md)

#### إذا كنت تحضّر للإطلاق:
👉 **ابدأ بـ:** [PHONE_AUTH_PRODUCTION_CHECKLIST.md](PHONE_AUTH_PRODUCTION_CHECKLIST.md)

## 🎯 كيفية العمل

### تدفق التسجيل (Registration Flow)

```
┌─────────────────────────┐
│  1. RegisterPage        │
│  - اختيار نوع الحساب    │
│  - إدخال رقم الهاتف     │
│  - إدخال كلمة المرور     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  2. Send OTP            │
│  sendRegistrationOtp()  │
│  - Firebase يرسل SMS    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  3. OtpVerificationPage │
│  - إدخال رمز 6 أرقام    │
│  - يمكن إعادة الإرسال   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  4. Verify OTP          │
│  verifyRegistrationOtp()│
│  - التحقق من الرمز      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  5. Complete Data       │
│  - اسم الشبكة/المتجر    │
│  - العنوان والموقع      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  6. Create Account      │
│  register()             │
│  - إنشاء الحساب         │
│  - ربط رقم الهاتف       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  7. Home Screen         │
│  ✅ تم التسجيل بنجاح    │
└─────────────────────────┘
```

## 🔧 API Reference

### AuthProvider Methods

#### إرسال OTP
```dart
Future<bool> sendRegistrationOtp(
  String phone, {
  bool forceResend = false,
})
```
- **phone:** رقم الهاتف (9 أرقام)
- **forceResend:** إجبار إعادة الإرسال
- **Returns:** `true` عند النجاح

#### التحقق من OTP
```dart
Future<bool> verifyRegistrationOtp(
  String phone,
  String smsCode,
)
```
- **phone:** رقم الهاتف
- **smsCode:** رمز التحقق (6 أرقام)
- **Returns:** `true` إذا كان الرمز صحيح

#### التسجيل
```dart
Future<bool> register({
  required String name,
  required String phone,
  required String password,
  required String confirmPassword,
  required UserType userType,
})
```
- يتحقق من OTP تلقائياً
- ينشئ الحساب ويربط رقم الهاتف

#### إعادة تعيين حالة OTP
```dart
void resetRegistrationOtpState()
```
- يمسح جميع بيانات OTP المؤقتة

### OtpVerificationPage

```dart
OtpVerificationPage({
  required String phoneNumber,
  required OtpVerificationType verificationType,
})
```

**Parameters:**
- **phoneNumber:** رقم الهاتف بصيغة E.164 (+967...)
- **verificationType:** 
  - `OtpVerificationType.registration` للتسجيل
  - `OtpVerificationType.passwordReset` لاستعادة كلمة المرور

**Returns:**
- `true` إذا تم التحقق بنجاح
- `false` إذا تم الإلغاء

## 🧪 أمثلة الاستخدام

### مثال 1: إرسال OTP

```dart
final authProvider = context.read<AuthProvider>();
final phone = '777123456';

final success = await authProvider.sendRegistrationOtp(phone);

if (success) {
  // انتقل لشاشة OTP
  final verified = await context.push<bool>(
    '/otp-verification',
    extra: {
      'phoneNumber': '+967$phone',
      'verificationType': OtpVerificationType.registration,
    },
  );
  
  if (verified == true) {
    // تم التحقق بنجاح
  }
} else {
  // فشل الإرسال
  print(authProvider.error);
}
```

### مثال 2: التحقق من OTP

```dart
final authProvider = context.read<AuthProvider>();
final phone = '777123456';
final otp = '123456';

final success = await authProvider.verifyRegistrationOtp(phone, otp);

if (success) {
  // الرمز صحيح
  context.pop(true);
} else {
  // الرمز خاطئ
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(authProvider.error ?? 'رمز خاطئ')),
  );
}
```

### مثال 3: التسجيل الكامل

```dart
final authProvider = context.read<AuthProvider>();

// 1. إرسال OTP
await authProvider.sendRegistrationOtp('777123456');

// 2. المستخدم يدخل OTP
await authProvider.verifyRegistrationOtp('777123456', '123456');

// 3. التسجيل
final success = await authProvider.register(
  name: 'شبكة الإنترنت',
  phone: '777123456',
  password: 'Password123!',
  confirmPassword: 'Password123!',
  userType: UserType.networkOwner,
);

if (success) {
  context.go('/');
}
```

## ⚙️ التكوين

### وضع Debug

في وضع Debug، يتم تخطي التحقق من OTP تلقائياً:

```dart
// في auth_provider.dart
Future<bool> sendRegistrationOtp(String phone, {bool forceResend = false}) async {
  if (kDebugMode) {
    return bypassRegistrationOtpForTesting(phone); // ✅ تخطي OTP
  }
  // ... باقي الكود
}
```

### وضع Production

في Production، التحقق من OTP إلزامي:

```dart
// في auth_provider.dart
Future<bool> register(...) async {
  if (!kDebugMode && !_registrationOtpVerified) {
    throw Exception('يجب التحقق من رقم الهاتف أولاً'); // ⚠️ خطأ
  }
  // ... باقي الكود
}
```

### Test Phone Numbers

لتسهيل الاختبار، أضف أرقام وهمية:

```
Firebase Console → Authentication → Phone numbers for testing

+967777777777 → 123456
+967777777778 → 654321
+967777777779 → 111111
```

## 🐛 استكشاف الأخطاء

### المشكلة: "فشل إرسال رمز التحقق"

**الحلول:**
1. تأكد من تفعيل Phone Auth في Firebase
2. تأكد من أن المشروع على Blaze Plan
3. أضف SHA-1 في Firebase Console
4. تحقق من صحة رقم الهاتف (+967XXXXXXXXX)

### المشكلة: "رمز التحقق غير صحيح"

**الحلول:**
1. تأكد من إدخال الرمز الصحيح من SMS
2. الرمز صالح لمدة 5 دقائق فقط
3. استخدم آخر رمز وصل (ليس رمز قديم)

### المشكلة: SMS لا يصل

**الحلول:**
1. انتظر 1-2 دقيقة (قد يتأخر الوصول)
2. تحقق من تغطية الشبكة
3. جرّب إعادة الإرسال
4. تأكد من أن الرقم صحيح

## 💰 التكاليف

### Firebase Pricing

| الخطة | Phone Auth | التكلفة |
|------|-----------|---------|
| **Spark (Free)** | ❌ غير متاح | $0 |
| **Blaze (Pay-as-you-go)** | ✅ متاح | حسب الاستخدام |

### تكلفة SMS

```
اليمن: ~$0.03 - $0.05 / رسالة
السعودية: ~$0.02 - $0.04 / رسالة
مصر: ~$0.01 - $0.03 / رسالة

مثال:
1000 مستخدم جديد/شهر × $0.03 = $30/شهر
+ 10% إعادة إرسال = $33/شهر
```

### تقليل التكلفة

1. **استخدم Debug mode أثناء التطوير**
   - لا يرسل SMS فعلي
   - تكلفة $0

2. **استخدم Test Phone Numbers**
   - للاختبار المتكرر
   - تكلفة $0

3. **قلل معدل إعادة الإرسال**
   - حسّن UX
   - اجعل وقت الانتظار واضح

## 📊 المراقبة

### Firebase Console

```
Authentication → Usage
- عدد رسائل SMS المرسلة
- معدل النجاح/الفشل
- التكلفة اليومية/الشهرية
```

### Metrics للمتابعة

```dart
// مثال: تتبع النجاح
FirebaseAnalytics.instance.logEvent(
  name: 'otp_sent',
  parameters: {'phone': phone},
);

FirebaseAnalytics.instance.logEvent(
  name: 'otp_verified',
  parameters: {'phone': phone, 'success': true},
);
```

## 🔒 الأمان

### ✅ ما تم تنفيذه

- ✅ التحقق الإلزامي من OTP في Production
- ✅ تنسيق رقم الهاتف (E.164)
- ✅ معالجة آمنة للأخطاء
- ✅ تشفير الاتصال (HTTPS)

### ⚠️ يُنصح بإضافته

- ⚠️ Firebase App Check (معطّل حالياً)
- ⚠️ Rate Limiting (حدود Firebase الافتراضية)
- ⚠️ Captcha للويب
- ⚠️ IP Whitelisting/Blacklisting

## 🚀 الإطلاق

### قبل الإطلاق

راجع: [PHONE_AUTH_PRODUCTION_CHECKLIST.md](PHONE_AUTH_PRODUCTION_CHECKLIST.md)

**الأساسيات:**
- [ ] Phone Auth مفعّل
- [ ] Blaze Plan نشط
- [ ] SHA-1 مضافة (Release)
- [ ] google-services.json محدّث
- [ ] الاختبار على أجهزة حقيقية
- [ ] حدود الميزانية مضبوطة

### يوم الإطلاق

- [ ] مراقبة Firebase Console
- [ ] فريق الدعم جاهز
- [ ] خطة Rollback جاهزة

## 📞 الدعم

### مشاكل Firebase

- Firebase Support: https://firebase.google.com/support
- Stack Overflow: `[firebase-authentication] [phone]`
- Firebase GitHub: https://github.com/firebase/flutterfire/issues

### مشاكل الكود

راجع الوثائق:
- [FIREBASE_PHONE_AUTH_SETUP.md](FIREBASE_PHONE_AUTH_SETUP.md)
- [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md)

## 🎓 موارد إضافية

### Firebase Documentation
- [Phone Authentication](https://firebase.google.com/docs/auth/android/phone-auth)
- [Firebase Auth Flutter](https://firebase.flutter.dev/docs/auth/usage)
- [Pricing](https://firebase.google.com/pricing)

### Flutter Packages
- [firebase_auth](https://pub.dev/packages/firebase_auth)
- [firebase_core](https://pub.dev/packages/firebase_core)

## 📜 الترخيص

هذا المشروع جزء من `network_app`.

## 👥 المساهمون

- تنفيذ: AI Assistant
- تاريخ: 2 نوفمبر 2025
- النسخة: 1.0.0

---

**✨ شكراً لاستخدام Phone Authentication!**

إذا كان لديك أي أسئلة أو مشاكل، راجع الوثائق أو تواصل مع فريق الدعم.

