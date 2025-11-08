# 🔍 دليل فحص وإصلاح قاعدة البيانات

## 📋 نظرة عامة

تم إصلاح مشكلة **عدم ظهور الدفعات النقدية** في قائمة المعاملات وإضافة أدوات فحص شاملة.

---

## ✅ ما تم إصلاحه

### 1️⃣ إصلاحات الكود (تلقائي للمعاملات الجديدة)

✅ **firebase_order_service.dart**
- إضافة `vendorName` في معاملات الطلبات
- إنشاء معاملة في `vendor_transactions` عند الموافقة على الطلب

✅ **firebase_cash_payment_service.dart**
- تحويل نوع المعاملة من `cash_payment_received` إلى `payment`
- تحويل المبلغ من موجب إلى سالب (المنطق الصحيح)
- إضافة حقل `date` في معاملات المتجر

✅ **firebase_transaction_service.dart**
- دعم المعاملات القديمة والجديدة
- حساب صحيح للمستحقات والمدفوعات

✅ **merchant_transactions_page.dart**
- عرض الدفعات بنوعيها (القديم والجديد)
- ألوان صحيحة (أحمر للدين، أخضر للتسديد)

---

## 🛠️ الأدوات المتوفرة

### 1. خدمة الترحيل (`firebase_transaction_migration_service.dart`)

**الوظائف:**
```dart
// ترحيل الدفعات القديمة
migrateOldCashPayments()
// cash_payment_received → payment
// amount موجب → سالب

// إضافة حقل status المفقود
addMissingStatusField()

// إضافة حقل date المفقود
addMissingDateField()

// تشغيل كل شيء
runAllMigrations()
```

### 2. خدمة الفحص (`database_integrity_checker.dart`)

**الوظائف:**
```dart
// فحص شامل
runFullAudit(networkId)

// فحص الطلبات
_auditOrders(networkId)

// فحص الدفعات
_auditCashPayments(networkId)

// فحص الأرصدة
_auditBalances(networkId)

// توليد تقرير
generateReport(networkId)
```

---

## 🚀 طريقة الفحص والإصلاح

### الطريقة 1: استخدام Debug Console

#### الخطوة 1: أضف هذا الكود في أي صفحة مؤقتاً

```dart
import 'package:network_app/features/network_owner/data/services/database_integrity_checker.dart';
import 'package:network_app/features/network_owner/data/services/firebase_transaction_migration_service.dart';

// في أي دالة async
Future<void> checkDatabase() async {
  final networkId = 'your_network_id_here';
  
  print('🔍 بدء الفحص الشامل...\n');
  
  // 1. فحص شامل
  final auditResults = await DatabaseIntegrityChecker.runFullAudit(networkId);
  
  // 2. طباعة التقرير
  final report = await DatabaseIntegrityChecker.generateReport(networkId);
  print(report);
  
  // 3. إصلاح المشاكل
  print('\n🔧 بدء الإصلاح التلقائي...\n');
  final migrationResults = await FirebaseTransactionMigrationService.runAllMigrations();
  
  print('\n✅ النتائج:');
  print('   - حقول status مضافة: ${migrationResults['statusAdded']}');
  print('   - حقول date مضافة: ${migrationResults['dateAdded']}');
  print('   - دفعات مرحلة: ${migrationResults['paymentsUpdated']}');
}
```

### الطريقة 2: استخدام Firebase Console مباشرة

#### فحص يدوي:

1. **افتح Firebase Console** → Firestore Database

2. **افحص مجموعة `transactions`:**
   ```
   - ابحث عن: type == "cash_payment_received"
   - ✅ إذا وجدت: هذه معاملات قديمة تحتاج ترحيل
   ```

3. **افحص التطابق:**
   ```sql
   -- في كل طلب معتمد (orders)
   SELECT * FROM orders WHERE status = 'approved'
   
   -- يجب أن يكون له معاملة في (transactions)
   SELECT * FROM transactions WHERE orderId = 'order_id_here'
   
   -- يجب أن يكون له معاملة في (vendor_transactions)
   SELECT * FROM vendor_transactions WHERE orderId = 'order_id_here'
   ```

---

## 📊 كيف تتحقق من صحة البيانات

### اختبار التطابق:

#### السيناريو: متجر "الأمل" مع شبكة "النور"

1. **جمع معاملات transactions:**
   ```javascript
   Filter: vendorId == "vendor_123" AND networkId == "network_456"
   
   Results:
   - charge: +5000 (طلب 1)
   - charge: +3000 (طلب 2)
   - payment: -2000 (دفعة 1)
   - charge: +1500 (طلب 3)
   - payment: -4000 (دفعة 2)
   
   المجموع: 5000 + 3000 - 2000 + 1500 - 4000 = +3500 ر.ي
   ```

2. **جمع معاملات vendor_transactions:**
   ```javascript
   Filter: vendorId == "vendor_123" AND networkId == "network_456"
   
   Results (بعد الإصلاح):
   - charge: +5000 (طلب 1) ✅
   - charge: +3000 (طلب 2) ✅
   - cash_payment_sent: -2000 (دفعة 1) ✅
   - charge: +1500 (طلب 3) ✅
   - cash_payment_sent: -4000 (دفعة 2) ✅
   
   المجموع: 5000 + 3000 - 2000 + 1500 - 4000 = +3500 ر.ي
   ```

3. **الرصيد المسجل في `vendors`:**
   ```javascript
   vendors/vendor_123:
     balance: 3500 ر.ي
   ```

4. **التحقق:**
   ```
   transactions: 3500 ✅
   vendor_transactions: 3500 ✅
   vendor.balance: 3500 ✅
   
   التطابق: 100% ✅
   ```

---

## 🎯 خطوات التنفيذ الموصى بها

### المرحلة 1: الفحص (5 دقائق)

```dart
// شغّل هذا في الكود
final networkId = 'YOUR_NETWORK_ID';
final results = await DatabaseIntegrityChecker.runFullAudit(networkId);
final report = await DatabaseIntegrityChecker.generateReport(networkId);
print(report);
```

**النتيجة المتوقعة:**
```
📦 الطلبات المعتمدة:
   الإجمالي: 25
   مع معاملة شبكة: 25
   بدون معاملة شبكة: 0 ✅
   مع معاملة متجر: 0
   بدون معاملة متجر: 25 🔴  ← مشكلة!
```

### المرحلة 2: الترحيل (10 دقائق)

```dart
// إصلاح المعاملات القديمة
final migrationResults = await FirebaseTransactionMigrationService.runAllMigrations();
```

**النتيجة المتوقعة:**
```
✅ Migration completed successfully!
   - Status fields added: 12
   - Date fields added: 7
   - Payments migrated: 9
```

### المرحلة 3: التحقق النهائي (5 دقائق)

```dart
// أعد الفحص
final finalResults = await DatabaseIntegrityChecker.runFullAudit(networkId);
```

**النتيجة المتوقعة:**
```
✅ لا توجد مشاكل - قاعدة البيانات سليمة تماماً!
```

---

## ⚠️ ملاحظات مهمة

### المعاملات الجديدة (بعد الإصلاح):

✅ **عند طلب جديد:**
- يُنشئ معاملة في `transactions` (للشبكة)
- يُنشئ معاملة في `vendor_transactions` (للمتجر)
- كلاهما بنفس المبلغ والبيانات

✅ **عند دفعة جديدة:**
- يُنشئ معاملة في `transactions` بمبلغ سالب
- يُنشئ معاملة في `vendor_transactions` بمبلغ سالب
- يُحدّث balance في `network_connections`

### المعاملات القديمة:

⚠️ **قد تحتاج ترحيل:**
- معاملات طلبات بدون vendor_transactions
- دفعات بنوع `cash_payment_received` ومبلغ موجب
- معاملات بدون حقل `status` أو `date`

---

## 📞 الدعم

إذا واجهت مشاكل:

1. **تحقق من Debug Console** - ستظهر رسائل مفصلة
2. **راجع التقرير** - DATABASE_AUDIT_REPORT.md
3. **استخدم أدوات الفحص** - للتأكد من سلامة البيانات

---

**📅 آخر تحديث:** 29 أكتوبر 2025  
**✅ الحالة:** جاهز للاستخدام


