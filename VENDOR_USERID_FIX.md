# إصلاح مشكلة عرض معاملات المتاجر

## المشكلة
بعد إضافة متجر جديد (سواء يدوياً أو تلقائياً عند الموافقة على الطلب)، كانت بطاقة المتجر تظهر في قائمة المتاجر، لكن عند محاولة عرض صفحة المعاملات كانت تظهر رسالة "لم يتم العثور على متجر".

## السبب
كانت المشكلة في استخدام `vendor.id` الذي أصبح الآن يحتوي على **composite key** (`networkId_userId`) بدلاً من `userId` الحقيقي. عند فتح صفحة المعاملات، كان يتم تمرير composite key بدلاً من userId الحقيقي، مما يسبب فشل في جلب البيانات.

## الحل

### 1. تحديث VendorModel
تم إضافة حقل `userId` جديد في `VendorModel` للاحتفاظ بـ userId الحقيقي من users collection:

```dart
class VendorModel {
  VendorModel({
    required this.id,        // Document ID (composite key)
    this.userId,             // userId الحقيقي من users
    // ... باقي الحقول
  });

  final String id;           // Document ID: {networkId}_{userId}
  final String? userId;      // User ID الحقيقي
  
  // Getter للحصول على userId الحقيقي (مع fallback للتوافق)
  String get realUserId => userId ?? id;
}
```

### 2. تحديث firebase_vendor_service.dart
تم تحديث جميع العمليات لاستخدام `realUserId`:

- **addVendor**: حفظ userId الحقيقي في document
- **_createNetworkConnection**: استخدام realUserId في الاستعلامات
- **updateVendor**: استخدام realUserId في composite key
- **searchAvailableVendors**: تمرير userId عند إنشاء VendorModel

### 3. تحديث الصفحات

#### accounts_page.dart
- تم تحديث `onTap` لتمرير `vendor.realUserId` بدلاً من `vendor.id`
- تم تحديث `_handleDeleteVendor` لاستخدام `realUserId`
- تم تحديث `_getVendorRealTimeData` لاستخدام `realUserId` في جميع الاستعلامات

#### network_owner_home_page.dart
- تم تحديث `_loadTopVendors` لاستخدام `realUserId` في جميع الاستعلامات:
  - استعلام orders
  - استعلام cash_payment_requests
  - استعلام transactions
  - استعلام vendor_cards
- تم تحديث `_loadOrders` لاستخدام `realUserId` كمفتاح في `_vendorsMap` لتطابق `order.vendorId`

#### vendor_search_page.dart
- تم تحديث `_addVendor` لتمرير `userId` عند إنشاء VendorModel

#### network_page.dart
- تم تحديث `_handleApprove` لتمرير `userId` عند إضافة المتجر تلقائياً

## النتيجة
الآن عند إضافة متجر جديد:
1. يتم حفظ userId الحقيقي في حقل `userId` بجانب composite key في `id`
2. عند فتح صفحة المعاملات، يتم تمرير userId الحقيقي
3. يتم جلب بيانات المتجر والمعاملات بنجاح
4. تظهر جميع البيانات بشكل صحيح

## التوافق الخلفي
تم إضافة getter `realUserId` الذي يعيد:
- `userId` إذا كان موجوداً (البيانات الجديدة)
- `id` كـ fallback (للبيانات القديمة)

هذا يضمن عمل النظام مع البيانات القديمة والجديدة.

## الملفات المُحدثة
1. `lib/features/network_owner/data/models/vendor_model.dart`
2. `lib/features/network_owner/data/services/firebase_vendor_service.dart`
3. `lib/features/network_owner/presentation/pages/accounts_page.dart`
4. `lib/features/network_owner/presentation/pages/network_owner_home_page.dart`
5. `lib/features/network_owner/presentation/pages/vendor_search_page.dart`
6. `lib/features/network_owner/presentation/pages/network_page.dart`

