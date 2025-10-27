# 📋 نشر فهارس Firestore

## 🎯 الهدف
إنشاء الفهارس المطلوبة في Firestore لتشغيل الاستعلامات بكفاءة.

---

## 🚀 الطريقة 1: استخدام Firebase CLI (الأسرع)

### الخطوات:

```bash
# 1. تثبيت Firebase CLI (إذا لم يكن مثبتاً)
npm install -g firebase-tools

# 2. تسجيل الدخول
firebase login

# 3. تهيئة المشروع (اختياري إذا لم يكن مُهيّأ)
firebase init firestore

# 4. نشر الفهارس
firebase deploy --only firestore:indexes
```

### النتيجة المتوقعة:
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/fir-networkapp/overview
```

⏱️ **الانتظار:** قد يستغرق بناء الفهارس من 2-5 دقائق

---

## 📱 الطريقة 2: عبر Firebase Console (يدوياً)

إذا لم تكن تريد استخدام CLI، يمكنك إنشاء الفهارس يدوياً:

### 1️⃣ افتح Firebase Console:
```
https://console.firebase.google.com/project/fir-networkapp/firestore/indexes
```

### 2️⃣ أنشئ الفهارس التالية:

#### فهرس 1: للباقات (عرض)
```
Collection: packages
Fields:
  - networkId (Ascending)
  - isActive (Ascending)
  - createdAt (Descending)
```

#### فهرس 2: للباقات (بحث)
```
Collection: packages
Fields:
  - networkId (Ascending)
  - isActive (Ascending)
  - name (Ascending)
```

#### فهرس 3: للكروت (عرض)
```
Collection: cards
Fields:
  - networkId (Ascending)
  - createdAt (Descending)
```

#### فهرس 4: للكروت (حسب الحالة)
```
Collection: cards
Fields:
  - networkId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```

#### فهرس 5: للكروت (حسب الباقة)
```
Collection: cards
Fields:
  - networkId (Ascending)
  - packageId (Ascending)
  - createdAt (Descending)
```

#### فهرس 6: للكروت (بحث)
```
Collection: cards
Fields:
  - networkId (Ascending)
  - cardNumber (Ascending)
```

---

## 🎬 الطريقة 3: عبر الرابط التلقائي (الأسهل!)

### عند ظهور خطأ الفهرس:

1. **انسخ الرابط** من رسالة الخطأ:
   ```
   You can create it here: https://console.firebase.google.com/v1/r/project/...
   ```

2. **افتح الرابط** في المتصفح

3. **اضغط "Create Index"** أو **"إنشاء فهرس"**

4. **انتظر** حتى يظهر:
   ```
   Status: Building... → Enabled ✅
   ```

5. **كرر** لكل رسالة خطأ تظهر

---

## 🔍 التحقق من الفهارس

### في Firebase Console:
```
Firestore Database → Indexes (الفهارس)
```

يجب أن ترى:
```
✅ packages (networkId, isActive, createdAt) - Enabled
✅ cards (networkId, createdAt) - Enabled
✅ cards (networkId, status, createdAt) - Enabled
✅ cards (networkId, packageId, createdAt) - Enabled
✅ cards (networkId, cardNumber) - Enabled
```

---

## ⚡ الحل الأسرع الآن

### افتح Terminal وشغّل:

```bash
cd d:\myprojacet\network_app

# نشر الفهارس
firebase deploy --only firestore:indexes

# انتظر حتى تكتمل (2-5 دقائق)
```

### أو استخدم الروابط التلقائية:

1. شغّل التطبيق
2. عند ظهور خطأ الفهرس، افتح الرابط
3. اضغط "Create Index"
4. كرر لكل خطأ

---

## 📊 حالة الفهارس

### Building (قيد البناء):
```
⏳ انتظر 2-5 دقائق
```

### Enabled (جاهز):
```
✅ يمكنك استخدام التطبيق الآن
```

### Error (خطأ):
```
🔴 تحقق من القواعد والصلاحيات
```

---

## 🎯 بعد نشر الفهارس

1. ✅ أعد تشغيل التطبيق
2. ✅ افتح صفحة الباقات
3. ✅ يجب أن تعمل بدون أخطاء!
4. ✅ استورد كروت
5. ✅ اعرض المخزون

كل شيء سيعمل بسرعة وكفاءة عالية! 🚀

---

## 💡 نصيحة

للتطوير السريع، يمكنك:
1. إنشاء الفهارس عبر الروابط التلقائية
2. بعد الانتهاء، نشر الفهارس عبر CLI

---

**جاهز للنشر!** 📦✨

