# 👨‍💻 دليل المطورين - MikroTik Cards Manager

## 🚀 البدء السريع

### **1. إعداد البيئة**

```bash
# 1. استنساخ المشروع
git clone <repository-url>
cd network_app

# 2. تثبيت التبعيات
flutter pub get

# 3. تشغيل التطبيق
flutter run
```

### **2. البنية الأساسية**

```
lib/
├── core/                    # الوظائف الأساسية
│   ├── providers/          # مزودي الحالة (Auth, Language)
│   ├── router/             # نظام التوجيه
│   ├── theme/              # الألوان والأنماط
│   └── localization/       # الترجمات
│
├── features/               # الميزات الرئيسية
│   ├── auth/              # تسجيل الدخول والتسجيل
│   ├── network_owner/     # وظائف مالك الشبكة
│   ├── pos_vendor/        # وظائف نقطة البيع
│   └── common/            # صفحات مشتركة
│
└── shared/                # مكونات مشتركة
    ├── widgets/           # Widgets قابلة لإعادة الاستخدام
    └── utils/             # دوال مساعدة
```

---

## 🔑 المفاهيم الأساسية

### **1. أنواع المستخدمين**

```dart
enum UserType {
  networkOwner,  // مالك الشبكة
  posVendor,     // نقطة البيع/المتجر
}
```

### **2. نظام المعاملات**

```dart
// أنواع المعاملات
type: 'charge'   → طلب كروت (زيادة دين)
type: 'payment'  → دفعة نقدية (تقليل دين)

// العرض للمستخدم
charge  → -5000 (أحمر 🔴)
payment → +3000 (أخضر 🟢)

// الحساب
الرصيد = المستحقات - المدفوعات
```

### **3. Collections في Firebase**

```
users                      - بيانات المستخدمين
├── {userId}
    ├── id, name, phone, type, etc.

vendors                    - بيانات المتاجر
├── {vendorId}
    ├── id, name, balance, stock, etc.

packages                   - الباقات المتاحة
├── {packageId}
    ├── name, price, dataSize, etc.

cards                      - كروت الشبكة
├── {cardId}
    ├── code, packageId, status, etc.

vendor_cards               - كروت المتاجر
├── {cardId}
    ├── vendorId, networkId, status, etc.

orders                     - طلبات الكروت
├── {orderId}
    ├── vendorId, items[], totalAmount, status, etc.

transactions               - المعاملات المالية
├── {transactionId}
    ├── vendorId, networkId, type, amount, date, etc.

cash_payment_requests      - طلبات الدفع النقدي
├── {requestId}
    ├── vendorId, networkId, amount, status, etc.

notifications              - الإشعارات
├── {notificationId}
    ├── userId, type, title, body, isRead, etc.

network_connections        - اتصالات الشبكات
├── {connectionId}
    ├── vendorId, networkId, balance, stock, etc.
```

---

## 💼 سير العمل الرئيسي

### **1. إضافة باقة جديدة (Network Owner)**

```dart
1. المستخدم يفتح AddPackagePage
2. يدخل معلومات الباقة
3. يضغط "حفظ"
   └─> FirebasePackageService.addPackage()
       └─> Firestore.collection('packages').add()
4. النجاح → العودة إلى NetworkPage
5. PackageProvider يتحدث تلقائياً (Stream)
```

### **2. إرسال طلب كروت (POS Vendor)**

```dart
1. المتجر يفتح SendOrderPage
2. يختار الباقات والكميات
3. يضغط "إرسال"
   └─> FirebaseOrderService.createOrder()
       ├─> Firestore.collection('orders').add()
       └─> FirebaseNotificationService.notifyNewOrder()
4. مالك الشبكة يستلم إشعار
```

### **3. الموافقة على طلب (Network Owner)**

```dart
1. مالك الشبكة يفتح NetworkPage → تبويب الطلبات
2. يضغط "موافقة" على الطلب
   └─> FirebaseOrderService.approveOrder()
       ├─> نقل الكروت من cards إلى vendor_cards
       ├─> تحديث المخزون في network_connections
       ├─> إنشاء معاملة في transactions
       ├─> تحديث حالة الطلب → 'approved'
       └─> إرسال إشعار للمتجر
3. المتجر يستلم إشعار
4. الكروت تظهر في مخزون المتجر
```

### **4. دفعة نقدية (Network Owner → POS Vendor)**

```dart
1. مالك الشبكة يفتح NetworkCashPaymentPage
2. يختار المتجر والمبلغ
3. يضغط "إرسال"
   └─> FirebaseCashPaymentService.createPaymentRequest()
       ├─> Firestore.collection('cash_payment_requests').add()
       └─> إرسال إشعار للمتجر

4. المتجر يستلم إشعار: "قام الشبكة بإضافة دفعة نقدية..."
5. المتجر يضغط "تأكيد"
   └─> FirebaseCashPaymentService.approvePaymentRequest()
       ├─> إنشاء معاملة (type: 'payment', amount: -X)
       ├─> تحديث الرصيد في network_connections
       ├─> تحديث حالة الطلب → 'approved'
       └─> إرسال إشعار لمالك الشبكة

6. مالك الشبكة يستلم إشعار: "أكد المتجر صحة الدفعة..."
7. الرصيد يتحدث تلقائياً
```

---

## 🔧 دوال Firebase الأساسية

### **1. FirebaseOrderService**

```dart
// إنشاء طلب
static Future<String> createOrder(OrderModel order)

// الحصول على طلبات الشبكة
static Stream<List<OrderModel>> getNetworkOrders(String networkId)

// الموافقة على طلب
static Future<void> approveOrder(String orderId, String networkId)

// رفض طلب
static Future<void> rejectOrder(String orderId, String networkId)

// حذف طلب
static Future<void> deleteOrder(String orderId)
```

### **2. FirebaseCashPaymentService**

```dart
// إنشاء طلب دفعة
static Future<String> createPaymentRequest(...)

// الموافقة على دفعة
static Future<void> approvePaymentRequest(String requestId, String vendorId)

// رفض دفعة
static Future<void> rejectPaymentRequest(String requestId, String vendorId)

// الحصول على طلبات المتجر
static Stream<List<CashPaymentRequestModel>> getVendorPaymentRequests(String vendorId)

// الحصول على طلبات الشبكة
static Stream<List<CashPaymentRequestModel>> getNetworkPaymentRequests(String networkId)
```

### **3. FirebaseNotificationService**

```dart
// إنشاء إشعار
static Future<String> createNotification(NotificationModel notification)

// الحصول على إشعارات المستخدم
static Stream<List<NotificationModel>> getUserNotifications(String userId)

// عدد الإشعارات غير المقروءة
static Stream<int> getUnreadCount(String userId)

// تحديد كمقروء
static Future<void> markAsRead(String notificationId)

// تحديد الكل كمقروء
static Future<void> markAllAsRead(String userId)

// حذف إشعار
static Future<void> deleteNotification(String notificationId)
```

---

## 🎨 مكونات UI القابلة لإعادة الاستخدام

### **1. AppCard**

```dart
AppCard(
  onTap: () => print('تم النقر'),
  padding: EdgeInsets.all(16.w),
  child: Text('محتوى البطاقة'),
)
```

### **2. AppButton**

```dart
AppButton(
  text: 'حفظ',
  variant: AppButtonVariant.primary,  // primary, secondary, outline, error
  size: AppButtonSize.medium,         // small, medium, large
  onPressed: () => _save(),
)
```

### **3. CustomToast**

```dart
// نجاح
CustomToast.success(
  context,
  'تم الحفظ بنجاح',
  title: 'نجح',
);

// خطأ
CustomToast.error(
  context,
  'فشلت العملية',
  title: 'خطأ',
);

// تحذير
CustomToast.warning(
  context,
  'يرجى التحقق من البيانات',
  title: 'تنبيه',
);
```

### **4. Skeleton Loaders**

```dart
// أثناء التحميل
SkeletonCard()
SkeletonLine(width: 100)
SkeletonBox(width: 50, height: 50)
```

---

## 🐛 تصحيح الأخطاء الشائعة

### **1. "لا توجد معاملات"**

```dart
// السبب: vendorId غير مطابق في transactions
// الحل: تحقق من:
1. Document ID في vendors = user.id ✅
2. vendorId في transactions = user.id ✅
3. networkId صحيح ✅
```

### **2. "permission-denied"**

```dart
// السبب: Firebase Security Rules
// الحل:
1. تحقق من Firestore Rules في Firebase Console
2. تأكد من isAuthenticated()
3. راجع الصلاحيات للمجموعة المحددة
```

### **3. "الرصيد غير صحيح"**

```dart
// السبب: حساب المدفوعات خاطئ
// الحل:
1. تحقق من amount في transactions (سالب أم موجب)
2. تأكد من استخدام .abs() عند جمع المدفوعات
3. الرصيد = totalCharges - totalPayments
```

---

## 📚 موارد إضافية

### **الوثائق الداخلية:**
- `HOW_TO_CHECK_DATABASE.md` - فحص قاعدة البيانات
- `PROJECT_CLEANUP_REPORT.md` - تقرير التنظيف
- `BEST_PRACTICES.md` - أفضل الممارسات
- `SESSION_SUMMARY.md` - ملخص التحسينات

### **الوثائق التقنية:**
- [Flutter Docs](https://docs.flutter.dev/)
- [Firebase Docs](https://firebase.google.com/docs)
- [FlutterFire Docs](https://firebase.flutter.dev/)

---

## ✨ نصائح للمطورين الجدد

1. 📖 **اقرأ الكود الموجود أولاً** قبل إضافة ميزات جديدة
2. 🧪 **اختبر التغييرات** على جهاز حقيقي
3. 🔍 **استخدم print()** للتتبع أثناء التطوير
4. 💾 **احفظ نسخ احتياطية** من قاعدة البيانات
5. 📱 **اختبر على iOS و Android** كليهما
6. 🔐 **لا تشارك Firebase config** في git
7. 📊 **راقب Firebase Console** بانتظام
8. 🎨 **اتبع نمط الكود الحالي** للتناسق

---

**حظاً موفقاً في التطوير! 🚀**

