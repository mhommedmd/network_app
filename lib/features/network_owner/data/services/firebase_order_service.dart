import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';
import 'firebase_notification_service.dart';

/// خدمة Firebase لإدارة الطلبات
class FirebaseOrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';
  static const String _cardsCollection = 'cards';
  static const String _vendorCardsCollection = 'vendor_cards';
  static const String _transactionsCollection = 'transactions';

  /// إنشاء طلب جديد
  static Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore.collection(_ordersCollection).add(order.toJson());

      // إرسال إشعار لمالك الشبكة
      try {
        await FirebaseNotificationService.notifyNewOrder(
          networkId: order.networkId,
          vendorName: order.vendorName,
          orderId: docRef.id,
        );
      } on Exception {
        // تجاهل خطأ الإشعار ولا تفشل العملية
      }

      return docRef.id;
    } on Exception catch (e) {
      throw Exception('فشل في إنشاء الطلب: $e');
    }
  }

  /// الحصول على طلبات الشبكة
  static Stream<List<OrderModel>> getNetworkOrders(String networkId) {
    return _firestore
        .collection(_ordersCollection)
        .where('networkId', isEqualTo: networkId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(OrderModel.fromFirestore).toList();
    });
  }

  /// الحصول على طلبات المتجر
  static Stream<List<OrderModel>> getVendorOrders(String vendorId) {
    return _firestore
        .collection(_ordersCollection)
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(OrderModel.fromFirestore).toList();
    });
  }

  /// الموافقة على الطلب ونقل الكروت
  static Future<void> approveOrder(OrderModel order) async {
    try {
      // بدء معاملة لضمان تنفيذ جميع العمليات معاً
      await _firestore.runTransaction((transaction) async {
        // معالجة كل باقة في الطلب
        for (final item in order.items) {
          // 1. الحصول على الكروت المتاحة من مخزون الشبكة
          final cardsQuery = await _firestore
              .collection(_cardsCollection)
              .where('networkId', isEqualTo: order.networkId)
              .where('packageId', isEqualTo: item.packageId)
              .where('status', isEqualTo: 'available')
              .limit(item.quantity)
              .get();

          // التحقق من توفر الكمية المطلوبة
          if (cardsQuery.docs.length < item.quantity) {
            throw Exception(
              'المخزون غير كافٍ للباقة "${item.packageName}". '
              'متوفر: ${cardsQuery.docs.length}، مطلوب: ${item.quantity}',
            );
          }

          // 2. نقل الكروت إلى مخزون المتجر
          for (final cardDoc in cardsQuery.docs) {
            final cardData = cardDoc.data();

            // إنشاء كرت في مخزون المتجر
            final vendorCardRef = _firestore.collection(_vendorCardsCollection).doc();

            transaction.set(vendorCardRef, {
              'vendorId': order.vendorId,
              'vendorName': order.vendorName,
              'networkId': order.networkId,
              'networkName': order.networkName,
              'packageId': item.packageId,
              'packageName': item.packageName,
              'cardNumber': cardData['cardNumber'],
              'status': 'available',
              'price': item.pricePerCard,
              'orderId': order.id,
              'importedAt': FieldValue.serverTimestamp(),
              'transferredAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });

            // تحديث حالة الكرت في مخزون الشبكة
            transaction.update(cardDoc.reference, {
              'status': 'transferred',
              'transferredTo': order.vendorId,
              'transferredAt': FieldValue.serverTimestamp(),
              'orderId': order.id,
            });
          }
        }

        // 3. تحديث حالة الطلب
        final orderRef = _firestore.collection(_ordersCollection).doc(order.id);

        transaction.update(orderRef, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      });

      // 4. إنشاء معاملات في transactions و vendor_transactions (خارج runTransaction)
      final now = DateTime.now();

      // معاملة الشبكة
      final transactionData = {
        'vendorId': order.vendorId,
        'vendorName': order.vendorName, // ✅ إضافة vendorName
        'networkId': order.networkId,
        'type': 'charge', // شحن - إضافة رصيد على المتجر
        'amount': order.totalAmount,
        'description': 'طلب كروت - ${order.items.length} باقة - ${order.totalCards} كرت',
        'reference': 'ORD-${order.id.substring(0, 8).toUpperCase()}',
        'status': 'completed',
        'balanceAfter': 0.0, // سيتم تحديثه لاحقاً عند الحاجة
        'createdBy': order.networkId,
        'method': 'order',
        'orderId': order.id,
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore.collection(_transactionsCollection).add(transactionData);

      // معاملة المتجر (✅ إضافة جديدة)
      final vendorTransactionData = {
        'vendorId': order.vendorId,
        'networkId': order.networkId,
        'networkName': order.networkName,
        'type': 'charge',
        'amount': order.totalAmount, // موجب (المتجر يدين)
        'description': 'طلب كروت - ${order.items.length} باقة - ${order.totalCards} كرت',
        'status': 'completed',
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'orderId': order.id,
      };

      await _firestore.collection('vendor_transactions').add(vendorTransactionData);

      // إرسال إشعار للمتجر بالموافقة
      try {
        await FirebaseNotificationService.notifyOrderApproved(
          vendorId: order.vendorId,
          networkName: order.networkName,
          orderId: order.id,
          cardsCount: order.totalCards,
        );
      } on Exception {
        // تجاهل خطأ الإشعار
      }
    } on Exception catch (e) {
      throw Exception('فشل في الموافقة على الطلب: $e');
    }
  }

  /// رفض الطلب
  static Future<void> rejectOrder(String orderId, {String? notes}) async {
    try {
      // الحصول على بيانات الطلب أولاً
      final orderDoc = await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('الطلب غير موجود');
      }

      final order = OrderModel.fromFirestore(orderDoc);

      // تحديث حالة الطلب
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      // إرسال إشعار للمتجر بالرفض
      try {
        await FirebaseNotificationService.notifyOrderRejected(
          vendorId: order.vendorId,
          networkName: order.networkName,
          orderId: orderId,
        );
      } on Exception {
        // تجاهل خطأ الإشعار
      }
    } on Exception catch (e) {
      throw Exception('فشل في رفض الطلب: $e');
    }
  }

  /// حساب إجمالي الطلبات حسب الحالة
  static Future<Map<String, int>> getOrdersCountByStatus(
    String networkId,
  ) async {
    try {
      final snapshot = await _firestore.collection(_ordersCollection).where('networkId', isEqualTo: networkId).get();

      final counts = <String, int>{
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } on Exception {
      return {'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  /// التحقق من توفر الكمية المطلوبة (للشبكة فقط عند الموافقة)
  static Future<Map<String, int>> checkOrderStockAvailability(
    OrderModel order,
  ) async {
    try {
      final availability = <String, int>{};

      for (final item in order.items) {
        final snapshot = await _firestore
            .collection(_cardsCollection)
            .where('networkId', isEqualTo: order.networkId)
            .where('packageId', isEqualTo: item.packageId)
            .where('status', isEqualTo: 'available')
            .get();

        availability[item.packageId] = snapshot.docs.length;
      }

      return availability;
    } on Exception {
      return {};
    }
  }

  /// حذف طلب (فقط للطلبات المعالجة - approved أو rejected)
  static Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).delete();
    } on Exception catch (e) {
      throw Exception('فشل في حذف الطلب: $e');
    }
  }
}
