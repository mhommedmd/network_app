# قائمة المهام قبل نشر Phone Authentication في Production

## 🔴 مهام حرجة (يجب إتمامها)

### 1. Firebase Configuration
- [ ] **تفعيل Phone Authentication**
  - اذهب إلى Firebase Console → Authentication → Sign-in method
  - فعّل Phone provider
  - احفظ التغييرات

- [ ] **ترقية المشروع إلى Blaze Plan**
  - Firebase Console → Usage and billing
  - Upgrade to Blaze (Pay as you go)
  - أضف طريقة دفع صالحة
  - **ملاحظة:** Phone Auth لا يعمل على Spark Plan المجاني

- [ ] **إضافة SHA-1 Fingerprints**
  - Debug SHA-1 (للتطوير)
  - Release SHA-1 (للإنتاج) ⚠️ **مهم جداً**
  
  ```bash
  # للحصول على Release SHA-1
  cd android
  keytool -list -v -keystore /path/to/release.keystore -alias your-alias
  ```

### 2. Android Configuration

- [ ] **تحديث google-services.json**
  - بعد إضافة SHA-1، حمّل google-services.json الجديد
  - ضعه في `android/app/google-services.json`
  - تأكد من أنه يحتوي على client_id الصحيح

- [ ] **Permissions في AndroidManifest.xml**
  ```xml
  <!-- android/app/src/main/AndroidManifest.xml -->
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.RECEIVE_SMS"/>
  <uses-permission android:name="android.permission.READ_SMS"/>
  ```

- [ ] **ProGuard Rules (للـ Release Build)**
  ```proguard
  # android/app/proguard-rules.pro
  -keep class com.google.firebase.** { *; }
  -keep class com.google.android.gms.** { *; }
  -dontwarn com.google.firebase.**
  -dontwarn com.google.android.gms.**
  ```

### 3. iOS Configuration (إن وجد)

- [ ] **تحديث GoogleService-Info.plist**
  - حمّل من Firebase Console
  - ضعه في `ios/Runner/GoogleService-Info.plist`

- [ ] **APNs Configuration**
  - أضف APNs Authentication Key في Firebase
  - فعّل Push Notifications في Xcode
  - أضف Background Modes capability

- [ ] **Update Info.plist**
  ```xml
  <!-- ios/Runner/Info.plist -->
  <key>FirebaseAppDelegateProxyEnabled</key>
  <false/>
  ```

## 🟡 مهام أمنية (مستحسنة بشدة)

### 4. Security & Rate Limiting

- [ ] **تفعيل Firebase App Check**
  ```dart
  // في main.dart
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  ```

- [ ] **تكوين Rate Limits**
  - Firebase Console → Authentication → Settings
  - حدد عدد محاولات SMS في الساعة:
    - Per IP: 100 (افتراضي)
    - Per Phone: 5 (افتراضي)
  - يمكن التعديل حسب الحاجة

- [ ] **Abuse Prevention**
  - راجع Firebase Console → Authentication → Usage
  - راقب الأنماط الغريبة
  - فعّل تنبيهات للاستخدام غير الطبيعي

### 5. Error Handling & Logging

- [ ] **إضافة Firebase Crashlytics**
  ```yaml
  # pubspec.yaml
  dependencies:
    firebase_crashlytics: ^latest
  ```

- [ ] **Error Tracking**
  ```dart
  // في auth_provider.dart
  try {
    // OTP logic
  } catch (e) {
    FirebaseCrashlytics.instance.recordError(e, stackTrace);
    // Handle error
  }
  ```

- [ ] **Analytics Events**
  ```dart
  // تتبع نجاح/فشل OTP
  FirebaseAnalytics.instance.logEvent(
    name: 'otp_verification',
    parameters: {'status': 'success'},
  );
  ```

## 🟢 مهام تحسينية (اختيارية)

### 6. User Experience

- [ ] **تحسين رسائل الخطأ**
  - اجعل الرسائل واضحة وباللغة العربية
  - أضف اقتراحات للحل

- [ ] **Retry Logic**
  ```dart
  // إضافة إعادة محاولة تلقائية
  Future<bool> sendOtpWithRetry(String phone, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await sendRegistrationOtp(phone);
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 2));
      }
    }
    return false;
  }
  ```

- [ ] **Loading States**
  - أضف مؤشرات تحميل واضحة
  - أظهر تقدم العملية

### 7. Testing

- [ ] **Unit Tests**
  ```dart
  // test/auth_provider_test.dart
  test('sendRegistrationOtp should return true on success', () async {
    // Test implementation
  });
  ```

- [ ] **Integration Tests**
  ```dart
  // integration_test/auth_flow_test.dart
  testWidgets('Complete registration flow with OTP', (tester) async {
    // Test full flow
  });
  ```

- [ ] **اختبار على أجهزة حقيقية**
  - Android (مختلف الإصدارات)
  - iOS (إن وجد)
  - شبكات مختلفة (WiFi, 3G, 4G)

## 💰 مهام مالية

### 8. Cost Management

- [ ] **تقدير التكلفة الشهرية**
  ```
  عدد المستخدمين الجدد المتوقع: _____ / شهر
  تكلفة SMS لليمن: ~$0.03 / رسالة
  معدل إعادة الإرسال: 10% (تقديري)
  
  التكلفة الشهرية = المستخدمين × $0.03 × 1.1
  ```

- [ ] **ضبط حدود الإنفاق**
  - Firebase Console → Usage and billing → Budget alerts
  - اضبط تنبيه عند 50% من الميزانية
  - اضبط تنبيه عند 90% من الميزانية

- [ ] **مراقبة الاستخدام**
  - راجع Firebase Console → Authentication → Usage يومياً
  - راقب الأنماط غير الطبيعية
  - فعّل تقارير البريد الإلكتروني الأسبوعية

## 📝 مهام توثيقية

### 9. Documentation

- [ ] **تحديث Terms of Service**
  - اذكر استخدام SMS للتحقق
  - وضّح تكاليف الرسائل (إن وجدت للمستخدم)

- [ ] **تحديث Privacy Policy**
  - وضّح كيفية استخدام رقم الهاتف
  - اذكر مشاركة البيانات مع Firebase/Google

- [ ] **FAQ للمستخدمين**
  - "لماذا نحتاج رقم هاتفك؟"
  - "كم تستغرق رسالة التحقق؟"
  - "ماذا لو لم تصل الرسالة؟"

### 10. Internal Documentation

- [ ] **توثيق الكود**
  ```dart
  /// يرسل رمز OTP إلى رقم الهاتف المحدد
  /// 
  /// [phone] رقم الهاتف بصيغة 9 أرقام (مثال: 777123456)
  /// [forceResend] لإجبار إعادة الإرسال حتى لو كان هناك طلب سابق
  /// 
  /// Returns: true إذا تم الإرسال بنجاح، false في حالة الفشل
  Future<bool> sendRegistrationOtp(String phone, {bool forceResend = false})
  ```

- [ ] **Runbook للمشاكل الشائعة**
  - كيفية التعامل مع ارتفاع مفاجئ في الاستخدام
  - كيفية حل مشكلة "رسائل لا تصل"
  - كيفية إيقاف الخدمة مؤقتاً في حالات الطوارئ

## 🚦 مهام الإطلاق

### 11. Pre-Launch

- [ ] **Soft Launch (إطلاق محدود)**
  - افتح للمستخدمين الأوائل (100 مستخدم)
  - راقب الأداء والأخطاء
  - اجمع ردود الفعل

- [ ] **Load Testing**
  ```dart
  // اختبار مع عدد كبير من الطلبات المتزامنة
  // استخدم أدوات مثل JMeter أو Locust
  ```

- [ ] **Disaster Recovery Plan**
  - ماذا تفعل إذا توقفت Firebase؟
  - هل لديك backup authentication method؟
  - كيف ستتواصل مع المستخدمين؟

### 12. Launch Day

- [ ] **تفعيل المراقبة في الوقت الفعلي**
  - Firebase Console → Authentication → Usage
  - Google Cloud Console → Monitoring

- [ ] **فريق الدعم جاهز**
  - قائمة بالمشاكل المحتملة والحلول
  - قنوات التواصل (email, phone, chat)

- [ ] **خطة rollback**
  - كيف تعود للنسخة القديمة إذا حدثت مشاكل؟
  - هل النسخة القديمة جاهزة؟

## 📊 مهام ما بعد الإطلاق

### 13. Monitoring (الأسبوع الأول)

- [ ] **مراقبة يومية**
  - معدل نجاح OTP
  - معدل إعادة الإرسال
  - التكلفة اليومية
  - الأخطاء الشائعة

- [ ] **User Feedback**
  - جمع آراء المستخدمين
  - مراجعة التقييمات في المتاجر
  - الرد على الشكاوى

### 14. Optimization (الشهر الأول)

- [ ] **تحليل الأداء**
  - ما هو متوسط وقت وصول SMS؟
  - كم نسبة الرسائل التي لا تصل؟
  - ما هي أوقات الذروة؟

- [ ] **تحسين التكلفة**
  - هل يمكن تقليل عدد إعادات الإرسال؟
  - هل يمكن استخدام طريقة أرخص في بعض الحالات؟

## ✅ قائمة التحقق النهائية

قبل الإطلاق، تأكد من:

- [ ] ✅ جميع المهام الحرجة (🔴) مكتملة
- [ ] ✅ معظم المهام الأمنية (🟡) مكتملة
- [ ] ✅ تم الاختبار على أجهزة حقيقية
- [ ] ✅ Firebase على Blaze Plan
- [ ] ✅ SHA-1 للـ Release مضافة
- [ ] ✅ حدود الميزانية مضبوطة
- [ ] ✅ المراقبة مفعّلة
- [ ] ✅ فريق الدعم جاهز
- [ ] ✅ خطة Rollback جاهزة

## 🆘 جهات الاتصال في حالة الطوارئ

```
Firebase Support: https://firebase.google.com/support
Google Cloud Support: https://cloud.google.com/support
مدير المشروع: ________________
مطور Backend: ________________
مدير DevOps: ________________
```

## 📈 KPIs للمتابعة

```
1. معدل نجاح OTP: > 95%
2. متوسط وقت وصول SMS: < 30 ثانية
3. معدل إعادة الإرسال: < 15%
4. تكلفة لكل مستخدم جديد: < $0.05
5. معدل الأخطاء: < 2%
```

---

**آخر تحديث:** 2 نوفمبر 2025
**المسؤول:** ________________
**تاريخ الإطلاق المخطط:** ________________

