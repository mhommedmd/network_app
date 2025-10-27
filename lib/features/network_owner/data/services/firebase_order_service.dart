import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

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
      final docRef =
          await _firestore.collection(_ordersCollection).add(order.toJson());
      return docRef.id;
    } catch (e) {
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
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
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
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
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
            final vendorCardRef =
                _firestore.collection(_vendorCardsCollection).doc();

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

      // 4. إنشاء معاملة في transactions (خارج runTransaction)
      final now = DateTime.now();
      final transactionData = {
        'vendorId': order.vendorId,
        'networkId': order.networkId,
        'type': 'charge', // شحن - إضافة رصيد على المتجر
        'amount': order.totalAmount,
        'description':
            'طلب كروت - ${order.items.length} باقة - ${order.totalCards} كرت',
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

      print('✅ Transaction recorded for order: ${order.id}');
      print('   - vendorId: ${order.vendorId}');
      print('   - networkId: ${order.networkId}');
      print('   - type: charge');
      print('   - amount: ${order.totalAmount}');
      print('   - reference: ORD-${order.id.substring(0, 8).toUpperCase()}');
      print('   - orderId: ${order.id}');
    } catch (e) {
      print('❌ Error approving order: $e');
      throw Exception('فشل في الموافقة على الطلب: $e');
    }
  }

  /// رفض الطلب
  static Future<void> rejectOrder(String orderId, {String? notes}) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } catch (e) {
      throw Exception('فشل في رفض الطلب: $e');
    }
  }

  /// حساب إجمالي الطلبات حسب الحالة
  static Future<Map<String, int>> getOrdersCountByStatus(
      String networkId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('networkId', isEqualTo: networkId)
          .get();

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
    } catch (e) {
      return {'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  /// التحقق من توفر الكمية المطلوبة (للشبكة فقط عند الموافقة)
  static Future<Map<String, int>> checkOrderStockAvailability(
      OrderModel order) async {
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
    } catch (e) {
      return {};
    }
  }
}
