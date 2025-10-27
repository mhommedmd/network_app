# 📦 نظام تخزين الكروت في Firebase

## 🎯 نظرة عامة

تم تطوير نظام متكامل لتخزين أرقام الكروت في Firebase Firestore، مما يوفر:
- ✅ تخزين آمن وموثوق في السحابة
- ✅ مزامنة تلقائية عبر جميع الأجهزة
- ✅ نسخ احتياطي تلقائي
- ✅ إمكانية البحث والفلترة
- ✅ إحصائيات مفصلة
- ✅ التبديل بين المخزون المحلي و Firebase

**ملاحظة:** تم دمج عرض Firebase في الصفحة الموجودة `network_stored_page.dart` بدلاً من إنشاء صفحة جديدة.

---

## 🏗️ بنية النظام

### 1. **CardModel** - نموذج بيانات الكرت

```dart
CardModel {
  id: string                 // معرف فريد يتم توليده تلقائياً
  cardNumber: string         // رقم الكرت
  pin: string               // رقم PIN (يتم توليده تلقائياً)
  packageId: string         // معرف الباقة
  packageName: string       // اسم الباقة
  price: double            // سعر الكرت
  expiryDate: DateTime     // تاريخ انتهاء الصلاحية
  status: CardStatus       // الحالة (available, sold, used, expired, blocked)
  networkId: string        // معرف الشبكة
  createdBy: string        // من قام بالإضافة
  createdAt: DateTime      // تاريخ الإضافة
  updatedAt: DateTime      // آخر تحديث
  soldTo: string?          // تم البيع لـ (اختياري)
  soldAt: DateTime?        // تاريخ البيع (اختياري)
  usedBy: string?          // تم الاستخدام من قبل (اختياري)
  usedAt: DateTime?        // تاريخ الاستخدام (اختياري)
  notes: string?           // ملاحظات إضافية
}
```

### 2. **FirebaseCardService** - خدمة Firebase

يوفر جميع العمليات على الكروت:

#### 📥 إضافة واستيراد
- `importCards(List<CardModel>)` - استيراد عدة كروت دفعة واحدة
- `addCard(CardModel)` - إضافة كرت واحد

#### 🔄 تحديث وحذف
- `updateCardStatus(cardId, status)` - تحديث حالة الكرت
- `deleteCard(cardId)` - حذف كرت

#### 🔍 استعلام وبحث
- `getCardsByNetwork(networkId)` - الحصول على كروت شبكة معينة
- `getCardsByStatus(networkId, status)` - فلترة حسب الحالة
- `getCardsByPackage(networkId, packageId)` - فلترة حسب الباقة
- `searchCards(networkId, query)` - البحث في الكروت

#### 📊 إحصائيات
- `getCardStats(networkId)` - إحصائيات شاملة:
  - إجمالي الكروت
  - الكروت المتاحة
  - الكروت المباعة
  - الكروت المستخدمة
  - القيمة الإجمالية

#### 📤 تصدير
- `exportCardsToCSV(networkId)` - تصدير الكروت لملف CSV

### 3. **CardProvider** - مزود الحالة

يدير حالة الكروت في التطبيق:

```dart
final cardProvider = Provider.of<CardProvider>(context);

// استيراد كروت
await cardProvider.importCards(cardModels);

// تحميل الكروت
cardProvider.loadCards(networkId);

// البحث
cardProvider.searchCards(networkId, query);

// الحصول على الإحصائيات
await cardProvider.loadStats(networkId);
```

---

## 🚀 كيفية الاستخدام

### 1️⃣ استيراد الكروت من ملف

```dart
// في import_cards_page.dart
Future<void> _handleImportCards() async {
  // 1. قراءة الملف (Excel, CSV, PDF, etc)
  final cards = await _extractCardsFromFile(file, digits);
  
  // 2. التحقق من التكرار
  final duplicates = _findDuplicates(cards);
  
  // 3. إنشاء CardModel لكل كرت
  final cardModels = cards.map((cardNumber) {
    return CardModel(
      cardNumber: cardNumber,
      pin: _generateRandomPin(),
      packageName: selectedPackage,
      status: CardStatus.available,
      // ... باقي البيانات
    );
  }).toList();
  
  // 4. حفظ في Firebase
  final success = await cardProvider.importCards(cardModels);
}
```

### 2️⃣ عرض الكروت

```dart
// الاستماع للتغييرات في الوقت الفعلي
StreamBuilder<List<CardModel>>(
  stream: FirebaseCardService.getCardsByNetwork(networkId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final cards = snapshot.data!;
      return ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return CardTile(card: card);
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### 3️⃣ تحديث حالة الكرت (عند البيع)

```dart
Future<void> sellCard(String cardId, String buyerId) async {
  final success = await cardProvider.updateCardStatus(
    cardId,
    CardStatus.sold,
    soldTo: buyerId,
  );
  
  if (success) {
    showSnackBar('تم بيع الكرت بنجاح');
  }
}
```

### 4️⃣ عرض الإحصائيات

```dart
Future<void> loadDashboard(String networkId) async {
  await cardProvider.loadStats(networkId);
  
  final stats = cardProvider.stats;
  print('إجمالي الكروت: ${stats['totalCards']}');
  print('الكروت المتاحة: ${stats['availableCards']}');
  print('الكروت المباعة: ${stats['soldCards']}');
  print('القيمة الإجمالية: ${stats['totalValue']} ر.ي');
}
```

---

## 🔧 ميزات إضافية يمكن تطويرها

### 1. ربط مع معلومات الباقات
```dart
// الحصول على السعر من PackageProvider
final packageProvider = Provider.of<PackageProvider>(context);
final package = await packageProvider.getPackage(packageId);

CardModel(
  // ...
  price: package.sellingPrice,
  expiryDate: now.add(Duration(days: package.validityDays)),
);
```

### 2. التحقق من التكرار في Firebase
```dart
static Future<bool> isCardNumberExists(String networkId, String cardNumber) async {
  final snapshot = await _firestore
      .collection('cards')
      .where('networkId', isEqualTo: networkId)
      .where('cardNumber', isEqualTo: cardNumber)
      .limit(1)
      .get();
  
  return snapshot.docs.isNotEmpty;
}
```

### 3. نظام الإشعارات
```dart
// عند اقتراب انتهاء صلاحية الكروت
static Stream<List<CardModel>> getExpiringCards(String networkId, int daysBeforeExpiry) {
  final expiryThreshold = DateTime.now().add(Duration(days: daysBeforeExpiry));
  
  return _firestore
      .collection('cards')
      .where('networkId', isEqualTo: networkId)
      .where('status', isEqualTo: CardStatus.available.name)
      .where('expiryDate', isLessThan: Timestamp.fromDate(expiryThreshold))
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => CardModel.fromFirestore(doc)).toList());
}
```

### 4. تقارير متقدمة
```dart
// إحصائيات المبيعات الشهرية
static Future<Map<String, dynamic>> getMonthlySalesReport(String networkId, int year, int month) async {
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);
  
  final snapshot = await _firestore
      .collection('cards')
      .where('networkId', isEqualTo: networkId)
      .where('status', isEqualTo: CardStatus.sold.name)
      .where('soldAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('soldAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .get();
  
  return {
    'soldCount': snapshot.docs.length,
    'totalRevenue': snapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['price'] as num).toDouble()),
  };
}
```

### 5. نظام الباركود / QR Code
```dart
// توليد QR code لكل كرت
import 'package:qr_flutter/qr_flutter.dart';

Widget buildCardQR(CardModel card) {
  final qrData = json.encode({
    'cardNumber': card.cardNumber,
    'pin': card.pin,
    'package': card.packageName,
  });
  
  return QrImageView(
    data: qrData,
    version: QrVersions.auto,
    size: 200.0,
  );
}
```

---

## 📋 قواعد الأمان في Firestore

يجب إضافة هذه القواعد في Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد الكروت
    match /cards/{cardId} {
      // السماح بالقراءة لمالك الشبكة فقط
      allow read: if request.auth != null && 
                     resource.data.networkId == request.auth.uid;
      
      // السماح بالكتابة لمالك الشبكة فقط
      allow create: if request.auth != null && 
                       request.resource.data.createdBy == request.auth.uid;
      
      // السماح بالتحديث لمالك الشبكة فقط
      allow update: if request.auth != null && 
                       resource.data.networkId == request.auth.uid;
      
      // السماح بالحذف لمالك الشبكة فقط
      allow delete: if request.auth != null && 
                       resource.data.networkId == request.auth.uid;
    }
  }
}
```

---

## 🎨 واجهة المستخدم المقترحة

### 1. صفحة عرض الكروت
```
┌─────────────────────────────────┐
│  📊 إحصائيات الكروت            │
├─────────────────────────────────┤
│  إجمالي: 1,250  │  متاح: 842   │
│  مباع: 325      │  مستخدم: 83  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  🔍 البحث والفلترة             │
│  [______________________] 🔎    │
│  [الحالة ▼] [الباقة ▼] [تطبيق] │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  📝 قائمة الكروت               │
│  ┌───────────────────────────┐  │
│  │ 🎟️ 123456789             │  │
│  │ باقة مميزة | 500 ر.ي    │  │
│  │ ✅ متاح | 📅 2024-12-31  │  │
│  └───────────────────────────┘  │
│  ...                            │
└─────────────────────────────────┘
```

---

## ✅ التحسينات المطبقة

1. ✅ **تخزين تلقائي في Firebase** عند استيراد الكروت
2. ✅ **مزامنة في الوقت الفعلي** باستخدام Streams
3. ✅ **إدارة حالة الكروت** (متاح، مباع، مستخدم، منتهي)
4. ✅ **إحصائيات شاملة** لمراقبة المخزون
5. ✅ **بحث وفلترة متقدمة**
6. ✅ **تصدير البيانات** لملفات CSV
7. ✅ **معالجة الأخطاء** مع رسائل واضحة
8. ✅ **مؤشرات تحميل** لتحسين تجربة المستخدم

---

## 🚦 الخطوات التالية

1. إضافة واجهة UI لعرض الكروت المخزنة
2. تطوير نظام البحث المتقدم
3. إضافة تقارير تفصيلية
4. تطوير نظام الإشعارات للكروت المنتهية
5. إضافة نظام الباركود/QR Code

---

## 📞 ملاحظات

- يتم توليد PIN تلقائياً لكل كرت (يمكن تخصيصه)
- تاريخ الانتهاء افتراضياً سنة واحدة (يمكن ربطه بالباقة)
- السعر حالياً 0.0 (يمكن ربطه بسعر الباقة)
- يتم حفظ الكروت محلياً و في Firebase معاً

---

تم إنشاء هذا التوثيق في: 2025-01-XX
آخر تحديث: 2025-01-XX

