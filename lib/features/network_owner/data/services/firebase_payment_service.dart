import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_request_model.dart';

/// خدمة Firebase لإدارة الدفعات النقدية
class FirebasePaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'payment_requests';

  /// إرسال طلب دفعة نقدية
  static Future<String> sendPaymentRequest({
    required String vendorId,
    required String networkId,
    required double amount,
    required String description,
    String? notes,
  }) async {
    try {
      final paymentRequest = PaymentRequestModel(
        id: '',
        vendorId: vendorId,
        networkId: networkId,
        amount: amount,
        description: description,
        status: PaymentRequestStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
      );

      final docRef =
          await _firestore.collection(_collection).add(paymentRequest.toJson());

      print('✅ تم إرسال طلب الدفعة: ${docRef.id}');

      // إنشاء معاملة بحالة pending
      await _createPendingTransaction(
        paymentRequestId: docRef.id,
        vendorId: vendorId,
        networkId: networkId,
        amount: amount,
        description: description,
      );

      // إرسال إشعار للمتجر
      await _sendNotificationToVendor(
        vendorId: vendorId,
        networkId: networkId,
        amount: amount,
        paymentRequestId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إرسال طلب الدفعة: $e');
    }
  }

  /// إنشاء معاملة معلقة
  static Future<void> _createPendingTransaction({
    required String paymentRequestId,
    required String vendorId,
    required String networkId,
    required double amount,
    required String description,
  }) async {
    try {
      final now = DateTime.now();
      final transactionData = {
        'vendorId': vendorId,
        'networkId': networkId,
        'type': 'payment',
        'amount': amount,
        'description': description,
        'reference': 'PAY-${paymentRequestId.substring(0, 8).toUpperCase()}',
        'status': 'pending',
        'balanceAfter': 0.0,
        'createdBy': networkId,
        'method': 'cash',
        'paymentRequestId': paymentRequestId,
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('transactions').add(transactionData);
      print(
          '✅ Pending transaction created for payment request: $paymentRequestId');
      print(
          '   - reference: PAY-${paymentRequestId.substring(0, 8).toUpperCase()}');
    } catch (e) {
      print('❌ فشل إنشاء المعاملة: $e');
    }
  }

  /// إرسال إشعار للمتجر
  static Future<void> _sendNotificationToVendor({
    required String vendorId,
    required String networkId,
    required double amount,
    required String paymentRequestId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': vendorId,
        'senderId': networkId,
        'type': 'payment_request',
        'title': 'طلب موافقة على دفعة نقدية',
        'body':
            'تم إرسال طلب لتأكيد استلام دفعة نقدية بقيمة ${amount.toStringAsFixed(0)} ر.ي',
        'data': {
          'paymentRequestId': paymentRequestId,
          'amount': amount,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ تم إرسال إشعار للمتجر');
    } catch (e) {
      print('❌ فشل إرسال الإشعار: $e');
    }
  }

  /// الحصول على طلبات الدفع لشبكة معينة
  static Stream<List<PaymentRequestModel>> getPaymentRequests(
      String networkId) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRequestModel.fromFirestore(doc))
            .toList());
  }

  /// الموافقة على طلب الدفعة (تحديث المعاملة)
  static Future<void> approvePaymentRequest({
    required String paymentRequestId,
    required String vendorId,
    required String networkId,
  }) async {
    try {
      // 1. تحديث حالة طلب الدفعة
      await _firestore.collection(_collection).doc(paymentRequestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 2. تحديث المعاملة المعلقة إلى completed
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('paymentRequestId', isEqualTo: paymentRequestId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (transactionsSnapshot.docs.isNotEmpty) {
        final transactionDoc = transactionsSnapshot.docs.first;
        await transactionDoc.reference.update({
          'status': 'completed',
        });
        print('✅ Payment transaction approved: ${transactionDoc.id}');
      } else {
        print(
            '⚠️ No pending transaction found for payment request: $paymentRequestId');
      }
    } catch (e) {
      print('❌ Error approving payment: $e');
      throw Exception('فشل في الموافقة على الدفعة: $e');
    }
  }

  /// رفض طلب الدفعة (حذف المعاملة المعلقة)
  static Future<void> rejectPaymentRequest({
    required String paymentRequestId,
    required String vendorId,
    required String networkId,
  }) async {
    try {
      // 1. تحديث حالة طلب الدفعة
      await _firestore.collection(_collection).doc(paymentRequestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // 2. حذف المعاملة المعلقة
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('paymentRequestId', isEqualTo: paymentRequestId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (transactionsSnapshot.docs.isNotEmpty) {
        final transactionDoc = transactionsSnapshot.docs.first;
        await transactionDoc.reference.delete();
        print('✅ Pending payment transaction deleted: ${transactionDoc.id}');
      }
    } catch (e) {
      print('❌ Error rejecting payment: $e');
      throw Exception('فشل في رفض الدفعة: $e');
    }
  }
}
