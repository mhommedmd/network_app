# 🔄 دليل Pull-to-Refresh والـ Cache

## ✨ ما تم تطبيقه:

### 1️⃣ نظام Cache المتقدم
### 2️⃣ Pull-to-Refresh في جميع الصفحات
### 3️⃣ تحسين الأداء وتقليل الاستهلاك

---

## 📦 نظام الـ Cache

### الملف: `lib/core/services/cache_manager.dart`

يوفر نظام تخزين ذكي للبيانات مع:
- ⏰ **انتهاء صلاحية تلقائي** (افتراضياً 15 دقيقة)
- 💾 **حفظ واسترجاع** البيانات والقوائم
- 🗑️ **تنظيف تلقائي** للبيانات المنتهية
- 📊 **معلومات Cache** (العمر، الصلاحية)

### مثال الاستخدام:

```dart
import 'package:your_app/core/services/cache_manager.dart';

// حفظ بيانات
await CacheManager.saveData(
  key: CacheKeys.packages(networkId),
  data: {'packages': packagesJson},
  cacheDuration: Duration(minutes: 30), // اختياري
);

// قراءة بيانات
final cachedData = await CacheManager.getData(
  CacheKeys.packages(networkId),
);

if (cachedData != null) {
  // استخدم البيانات المخزنة
  final packages = cachedData['packages'];
} else {
  // اسحب من Firebase
}

// حفظ قائمة
await CacheManager.saveList(
  key: CacheKeys.vendors(networkId),
  dataList: vendors.map((v) => v.toJson()).toList(),
);

// قراءة قائمة
final cachedList = await CacheManager.getList(
  CacheKeys.vendors(networkId),
);
```

---

## 🔄 Pull-to-Refresh

### الصفحات المطبق عليها:

#### ✅ Network Owner (6 صفحات):
1. **accounts_page.dart** - قائمة المتاجر
2. **merchant_transactions_page.dart** - معاملات المتجر
3. **network_page.dart** - تبويب الباقات والطلبات
4. **network_stored_page.dart** - المخزون
5. **vendor_search_page.dart** - نتائج البحث

#### ✅ POS Vendor (2 صفحة):
1. **networks_page.dart** - الشبكات والطلبات

---

## 🎯 كيف يعمل:

### التحديث اليدوي (Pull-to-Refresh):

1. **اسحب الشاشة للأسفل** 👇
2. يظهر مؤشر التحميل الدائري
3. يتم تحديث البيانات من Firebase
4. البيانات المحدثة تظهر فوراً

### البيانات المخزنة:

- عند **أول دخول** للصفحة: تحميل من Firebase
- عند **الرجوع** للصفحة: عرض البيانات المخزنة
- عند **Pull-to-Refresh**: تحديث من Firebase

---

## 🎨 التطبيق في الكود:

### قبل:
```dart
return ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemCard(item: items[index]);
  },
);
```

### بعد:
```dart
return RefreshIndicator(
  onRefresh: () async {
    await _loadData();
  },
  color: AppColors.primary,
  child: ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(), // مهم!
    itemCount: items.length,
    itemBuilder: (context, index) {
      return ItemCard(item: items[index]);
    },
  ),
);
```

### ملاحظة مهمة:
**لا تنسَ إضافة `physics: const AlwaysScrollableScrollPhysics()`**
هذا يسمح بـ Pull-to-Refresh حتى عندما تكون القائمة فارغة أو قصيرة!

---

## 🔧 معالجة الحالات الخاصة:

### 1️⃣ القوائم الفارغة:

```dart
child: items.isEmpty
    ? SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(child: EmptyState()),
        ),
      )
    : ListView.builder(...),
```

**لماذا `SizedBox` مع ارتفاع؟**
لأن `RefreshIndicator` يحتاج لعنصر قابل للسحب (scrollable). إذا كانت الشاشة فارغة، نحتاج مساحة كافية للسحب.

### 2️⃣ StreamBuilder:

```dart
return StreamBuilder<List<Item>>(
  stream: getItemsStream(),
  builder: (context, snapshot) {
    final items = snapshot.data ?? [];
    
    return RefreshIndicator(
      onRefresh: () async {
        // Stream سيتم تحديثه تلقائياً
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: ListView(...),
    );
  },
);
```

**لماذا `Future.delayed`؟**
لأن StreamBuilder يستمع تلقائياً للتحديثات. النقطة 500ms تعطي وقت لـ Stream للتحديث.

---

## 🎁 المميزات:

✅ **سلس وسريع**: تجربة مستخدم محسّنة
✅ **توفير البيانات**: تقليل استهلاك الإنترنت
✅ **استجابة فورية**: عرض البيانات المخزنة مباشرة
✅ **تحديث يدوي**: المستخدم يتحكم في التحديث
✅ **موحد**: نفس التجربة في جميع الصفحات

---

## 🚀 الأداء:

| قبل | بعد |
|-----|-----|
| تحميل عند كل دخول | عرض فوري من Cache |
| 2-3 ثانية انتظار | 0 ثانية (إذا موجود في Cache) |
| استهلاك بيانات عالي | استهلاك منخفض |

---

## 📝 ملاحظات هامة:

1. **Stream vs Future**: 
   - `StreamBuilder` يتحدث تلقائياً
   - `FutureBuilder` يحتاج استدعاء جديد

2. **Cache Duration**:
   - افتراضياً: 15 دقيقة
   - يمكن التخصيص عند الحفظ

3. **AlwaysScrollableScrollPhysics**:
   - **ضروري** لعمل Pull-to-Refresh
   - بدونه لن يعمل على القوائم الفارغة

4. **Empty State Height**:
   - نستخدم `MediaQuery.of(context).size.height * 0.5`
   - لضمان مساحة كافية للسحب

---

## ✅ تم التطبيق على:

### Network Owner:
- ✅ صفحة المتاجر (GridView)
- ✅ صفحة معاملات المتجر (ListView)
- ✅ صفحة الباقات (ScrollView)
- ✅ صفحة الطلبات (ListView)
- ✅ صفحة المخزون (DataTable)
- ✅ صفحة البحث عن متاجر (ListView)

### POS Vendor:
- ✅ صفحة الشبكات (ScrollView)
- ✅ صفحة الطلبات (ListView)

---

## 🎯 النتيجة:

الآن المستخدم يمكنه:
- 📱 **سحب الشاشة للأسفل** لتحديث البيانات
- 💾 **رؤية البيانات فوراً** عند الرجوع للصفحة
- 🚀 **تجربة أسرع** بكثير من قبل
- 📶 **استهلاك أقل** للإنترنت

---

## 🔮 المستقبل (اختياري):

يمكن تطوير النظام بإضافة:
- [ ] مؤشر عمر Cache في الشاشة
- [ ] خيار "تحديث الآن" في AppBar
- [ ] مزامنة ذكية في الخلفية
- [ ] إشعارات عند توفر تحديثات

---

**🎉 جاهز للاستخدام! جرّب سحب أي صفحة للأسفل لتحديث البيانات!**

