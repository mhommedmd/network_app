import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cash_payment_request_model.dart';
import 'firebase_notification_service.dart';

/// خدمة Firebase لإدارة طلبات الدفعات النقدية
class FirebaseCashPaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _paymentsCollection = 'cash_payment_requests';
  static const String _transactionsCollection = 'transactions';

  /// إنشاء طلب دفعة نقدية جديد
  static Future<String> createPaymentRequest(
    CashPaymentRequestModel request,
  ) async {
    try {
      final docRef = await _firestore.collection(_paymentsCollection).add(request.toJson());

      // إرسال إشعار للمتجر
      try {
        await FirebaseNotificationService.notifyNewPayment(
          vendorId: request.vendorId,
          networkName: request.networkName,
          amount: request.amount,
          paymentId: docRef.id,
        );
      } on Exception {
        // تجاهل خطأ الإشعار
      }

      return docRef.id;
    } on Exception catch (e) {
      throw Exception('فشل في إنشاء طلب الدفعة: $e');
    }
  }

  /// الحصول على طلبات الدفع للمتجر
  static Stream<List<CashPaymentRequestModel>> getVendorPaymentRequests(
    String vendorId,
  ) {
    return _firestore
        .collection(_paymentsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map(CashPaymentRequestModel.fromFirestore).toList();
      // ترتيب حسب التاريخ (الأحدث أولاً) في التطبيق
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  /// الحصول على طلبات الدفع للشبكة
  static Stream<List<CashPaymentRequestModel>> getNetworkPaymentRequests(
    String networkId,
  ) {
    return _firestore
        .collection(_paymentsCollection)
        .where('networkId', isEqualTo: networkId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map(CashPaymentRequestModel.fromFirestore).toList();
      // ترتيب حسب التاريخ (الأحدث أولاً) في التطبيق
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  /// الموافقة على طلب الدفعة وتسجيل المعاملة
  static Future<void> approvePaymentRequest(
    String requestId,
    String vendorId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. الحصول على بيانات الطلب
        final requestDoc = await transaction.get(_firestore.collection(_paymentsCollection).doc(requestId));

        if (!requestDoc.exists) {
          throw Exception('الطلب غير موجود');
        }

        final requestData = requestDoc.data()!;
        final amount = (requestData['amount'] as num).toDouble();
        final networkId = requestData['networkId'] as String;
        final vendorName = requestData['vendorName'] as String;
        final networkName = requestData['networkName'] as String;

        // 2. تحديث حالة الطلب
        transaction.update(requestDoc.reference, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'processedBy': vendorId,
        });

        // 3. تسجيل معاملة الدفع (من جانب الشبكة)
        final now = DateTime.now();
        final networkTransactionRef = _firestore.collection(_transactionsCollection).doc();
        transaction.set(networkTransactionRef, {
          'networkId': networkId,
          'vendorId': vendorId,
          'vendorName': vendorName,
          'type': 'payment',
          'amount': -amount, // سالب لأنه يخفض دين المتجر
          'description': 'دفعة نقدية من $vendorName',
          'reference': 'PAY-${requestId.substring(0, 8).toUpperCase()}',
          'status': 'completed',
          'date': Timestamp.fromDate(now),
          'createdAt': Timestamp.fromDate(now),
          'createdBy': networkId,
          'method': 'cash',
          'balanceAfter': 0.0, // سيتم تحديثه إذا لزم الأمر
          'paymentRequestId': requestId,
        });

        // 4. تسجيل معاملة الدفع (من جانب المتجر)
        final vendorTransactionRef = _firestore.collection('vendor_transactions').doc();
        transaction.set(vendorTransactionRef, {
          'vendorId': vendorId,
          'networkId': networkId,
          'networkName': networkName,
          'type': 'cash_payment_sent',
          'amount': -amount, // سالب لأنه دفع من المتجر
          'description': 'دفعة نقدية إلى $networkName',
          'status': 'completed',
          'date': Timestamp.fromDate(now), // ✅ إضافة date
          'createdAt': Timestamp.fromDate(now),
          'paymentRequestId': requestId,
        });

        // 5. تحديث رصيد المتجر في network_connections
        final connectionQuery = await _firestore
            .collection('network_connections')
            .where('networkId', isEqualTo: networkId)
            .where('vendorId', isEqualTo: vendorId)
            .limit(1)
            .get();

        if (connectionQuery.docs.isNotEmpty) {
          final connectionDoc = connectionQuery.docs.first;
          final currentBalance = (connectionDoc.data()['balance'] as num?)?.toDouble() ?? 0.0;
          final newBalance = currentBalance - amount; // ✅ طرح الدفعة من الدين (المتجر يسدد)

          transaction.update(connectionDoc.reference, {
            'balance': newBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✅ Cash payment transaction recorded:');
      print('   - paymentRequestId: $requestId');
      print('   - vendorId: $vendorId');
      print('   - type: cash_payment_received');
      print(
          '   - amount: ${(await _firestore.collection(_paymentsCollection).doc(requestId).get()).data()?['amount']}',);

      // إرسال إشعار لمالك الشبكة بالموافقة
      try {
        final requestDoc = await _firestore.collection(_paymentsCollection).doc(requestId).get();
        if (requestDoc.exists) {
          final requestData = requestDoc.data()!;
          await FirebaseNotificationService.notifyPaymentApproved(
            networkId: requestData['networkId'] as String,
            vendorName: requestData['vendorName'] as String,
            amount: (requestData['amount'] as num).toDouble(),
            paymentId: requestId,
          );
        }
      } on Exception {
        // تجاهل خطأ الإشعار
      }
    } on Exception catch (e) {
      throw Exception('فشل في الموافقة على الدفعة: $e');
    }
  }

  /// رفض طلب الدفعة
  static Future<void> rejectPaymentRequest(
    String requestId,
    String vendorId,
  ) async {
    try {
      // الحصول على بيانات الطلب أولاً
      final requestDoc = await _firestore.collection(_paymentsCollection).doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('طلب الدفعة غير موجود');
      }

      final requestData = requestDoc.data()!;

      // تحديث حالة الطلب
      await _firestore.collection(_paymentsCollection).doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'processedBy': vendorId,
      });

      // إرسال إشعار لمالك الشبكة بالرفض
      try {
        await FirebaseNotificationService.notifyPaymentRejected(
          networkId: requestData['networkId'] as String,
          vendorName: requestData['vendorName'] as String,
          amount: (requestData['amount'] as num).toDouble(),
          paymentId: requestId,
        );
      } on Exception {
        // تجاهل خطأ الإشعار
      }
    } on Exception catch (e) {
      throw Exception('فشل في رفض الدفعة: $e');
    }
  }

  /// الحصول على عدد الطلبات المعلقة للمتجر
  static Stream<int> getPendingPaymentsCount(String vendorId) {
    return _firestore
        .collection(_paymentsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// حذف طلب دفعة
  static Future<void> deletePaymentRequest(String requestId) async {
    try {
      await _firestore.collection(_paymentsCollection).doc(requestId).delete();
    } on Exception catch (e) {
      throw Exception('فشل في حذف طلب الدفعة: $e');
    }
  }
}
