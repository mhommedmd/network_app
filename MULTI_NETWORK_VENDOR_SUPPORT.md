# 🔄 دعم تعدد الشبكات للمتاجر (Multi-Network Vendor Support)

## 📋 المشكلة الأصلية

كان النظام القديم يمنع:
- ❌ إضافة متجر (POS Vendor) لأكثر من شبكة واحدة
- ❌ شبكة ثانية من إضافة متجر مضاف مسبقاً لشبكة أخرى
- ❌ كان الخطأ: `PERMISSION_DENIED: Missing or insufficient permissions`

**السبب:** كان يستخدم `vendors/{vendorId}` مما يعني document واحد فقط لكل متجر.

---

## ✅ الحل المطبق

### 1️⃣ **Composite Key في Vendors Collection**

تم تغيير Document ID من:
```
vendors/{vendorId}
```

إلى:
```
vendors/{networkId}_{vendorId}
```

**الفوائد:**
- ✅ نفس المتجر يمكنه التعامل مع عدة شبكات
- ✅ كل شبكة لها سجل منفصل للمتجر (رصيد، مخزون، معاملات)
- ✅ عزل كامل بين بيانات الشبكات المختلفة

---

## 📝 التعديلات المنفذة

### **1. firebase_vendor_service.dart**

#### ✨ `addVendor()` - استخدام Composite Key
```dart
// قبل
await _firestore.collection('vendors').doc(vendor.id).set(vendorData);

// بعد
final documentId = '${vendor.networkId}_${vendor.id}';
await _firestore.collection('vendors').doc(documentId).set(vendorData);
```

#### ✨ `_createNetworkConnection()` - منع التكرار
```dart
// التحقق من وجود اتصال مسبق قبل الإضافة
final existingConnection = await _firestore
    .collection('network_connections')
    .where('vendorId', isEqualTo: vendor.id)
    .where('networkId', isEqualTo: vendor.networkId)
    .limit(1)
    .get();

if (existingConnection.docs.isNotEmpty) {
  return; // لا نضيف مرة أخرى
}
```

#### ✨ `searchAvailableVendors()` - استخراج userId
```dart
// قبل
final addedVendorIds = addedVendorsSnapshot.docs
    .map((doc) => doc.id)
    .toSet();

// بعد
final addedVendorIds = addedVendorsSnapshot.docs
    .map((doc) => doc.data()['userId'] as String?)
    .where((id) => id != null)
    .cast<String>()
    .toSet();
```

#### ✨ `getVendor()` - دعم networkId اختياري
```dart
static Future<VendorModel?> getVendor(String vendorId, {String? networkId}) async {
  if (networkId != null) {
    final documentId = '${networkId}_$vendorId';
    final doc = await _firestore.collection('vendors').doc(documentId).get();
    // ...
  }
  // Fallback للكود القديم
}
```

#### ✨ `deleteVendor()`, `updateVendorBalance()`, `updateVendorStock()`
```dart
// تحديث جميع الدوال لاستخدام composite key
static Future<void> deleteVendor(String vendorId, String networkId) async {
  final documentId = '${networkId}_$vendorId';
  await _firestore.collection('vendors').doc(documentId).delete();
}
```

### **2. vendor_provider.dart**

تحديث جميع الاستدعاءات لتمرير `_networkId`:
```dart
await FirebaseVendorService.deleteVendor(vendorId, _networkId);
await FirebaseVendorService.updateVendorBalance(vendorId, _networkId, newBalance);
await FirebaseVendorService.updateVendorStock(vendorId, _networkId, newStock);
```

### **3. firestore.rules**

تحديث قواعد Vendors collection:
```javascript
// قبل
match /vendors/{vendorId} {
  allow read: if isAuthenticated();
  allow create: if isNetworkOwner();
  allow update, delete: if isNetworkOwner() && 
                          resource.data.networkId == getUserId();
}

// بعد
match /vendors/{compositeId} {
  allow read: if isAuthenticated();
  allow create: if isNetworkOwner() && 
                  request.resource.data.networkId == getUserId();
  allow update, delete: if isNetworkOwner() && 
                          resource.data.networkId == getUserId();
}
```

**التغيير الرئيسي:** إضافة شرط `request.resource.data.networkId == getUserId()` في `allow create` للتأكد من أن الشبكة تضيف المتجر لنفسها فقط.

### **4. merchant_transactions_page.dart**

```dart
// تمرير networkId عند جلب بيانات المتجر
final vendor = await FirebaseVendorService.getVendor(
  widget.vendorId,
  networkId: networkId,
);
```

---

## 🚀 كيفية النشر

### **الخطوة 1: نشر Firestore Rules**

1. افتح Firebase Console
2. اذهب إلى **Firestore Database** → **Rules**
3. انسخ محتوى ملف `firestore.rules`
4. الصق في المحرر
5. اضغط **Publish**

### **الخطوة 2: اختبار الميزة**

1. سجل دخول كـ Network Owner 1
2. ابحث عن متجر وأضفه
3. سجل خروج وسجل دخول كـ Network Owner 2
4. ابحث عن نفس المتجر
5. ✅ **يجب أن تتمكن من إضافته بنجاح!**

---

## 📊 بنية البيانات الجديدة

### **مثال: متجر واحد مع شبكتين**

```
vendors/
  ├── network1_vendor123
  │   ├── userId: "vendor123"
  │   ├── networkId: "network1"
  │   ├── balance: 5000
  │   └── stock: 100
  │
  └── network2_vendor123
      ├── userId: "vendor123"
      ├── networkId: "network2"
      ├── balance: 3000
      └── stock: 50
```

### **network_connections**
```
network_connections/
  ├── connection_1
  │   ├── vendorId: "vendor123"
  │   ├── networkId: "network1"
  │   └── balance: 5000
  │
  └── connection_2
      ├── vendorId: "vendor123"
      ├── networkId: "network2"
      └── balance: 3000
```

---

## ✨ المزايا

1. ✅ **عزل كامل** - كل شبكة لها بيانات مستقلة للمتجر
2. ✅ **تعدد الشبكات** - المتجر يمكنه العمل مع عدد غير محدود من الشبكات
3. ✅ **أمان محسّن** - كل شبكة تتحكم في بياناتها فقط
4. ✅ **مرونة** - سهولة إضافة/حذف علاقات بين المتجر والشبكات
5. ✅ **توافق خلفي** - `getVendor()` يدعم الكود القديم مع fallback

---

## ⚠️ ملاحظات مهمة

1. **userId المحفوظ:** كل document في vendors يحتوي على `userId` للربط مع `users` collection
2. **network_connections:** يتم إنشاء اتصال تلقائياً مع فحص عدم التكرار
3. **Backward Compatibility:** `getVendor()` يدعم استدعاء بدون `networkId` للتوافق

---

## 📅 تاريخ التطبيق

- **التاريخ:** 2 نوفمبر 2025
- **الإصدار:** v1.1.0
- **الحالة:** ✅ جاهز للنشر

---

## 🔧 Migration للبيانات الموجودة (اختياري)

إذا كان لديك بيانات موجودة في `vendors/{vendorId}`، يمكنك تشغيل migration script:

```javascript
// Cloud Function أو Firebase Console
const admin = require('firebase-admin');
const db = admin.firestore();

async function migrateVendors() {
  const vendorsSnapshot = await db.collection('vendors').get();
  
  for (const doc of vendorsSnapshot.docs) {
    const data = doc.data();
    const vendorId = doc.id;
    const networkId = data.networkId;
    
    if (networkId && vendorId) {
      // إنشاء document جديد بـ composite key
      const newDocId = `${networkId}_${vendorId}`;
      await db.collection('vendors').doc(newDocId).set({
        ...data,
        userId: vendorId
      });
      
      // حذف القديم (اختياري)
      // await db.collection('vendors').doc(vendorId).delete();
    }
  }
  
  console.log('Migration completed!');
}
```

---

## 🎯 الخلاصة

✨ **المتاجر الآن يمكنها:**
- 🌐 التعامل مع عدة شبكات في نفس الوقت
- 💰 رصيد منفصل لكل شبكة
- 📦 مخزون منفصل لكل شبكة
- 🔒 أمان كامل وعزل للبيانات

**المشكلة:** ✅ **تم حلها!**

