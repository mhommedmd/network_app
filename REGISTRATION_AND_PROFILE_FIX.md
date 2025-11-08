# إصلاح عملية التسجيل وعرض معلومات المستخدم

## المشكلة
عند إنشاء حساب جديد، كانت البيانات لا تُحفظ بشكل صحيح:
- **لحسابات networkowner**: `ownerName` كان يظهر في كل من "الاسم الكامل" و "اسم الشبكة"
- **لحسابات posvendor**: `ownerName` كان يظهر في كل من "الاسم الكامل" و "اسم المتجر"

## السبب
1. كان يتم استخدام `entityName` لحفظ اسم الشبكة/المتجر
2. البيانات كانت تُحفظ بشكل غير متسق بين User model و Firestore
3. صفحة Profile كانت تعرض الحقول بشكل خاطئ

## الحل المطبق

### 1. تحديث عملية التسجيل (`register_page.dart`)

#### إزالة `entityName`
- تم استبدال `_entityNameController` بـ `_networkOrStoreNameController`
- تم إزالة `entityName` من جميع الأماكن

#### تحديث منطق حفظ البيانات
**لحسابات networkowner:**
```dart
profileData['networkName'] = networkOrStoreName; // اسم الشبكة
profileData['ownerName'] = ownerName;           // اسم مالك الشبكة
// يتم تمرير ownerName كـ name في دالة register
```

**لحسابات posvendor:**
```dart
profileData['name'] = networkOrStoreName;  // اسم المتجر
profileData['ownerName'] = ownerName;      // اسم مالك المتجر
// يتم تمرير اسم المتجر كـ name في دالة register
```

### 2. تحديث User Model (`auth_provider.dart`)

#### إضافة حقل `ownerName`
```dart
class User {
  final String name;
  final String? ownerName;    // جديد!
  final String? networkName;
  // ... باقي الحقول
}
```

#### تحديث الدوال
- `fromJson`: إضافة قراءة `ownerName` من Firestore
- `toJson`: إضافة حفظ `ownerName` إلى Firestore
- `copyWith`: إضافة `ownerName` للدعم

### 3. تحديث دالة تحديث الملف الشخصي

تم إضافة `ownerName` كمعامل في `updateUserProfile`:
```dart
Future<bool> updateUserProfile({
  String? name,
  String? ownerName,      // جديد!
  String? networkName,
  // ... باقي المعاملات
})
```

### 4. تحديث صفحة Profile (`profile_page.dart`)

#### إضافة Controller جديد
```dart
late TextEditingController _ownerNameController;
```

#### تحديث عرض الحقول

**لحسابات posVendor:**
```dart
// اسم المتجر من name
_buildInfoField(
  label: 'اسم المتجر',
  controller: _nameController,
  icon: Icons.store,
)

// اسم مالك المتجر من ownerName
_buildInfoField(
  label: 'اسم مالك المتجر',
  controller: _ownerNameController,
  icon: Icons.person,
)
```

**لحسابات networkOwner:**
```dart
// اسم مالك الشبكة من name
_buildInfoField(
  label: 'اسم مالك الشبكة',
  controller: _nameController,
  icon: Icons.person,
)

// اسم الشبكة من networkName
_buildInfoField(
  label: 'اسم الشبكة',
  controller: _networkNameController,
  icon: Icons.wifi,
)
```

## هيكل البيانات النهائي

### لحسابات networkowner
| الحقل | القيمة | الوصف |
|-------|--------|--------|
| `name` | اسم مالك الشبكة | الاسم الكامل للمالك |
| `networkName` | اسم الشبكة | اسم الشبكة (مثل: شبكة افاق نت) |
| `ownerName` | null | غير مستخدم لهذا النوع |

### لحسابات posvendor
| الحقل | القيمة | الوصف |
|-------|--------|--------|
| `name` | اسم المتجر | اسم نقطة البيع |
| `ownerName` | اسم مالك المتجر | الاسم الكامل للمالك |
| `networkName` | null | غير مستخدم لهذا النوع |

## الملفات المُحدثة

1. **lib/features/auth/presentation/pages/register_page.dart**
   - إزالة `entityName` واستبداله بـ `networkOrStoreName`
   - تحديث منطق حفظ البيانات
   - تحديث Labels للحقول

2. **lib/core/providers/auth_provider.dart**
   - إضافة حقل `ownerName` في User class
   - تحديث `fromJson`, `toJson`, `copyWith`
   - تحديث `updateUserProfile` لدعم `ownerName`

3. **lib/features/common/presentation/pages/profile_page.dart**
   - إضافة `_ownerNameController`
   - تحديث عرض الحقول حسب نوع الحساب
   - تحديث منطق حفظ التغييرات

## النتيجة

✅ الآن عند إنشاء حساب جديد:
- لـ networkowner: يتم حفظ اسم المالك في `name` واسم الشبكة في `networkName`
- لـ posvendor: يتم حفظ اسم المتجر في `name` واسم المالك في `ownerName`

✅ في صفحة Profile:
- تظهر الحقول الصحيحة لكل نوع حساب
- يمكن تعديل جميع البيانات بشكل صحيح
- لا يوجد تكرار أو خلط في البيانات

✅ في الصفحات الرئيسية:
- posVendor: يعرض اسم المتجر بشكل صحيح من `user?.name`
- networkOwner: يعرض اسم الشبكة بشكل صحيح من `user?.networkName`

## الإصلاحات الإضافية

### إصلاح عدم ظهور البيانات بعد التسجيل

**المشكلة**: بعد إنشاء حساب جديد، كانت بعض الحقول (مثل `networkName` لـ networkOwner) تظهر فارغة في Profile.

**السبب**: دالة `register()` تحفظ User object الأولي بدون الحقول الإضافية، ثم يتم حفظ هذه الحقول في Firestore لكن User object في الذاكرة لا يتم تحديثه.

**الحل**: بعد حفظ البيانات في Firestore، يتم استدعاء `updateUserProfile` لتحديث User object في الذاكرة:

```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set(profileData, SetOptions(merge: true));

// تحديث User object في الذاكرة
if (_isNetworkOwner) {
  await authProvider.updateUserProfile(
    name: ownerName,
    networkName: networkOrStoreName,
    ownerName: ownerName,
  );
} else {
  await authProvider.updateUserProfile(
    name: networkOrStoreName,
    ownerName: ownerName,
  );
}
```

### تحديث دالة حفظ التعديلات

تم تحديث `_saveProfileChanges` لحفظ `ownerName` دائماً (بدلاً من فقط عند posVendor):

```dart
final success = await authProvider.updateUserProfile(
  name: newName,
  ownerName: newOwnerName, // حفظ ownerName دائماً
  networkName: newNetworkName,
  // ... باقي الحقول
);
```

## ملاحظات مهمة

1. **التوافق الخلفي**: الكود الجديد متوافق مع البيانات القديمة (حيث أن `ownerName` هو حقل optional)
2. **لا حاجة لتحديث قاعدة البيانات**: الحسابات القديمة ستستمر في العمل، والحسابات الجديدة ستستخدم الهيكل الجديد
3. **الأمان**: جميع التحديثات تحترم قواعد Firestore الأمنية

## اختبار التغييرات

للتأكد من أن التغييرات تعمل بشكل صحيح:

1. إنشاء حساب `networkowner` جديد:
   - التحقق من حفظ اسم المالك واسم الشبكة بشكل منفصل
   - التحقق من ظهور البيانات الصحيحة في Profile

2. إنشاء حساب `posvendor` جديد:
   - التحقق من حفظ اسم المتجر واسم المالك بشكل منفصل
   - التحقق من ظهور البيانات الصحيحة في Profile

3. تحديث البيانات في Profile:
   - التحقق من حفظ التعديلات بشكل صحيح
   - التحقق من أن البيانات لا تتداخل أو تتكرر

