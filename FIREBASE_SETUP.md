# 🔥 إعداد Firebase لحل مشكلة الصلاحيات

## ⚠️ المشكلة

```
Exception: [cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation
```

هذا يعني أن **قواعد Firestore** لا تسمح بالكتابة في قاعدة البيانات.

---

## ✅ الحل السريع (للتطوير فقط)

### الطريقة 1️⃣: عبر Firebase Console

1. **افتح Firebase Console:**
   - اذهب إلى: https://console.firebase.google.com
   - اختر مشروعك: `fir-networkapp`

2. **اذهب إلى Firestore Database:**
   ```
   Firebase Console → Firestore Database → Rules
   ```

3. **استبدل القواعد الحالية بهذه القواعد المؤقتة:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // للتطوير فقط - يسمح بالقراءة والكتابة لأي مستخدم مسجل
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

4. **اضغط "Publish" (نشر)**

5. **جرّب التطبيق الآن** - المشكلة ستحل! ✅

---

## 🔒 الحل الإنتاجي (موصى به)

بعد انتهاء التطوير، استخدم القواعد الآمنة من ملف `firestore.rules`:

### كيفية التطبيق:

#### الطريقة الأولى: عبر Firebase Console
انسخ محتوى ملف `firestore.rules` والصقه في Firebase Console → Firestore Database → Rules

#### الطريقة الثانية: عبر Firebase CLI
```bash
# تثبيت Firebase CLI (إذا لم يكن مثبتاً)
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# تهيئة المشروع
firebase init firestore

# نشر القواعد
firebase deploy --only firestore:rules
```

---

## 📋 شرح القواعد الإنتاجية

### 1. الباقات (packages)
```javascript
match /packages/{packageId} {
  // أي شخص مسجل دخول يمكنه القراءة
  allow read: if isAuthenticated();
  
  // فقط مالك الشبكة يمكنه الإضافة
  allow create: if isAuthenticated() && 
                   request.resource.data.createdBy == request.auth.uid &&
                   request.resource.data.networkId == request.auth.uid;
  
  // فقط مالك الشبكة يمكنه التعديل والحذف
  allow update, delete: if isAuthenticated() && 
                           resource.data.networkId == request.auth.uid;
}
```

### 2. الكروت (cards)
```javascript
match /cards/{cardId} {
  // القراءة: مالك الشبكة أو من اشترى الكرت
  allow read: if isAuthenticated() && 
                (resource.data.networkId == request.auth.uid || 
                 resource.data.soldTo == request.auth.uid);
  
  // الكتابة: مالك الشبكة فقط
  allow create, update, delete: if isAuthenticated() && 
                                   request.auth.uid == request.resource.data.networkId;
}
```

---

## 🎯 الخطوات الموصى بها

### للتطوير (الآن):
1. ✅ استخدم القواعد المؤقتة (من الطريقة 1 أعلاه)
2. ✅ اختبر جميع الميزات
3. ✅ تأكد من أن كل شيء يعمل

### للإنتاج (لاحقاً):
1. 🔒 طبّق القواعد الآمنة من `firestore.rules`
2. 🔒 اختبر جميع الحالات
3. 🔒 تأكد من عدم وجود ثغرات أمنية

---

## 🔍 التحقق من نجاح التطبيق

بعد تطبيق القواعد، جرّب:

```
1. تسجيل الدخول كمالك شبكة
2. إضافة باقة جديدة
   ✅ يجب أن تنجح بدون أخطاء
3. استيراد كروت
   ✅ يجب أن تُحفظ في Firebase
4. عرض المخزون
   ✅ يجب أن تظهر البيانات
```

---

## 🚨 ملاحظات هامة

### ⚠️ القواعد المؤقتة (للتطوير)
```javascript
// هذه القواعد تسمح بالقراءة والكتابة لأي شخص مسجل دخول
// مناسبة للتطوير فقط!
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

**المخاطر:**
- ❌ أي مستخدم يمكنه حذف أو تعديل بيانات أي مستخدم آخر
- ❌ غير آمنة للإنتاج
- ✅ مناسبة فقط للتطوير والاختبار

### 🔒 القواعد الإنتاجية (الآمنة)
```javascript
// كل مستخدم يمكنه فقط التعامل مع بياناته الخاصة
// التحقق من networkId و createdBy
```

**الفوائد:**
- ✅ كل مستخدم يصل فقط لبياناته
- ✅ أمان محكم ضد الاختراق
- ✅ التحقق من الصلاحيات في كل عملية

---

## 📱 الحل الفوري (3 دقائق)

### الخطوات:

1. **افتح Firebase Console:**
   ```
   https://console.firebase.google.com/project/fir-networkapp
   ```

2. **اذهب إلى Firestore:**
   ```
   القائمة الجانبية → Firestore Database → Rules
   ```

3. **استبدل القواعد بهذه:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

4. **اضغط "Publish"**

5. **جرّب التطبيق مباشرة!** ✅

---

## 🔧 إذا استمرت المشكلة

### تحقق من:

1. **هل المستخدم مسجل دخول؟**
   ```dart
   // في الكود، تأكد من:
   final currentUser = authProvider.user;
   if (currentUser == null) {
     // لم يسجل دخول
   }
   ```

2. **هل Firebase Auth يعمل؟**
   ```dart
   final firebaseUser = FirebaseAuth.instance.currentUser;
   print('Firebase User: ${firebaseUser?.uid}');
   ```

3. **هل المشروع صحيح؟**
   ```
   تأكد من أن projectId في firebase.json = fir-networkapp
   ```

---

## 🎯 التطبيق السريع عبر Terminal

إذا كان لديك Firebase CLI:

```bash
# 1. تسجيل الدخول
firebase login

# 2. اختيار المشروع
firebase use fir-networkapp

# 3. نشر القواعد المؤقتة
firebase deploy --only firestore:rules
```

---

**بعد تطبيق القواعد المؤقتة، جرّب إضافة باقة الآن - ستعمل مباشرة!** 🚀✅

هل تريد مني المساعدة في أي شيء آخر؟
