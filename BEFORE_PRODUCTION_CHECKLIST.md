# ⚠️ قائمة التحقق قبل الإطلاق النهائي للمشروع

> **مهم جداً:** هذا الملف يحتوي على جميع الأشياء المُعطّلة أو المؤقتة التي يجب تفعيلها/تعديلها قبل إطلاق التطبيق للمستخدمين النهائيين.

---

## 📋 الفهرس

1. [Firebase App Check](#1-firebase-app-check)
2. [Debug Mode & Logging](#2-debug-mode--logging)
3. [Firebase Security Rules](#3-firebase-security-rules)
4. [API Keys & Credentials](#4-api-keys--credentials)
5. [Performance & Optimization](#5-performance--optimization)
6. [Testing & Quality](#6-testing--quality)
7. [Many-to-Many Architecture](#7-many-to-many-architecture)
8. [قائمة التحقق النهائية](#-قائمة-التحقق-النهائية)

---

## 1. Firebase App Check

### ⚠️ الحالة الحالية: **معطل**

**الموقع:** `lib/main.dart` (السطور 24-30)

```dart
// تعطيل App Check مؤقتاً لحل مشكلة رفع الصور
// سيتم تفعيله لاحقاً في الإنتاج
// await FirebaseAppCheck.instance.activate(
//   webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
//   androidProvider: AndroidProvider.debug,
//   appleProvider: AppleProvider.debug,
// );
```

### ✅ المطلوب قبل الإطلاق:

#### 1. تفعيل Play Integrity في Firebase Console

```
الخطوات:
1. افتح: https://console.firebase.google.com
2. اختر المشروع: fir-networkapp
3. اذهب إلى: Build → App Check
4. اضغط: Register app
5. اختر تطبيق Android
6. اختر: Play Integrity
7. اتبع التعليمات لإعداد Play Console
8. احفظ التكوين
```

#### 2. تحديث الكود

**استبدل الكود في `lib/main.dart`:**

```dart
// قبل الإطلاق - استخدام Play Integrity
await FirebaseAppCheck.instance.activate(
  // للويب: استخدام reCAPTCHA v3
  webProvider: ReCaptchaV3Provider('YOUR-RECAPTCHA-SITE-KEY-HERE'),
  
  // للأندرويد: استخدام Play Integrity
  androidProvider: AndroidProvider.playIntegrity,
  
  // للـ iOS: استخدام Device Check
  appleProvider: AppleProvider.deviceCheck,
);
```

#### 3. اختبار App Check

```bash
# بناء نسخة Release
flutter build apk --release

# أو
flutter build appbundle --release

# اختبار التطبيق على جهاز حقيقي
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### 4. التحقق في Firebase Console

```
1. افتح: Firebase Console → App Check
2. تحقق من Metrics:
   - App Check Tokens Generated
   - Requests Protected
   - Verification Success Rate
3. يجب أن ترى: ✅ Active Protection
```

---

## 2. Debug Mode & Logging




### ⚠️ الحالة الحالية: **Debug Logging مُفعّل**

يوجد الكثير من `debugPrint` في الكود لأغراض التطوير والتتبع.

### ✅ المطلوب قبل الإطلاق:

#### 1. إزالة Debug Prints الحساسة

**ابحث في المشروع عن:**

```bash
grep -r "debugPrint" lib/ --include="*.dart"
```

**الأولويات للإزالة/التعديل:**

| الملف | النوع | الإجراء |
|-------|-------|---------|
| `auth_provider.dart` | 🔴 حساس | إزالة prints التي تعرض User ID, Auth Token |
| `firebase_sale_service.dart` | 🟡 متوسط | إبقاء الأساسي فقط |
| `firebase_network_service.dart` | 🟡 متوسط | إبقاء الأساسي فقط |
| `network_stored_page.dart` | 🟢 عادي | يمكن الإبقاء |

**مثال للتعديل:**

```dart
// ❌ لا تفعل هذا في Production
debugPrint('👤 User ID: ${_user!.id}');
debugPrint('🔐 Auth UID: ${_firebaseAuth.currentUser?.uid}');

// ✅ افعل هذا
if (kDebugMode) {
  debugPrint('👤 User ID: ${_user!.id}');
  debugPrint('🔐 Auth UID: ${_firebaseAuth.currentUser?.uid}');
}
```

#### 2. استخدام Logger مناسب للإنتاج

**أضف package:**

```yaml
# pubspec.yaml
dependencies:
  logger: ^2.0.0
```

**استخدام:**

```dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// في Production - فقط الأخطاء
if (kReleaseMode) {
  logger.level = Level.error;
} else {
  logger.level = Level.debug;
}

// الاستخدام
logger.d('Debug message');   // فقط في Debug
logger.e('Error message');   // في Debug & Release
```

---

## 3. Firebase Security Rules

### ⚠️ الحالة الحالية: **قواعد التطوير**

القواعد الحالية تسمح ببعض العمليات لسهولة التطوير.

### ✅ المطلوب قبل الإطلاق:

#### 1. مراجعة Firestore Rules

**الملف:** `firestore.rules`

**تحقق من:**

```javascript
// ✅ جيد - محمي بالكامل
allow read: if request.auth != null && request.auth.uid == userId;

// ⚠️ احذر - قد يكون خطر
allow read: if true;  // يسمح للجميع بالقراءة!

// ✅ جيد - محمي بالشروط
allow update: if request.auth != null 
              && request.auth.uid == resource.data.ownerId
              && request.resource.data.keys().hasAll(['name', 'status']);
```

**قواعد يجب مراجعتها:**

```javascript
// users collection
match /users/{userId} {
  // ✅ التحقق: هل يمكن للمستخدم قراءة معلومات الآخرين؟
  allow read: if request.auth != null;
  
  // ✅ التحقق: هل يمكن للمستخدم تعديل معلومات الآخرين؟
  allow update: if request.auth != null && request.auth.uid == userId;
}

// cards collection
match /cards/{cardId} {
  // ✅ التحقق: من يستطيع قراءة الكروت؟
  // ✅ التحقق: من يستطيع تعديل حالة الكرت؟
}

// transactions collection
match /transactions/{transactionId} {
  // ✅ التحقق: من يستطيع إنشاء معاملة؟
  // ✅ التحقق: هل يمكن حذف المعاملات؟
}
```

#### 2. مراجعة Storage Rules

**الملف:** `storage.rules`

```javascript
// ✅ جيد - الحد الأقصى 5 MB
allow create: if request.resource.size < 5 * 1024 * 1024;

// ⚠️ فكّر: هل 5 MB مناسب؟ أم يجب تقليله؟
// للصور المضغوطة، 2 MB كافي:
allow create: if request.resource.size < 2 * 1024 * 1024;

// ✅ جيد - صور فقط
allow create: if request.resource.contentType.matches('image/.*');

// ✅ إضافة: هل تريد حد أقصى لعدد الصور؟
// مثال: 5 صور لكل مستخدم
allow create: if request.resource.size < 2 * 1024 * 1024
              && request.resource.contentType.matches('image/.*')
              && getUserImagesCount() < 5;
```

#### 3. اختبار القواعد

```bash
# تشغيل emulator
firebase emulators:start

# اختبار القواعد
firebase firestore:rules:test --project fir-networkapp

# نشر القواعد المحدثة
firebase deploy --only firestore:rules,storage --project fir-networkapp
```

---

## 4. API Keys & Credentials

### ⚠️ الحالة الحالية: **مفاتيح التطوير**

### ✅ المطلوب قبل الإطلاق:

#### 1. مراجعة Firebase Config

**الملف:** `android/app/google-services.json`

```json
{
  "client": [
    {
      "api_key": [
        {
          "current_key": "AIzaSy..." // ✅ تحقق من القيد بـ Bundle ID
        }
      ]
    }
  ]
}
```

**التحقق:**
```
1. افتح: Firebase Console → Project Settings
2. اذهب إلى: Your apps → Android app
3. تحقق من API Key Restrictions:
   ✅ محدود بـ Package Name
   ✅ محدود بـ SHA-1 fingerprint
```

#### 2. تقييد API Keys في Google Cloud

```
1. افتح: https://console.cloud.google.com
2. اختر المشروع: fir-networkapp
3. اذهب إلى: APIs & Services → Credentials
4. لكل API Key:
   - API restrictions: محدود للـ APIs المطلوبة فقط
   - Application restrictions: Android apps
   - Package name: com.example.network_app
   - SHA-1: [fingerprint of release keystore]
```

#### 3. Firebase App Check (مرة أخرى!)

⚠️ **مهم جداً:** App Check يحمي API Keys من إساءة الاستخدام!

---

## 5. Performance & Optimization

### ⚠️ الحالة الحالية: **بعض التحسينات مفقودة**

### ✅ المطلوب قبل الإطلاق:

#### 1. تفعيل Proguard/R8 (Android)

**الملف:** `android/app/build.gradle`

```gradle
android {
    buildTypes {
        release {
            // ✅ تصغير الكود
            minifyEnabled true
            shrinkResources true
            
            // ✅ تشويش الكود
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // ✅ توقيع التطبيق
            signingConfig signingConfigs.release
        }
    }
}
```

**الملف:** `android/app/proguard-rules.pro`

```proguard
# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
```

#### 2. تحسين الصور

```dart
// في ImagePicker - تحقق من الإعدادات
final pickedFile = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 512,      // ✅ محدود
  maxHeight: 512,     // ✅ محدود
  imageQuality: 85,   // ✅ جودة معقولة
);

// ⚠️ فكّر: هل 512px كافي؟ أم 1024px أفضل؟
```

#### 3. Firebase Performance Monitoring

**أضف:**

```yaml
# pubspec.yaml
dependencies:
  firebase_performance: ^0.9.0
```

**في الكود:**

```dart
import 'package:firebase_performance/firebase_performance.dart';

// مراقبة عمليات مهمة
Future<void> sellCards() async {
  final trace = FirebasePerformance.instance.newTrace('sell_cards');
  await trace.start();
  
  try {
    // عملية البيع
    await _performSale();
  } finally {
    await trace.stop();
  }
}
```

#### 4. Lazy Loading للصور

```dart
// استخدام CachedNetworkImage بدلاً من Image.network
CachedNetworkImage(
  imageUrl: user.avatar ?? '',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  cacheKey: user.id,
  maxWidthDiskCache: 200,
  maxHeightDiskCache: 200,
)
```

---

## 6. Testing & Quality

### ⚠️ الحالة الحالية: **اختبارات يدوية فقط**

### ✅ المطلوب قبل الإطلاق:

#### 1. اختبارات Unit Tests

```dart
// test/auth_provider_test.dart
void main() {
  group('AuthProvider Tests', () {
    test('login with valid credentials should succeed', () async {
      // arrange
      final authProvider = AuthProvider();
      
      // act
      final result = await authProvider.login(
        phone: '777123456',
        password: 'test123',
      );
      
      // assert
      expect(result, true);
      expect(authProvider.user, isNotNull);
    });
  });
}
```

#### 2. اختبارات Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  testWidgets('Complete sale flow', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Login
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();
    
    // Navigate to Sale
    await tester.tap(find.byIcon(Icons.sell));
    await tester.pumpAndSettle();
    
    // Select package and sell
    // ...
  });
}
```

#### 3. اختبار الأداء

```bash
# تشغيل في وضع profile
flutter run --profile

# قياس الأداء
flutter drive --target=test_driver/perf_test.dart --profile
```

---

## 7. قائمة التحقق النهائية

### 🔴 **حرج - يجب إصلاحها قبل الإطلاق**

- [ ] **تفعيل Firebase App Check** مع Play Integrity
- [ ] **مراجعة Firestore Security Rules** - لا قواعد مفتوحة
- [ ] **مراجعة Storage Security Rules** - حدود واضحة
- [ ] **تقييد API Keys** في Google Cloud Console
- [ ] **إزالة Debug Prints الحساسة** (Auth tokens, User IDs)
- [ ] **توقيع التطبيق** بـ Release Keystore
- [ ] **تفعيل Proguard/R8** لتصغير وتشويش الكود

---

### 🟡 **مهم - يُفضل إصلاحها**

- [ ] **إضافة Firebase Performance Monitoring**
- [ ] **تحسين الصور** - Lazy Loading, Caching
- [ ] **إضافة Error Tracking** (Firebase Crashlytics)
- [ ] **مراجعة حدود الحجم** للصور (هل 5 MB مناسب؟)
- [ ] **إضافة Rate Limiting** لمنع إساءة الاستخدام
- [ ] **تفعيل Analytics** لتتبع سلوك المستخدمين
- [ ] **اختبار التطبيق** على أجهزة مختلفة (low-end, high-end)

---

### 🟢 **جيد أن يكون - اختياري**

- [ ] **إضافة Unit Tests** للمكونات الرئيسية
- [ ] **إضافة Integration Tests** للتدفقات المهمة
- [ ] **إضافة CI/CD** للنشر التلقائي
- [ ] **إعداد Beta Testing** على Google Play (Internal/Closed Testing)
- [ ] **إضافة Deep Linking** للإشعارات
- [ ] **إضافة Push Notifications** للتحديثات المهمة
- [ ] **إنشاء Privacy Policy** و Terms of Service

---

## 📝 ملاحظات مهمة

### 🔐 الأمان:

```
الطبقات الأمنية المطلوبة:

1. Firebase Authentication ✅
   └─ التحقق من رقم الهاتف + OTP

2. Firestore Security Rules ✅
   └─ التحقق من صلاحيات القراءة/الكتابة

3. Storage Security Rules ✅
   └─ التحقق من نوع الملف والحجم

4. Firebase App Check ⚠️ (معطل حالياً)
   └─ الحماية من الروبوتات والتطبيقات المزيفة

5. API Key Restrictions ⚠️ (يجب المراجعة)
   └─ تحديد الـ APIs المسموحة

6. Proguard/R8 ⚠️ (يجب التفعيل)
   └─ تشويش الكود لمنع الهندسة العكسية
```

---

### ⚡ الأداء:

```
التحسينات المطلوبة:

1. Image Compression ✅
   └─ 512x512, 85% quality

2. Lazy Loading ⚠️
   └─ تحميل الصور عند الحاجة فقط

3. Caching ⚠️
   └─ حفظ الصور والبيانات محلياً

4. Code Minification ⚠️
   └─ تصغير حجم APK

5. Performance Monitoring ⚠️
   └─ تتبع الأداء في الإنتاج
```

---

### 📊 المراقبة:

```
الأدوات المطلوبة للإنتاج:

1. Firebase Analytics ⚠️
   └─ تتبع سلوك المستخدمين

2. Firebase Crashlytics ⚠️
   └─ تتبع الأخطاء والأعطال

3. Firebase Performance ⚠️
   └─ قياس أداء التطبيق

4. Firebase App Check Metrics ⚠️
   └─ مراقبة الحماية ضد الهجمات
```

---

## 🚀 خطوات الإطلاق المقترحة

### المرحلة 1: التحضير (أسبوع واحد)

```
□ مراجعة وتحديث Security Rules
□ تفعيل App Check
□ إزالة Debug Code
□ تفعيل Proguard
□ إنشاء Release Keystore
□ توقيع التطبيق
```

### المرحلة 2: الاختبار (أسبوعين)

```
□ اختبار داخلي (Internal Testing)
  - 5-10 مستخدمين
  - اختبار جميع الميزات
  - جمع الملاحظات

□ اختبار مغلق (Closed Testing)
  - 20-50 مستخدم
  - اختبار على أجهزة مختلفة
  - قياس الأداء

□ اختبار مفتوح (Open Testing)
  - 100+ مستخدم
  - التأكد من الاستقرار
  - التأكد من الأمان
```

### المرحلة 3: الإطلاق (يوم واحد)

```
□ النشر النهائي على Google Play Store
□ تفعيل جميع المراقبة (Analytics, Crashlytics)
□ إعداد خطة الدعم الفني
□ مراقبة الأداء في الأيام الأولى
```

---

## 7. Many-to-Many Architecture

### ✅ الحالة الحالية: **مُفعّل ومُختبر بالكامل**

**تم التحقق:** 31 أكتوبر 2025

### 📄 التوثيق الكامل
راجع ملف: [`MANY_TO_MANY_VERIFICATION.md`](./MANY_TO_MANY_VERIFICATION.md)

### 🎯 النظرة العامة

التطبيق يدعم بشكل كامل العلاقة **Many-to-Many** بين:
- **مستخدم `pos_vendor` واحد** ← يمكنه الاتصال بـ **عدة شبكات** (`network_owner`)
- **مستخدم `network_owner` واحد** ← يمكنه التعامل مع **عدة متاجر** (`pos_vendor`)

### ✅ المكونات المُختبرة

| المكون | الحالة | الملاحظات |
|--------|:------:|-----------|
| network_connections | ✅ | يسمح بعلاقات متعددة |
| الصفحة الرئيسية pos_vendor | ✅ | يعرض 3 شبكات مخصصة |
| نظام الطلبات | ✅ | يحدد networkId لكل طلب |
| نظام البيع | ✅ | يبيع من شبكة محددة |
| المدفوعات النقدية | ✅ | دفعات منفصلة لكل شبكة |
| المخزون vendor_cards | ✅ | مخزون منفصل حسب الشبكة |
| صفحة الحساب والمعاملات | ✅ | رصيد منفصل لكل شبكة |

### 🔍 الفهارس المطلوبة في Firestore

**مهم جداً:** تأكد من وجود هذه الفهارس قبل الإطلاق:

#### network_connections
```
vendorId (ASC) + isActive (ASC)
networkId (ASC) + vendorId (ASC)
```

#### orders
```
vendorId (ASC) + status (ASC) + createdAt (DESC)
networkId (ASC) + status (ASC) + createdAt (DESC)
```

#### vendor_cards
```
vendorId (ASC) + status (ASC)
vendorId (ASC) + networkId (ASC) + status (ASC)
vendorId (ASC) + networkId (ASC) + packageId (ASC) + status (ASC)
```

#### transactions
```
vendorId (ASC) + networkId (ASC) + date (DESC)
vendorId (ASC) + networkId (ASC) + status (ASC)
networkId (ASC) + status (ASC) + date (DESC)
```

#### sales
```
vendorId (ASC) + soldAt (DESC)
networkId (ASC) + soldAt (DESC)
```

#### cash_payment_requests
```
vendorId (ASC) + status (ASC)
networkId (ASC) + status (ASC)
```

### ⚠️ التحقق قبل الإطلاق

```bash
# 1. تحقق من الفهارس في Firebase Console
https://console.firebase.google.com → Firestore → Indexes

# 2. اختبر السيناريوهات التالية:
□ متجر يضيف 3 شبكات مختلفة
□ متجر يرسل طلبات لشبكات مختلفة
□ متجر يبيع كروت من شبكات مختلفة
□ متجر يدفع مبالغ نقدية لشبكات مختلفة
□ متجر يعرض رصيده مع كل شبكة بشكل صحيح
□ شبكة تتعامل مع عدة متاجر
```

### 📊 مثال سيناريو مدعوم

```
متجر "يحيى عبدوه فارع"
├── شبكة "أحمد"
│   ├── رصيد: 175,000 ر.ي
│   ├── مخزون: 50 كرت
│   └── معاملات: 120
├── شبكة "محمد"
│   ├── رصيد: 95,000 ر.ي
│   ├── مخزون: 80 كرت
│   └── معاملات: 85
└── شبكة "علي"
    ├── رصيد: 50,000 ر.ي
    ├── مخزون: 30 كرت
    └── معاملات: 45
```

**✅ لا توجد حاجة لأي تعديلات - النظام يعمل بشكل صحيح!**

---

## 📞 جهات الاتصال

### Firebase Support
- Console: https://console.firebase.google.com
- Documentation: https://firebase.google.com/docs
- Support: https://firebase.google.com/support

### Google Play Console
- Console: https://play.google.com/console
- Documentation: https://support.google.com/googleplay

---

## 📅 تاريخ الإنشاء
**30 أكتوبر 2025**

## 🔄 آخر تحديث
**31 أكتوبر 2025** - تم التحقق من دعم Many-to-Many Architecture

---

## ✅ حالة المشروع الحالية

```
🟢 جاهز للتطوير
🟡 يحتاج تحضير للإطلاق
🔴 غير جاهز للإنتاج (بدون App Check)
```

---

**مهم:** راجع هذا الملف بانتظام وقم بتحديث القوائم عند إكمال أي مهمة! ✅

---

## 🎯 الهدف النهائي

```
┌─────────────────────────────────────────┐
│  تطبيق آمن ⚡ سريع 📱 مستقر 🔒 محمي  │
└─────────────────────────────────────────┘

✅ جميع الميزات الأمنية مُفعّلة
✅ الأداء محسّن بالكامل
✅ الأخطاء مراقبة ومُعالجة
✅ المستخدمون راضون وآمنون
```

**بالتوفيق في الإطلاق!** 🚀

