# إصلاح بطاقة عرض معلومات المتجر

## المشكلة
في بطاقة عرض معلومات المتجر (accounts_page)، كان يظهر نفس الاسم في كل من:
- اسم المتجر
- اسم المالك

بدلاً من عرض اسم المتجر واسم المالك بشكل منفصل.

## السبب
كانت المشكلة في عدة أماكن حيث يتم إنشاء `VendorModel` من بيانات المستخدم:

### 1. في `firebase_vendor_service.dart` - دالة `searchAvailableVendors`
```dart
// الكود القديم (خطأ):
name: data['name'] as String? ?? '',
ownerName: data['name'] as String? ?? '', // نفس الاسم ❌
```

كان يستخدم `data['name']` لكل من `name` و `ownerName`.

### 2. في `network_page.dart` - عند إضافة متجر تلقائياً
```dart
// الكود القديم (خطأ):
name: order.vendorName,
ownerName: userData['name'] as String? ?? order.vendorName, ❌
```

كان يستخدم `userData['name']` (اسم المتجر) بدلاً من `userData['ownerName']` (اسم المالك).

## الحل

### 1. إصلاح `firebase_vendor_service.dart`
```dart
// الكود الجديد (صحيح):
final vendor = VendorModel(
  id: doc.id,
  userId: doc.id,
  name: data['name'] as String? ?? '', // اسم المتجر ✅
  ownerName: data['ownerName'] as String? ?? '', // اسم مالك المتجر ✅
  // ... باقي الحقول
);
```

### 2. إصلاح `network_page.dart`
```dart
// الكود الجديد (صحيح):
final newVendor = VendorModel(
  id: order.vendorId,
  userId: order.vendorId,
  name: userData['name'] as String? ?? order.vendorName, // اسم المتجر ✅
  ownerName: userData['ownerName'] as String? ?? userData['name'] as String? ?? '', // اسم المالك ✅
  // ... باقي الحقول
);
```

## بطاقة عرض المتجر في `accounts_page.dart`

البطاقة كانت تعرض البيانات بشكل صحيح:

```dart
// اسم المتجر
Text(
  widget.vendor.name,
  style: TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.gray900,
  ),
)

// اسم المالك
Row(
  children: [
    Icon(Icons.person_outline, size: 12.w, color: AppColors.gray500),
    SizedBox(width: 3.w),
    Text(
      widget.vendor.ownerName,
      style: TextStyle(
        fontSize: 11.sp,
        color: AppColors.gray600,
      ),
    ),
  ],
)
```

لكن المشكلة كانت في البيانات المحملة من Firestore.

## النتيجة

✅ **الآن عند عرض بطاقة المتجر:**
- السطر الأول: يعرض **اسم المتجر** (من `vendor.name`)
- السطر الثاني (مع أيقونة الشخص): يعرض **اسم مالك المتجر** (من `vendor.ownerName`)

✅ **عند البحث عن متاجر:**
- يتم تحميل اسم المتجر واسم المالك بشكل صحيح من users collection

✅ **عند إضافة متجر تلقائياً:**
- يتم حفظ اسم المتجر واسم المالك بشكل صحيح في vendors collection

## الملفات المُحدثة

1. **lib/features/network_owner/data/services/firebase_vendor_service.dart**
   - إصلاح `searchAvailableVendors` لقراءة `ownerName` من `data['ownerName']`

2. **lib/features/network_owner/presentation/pages/network_page.dart**
   - إصلاح إضافة المتجر التلقائي لاستخدام `userData['ownerName']`

## اختبار الإصلاح

للتحقق من أن الإصلاح يعمل بشكل صحيح:

1. **إضافة متجر جديد عبر البحث:**
   - افتح صفحة الحسابات → ابحث عن متجر
   - أضف المتجر
   - تحقق من أن البطاقة تعرض اسم المتجر واسم المالك بشكل منفصل

2. **إضافة متجر تلقائياً عبر الطلبات:**
   - استلم طلب من متجر جديد
   - اضغط على الموافقة → أضف المتجر
   - تحقق من أن البطاقة تعرض اسم المتجر واسم المالك بشكل منفصل

3. **عرض المتاجر المضافة:**
   - افتح صفحة الحسابات
   - تحقق من أن جميع بطاقات المتاجر تعرض البيانات بشكل صحيح

## ملاحظات

- البيانات القديمة (المتاجر المضافة قبل الإصلاح) قد تحتوي على نفس القيمة في `name` و `ownerName`
- المتاجر الجديدة (المضافة بعد الإصلاح) ستعرض البيانات بشكل صحيح
- يمكن تحديث البيانات القديمة يدوياً من صفحة Profile للمتجر

