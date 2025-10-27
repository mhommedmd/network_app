import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

/// خدمة Firebase لإدارة المعاملات المالية
class FirebaseTransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  /// إضافة معاملة جديدة
  static Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(transaction.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة المعاملة: $e');
    }
  }

  /// الحصول على معاملات متجر معين
  static Stream<List<TransactionModel>> getTransactionsByVendor({
    required String vendorId,
    required String networkId,
  }) {
    print('🔍 Fetching transactions for:');
    print('   - vendorId: $vendorId');
    print('   - networkId: $networkId');

    return _firestore
        .collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .where('networkId', isEqualTo: networkId)
        .where('status', isEqualTo: 'completed')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📥 Transactions received: ${snapshot.docs.length}');

      final transactions = snapshot.docs.map((doc) {
        print('   - ${doc.id}: ${doc.data()['description']}');
        return TransactionModel.fromFirestore(doc);
      }).toList();

      return transactions;
    });
  }

  /// حساب ملخص الحساب
  static Future<Map<String, dynamic>> getAccountSummary({
    required String vendorId,
    required String networkId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalCharges = 0;
      double totalPayments = 0;
      int totalTransactions = snapshot.docs.length;
      DateTime? lastTransactionDate;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = data['type'] as String?;
        final date = (data['date'] as Timestamp?)?.toDate();

        if (type == 'charge' || type == 'fee') {
          totalCharges += amount.abs();
        } else if (type == 'payment' || type == 'refund') {
          totalPayments += amount.abs();
        }

        if (date != null) {
          if (lastTransactionDate == null ||
              date.isAfter(lastTransactionDate)) {
            lastTransactionDate = date;
          }
        }
      }

      // حساب الرصيد من المعاملات
      final currentBalance = totalCharges - totalPayments;

      return {
        'totalCharges': totalCharges,
        'totalPayments': totalPayments,
        'currentBalance': currentBalance,
        'totalTransactions': totalTransactions,
        'lastTransactionDate': lastTransactionDate,
      };
    } catch (e) {
      throw Exception('فشل في حساب ملخص الحساب: $e');
    }
  }

  /// حذف معاملة
  static Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection(_collection).doc(transactionId).delete();
    } catch (e) {
      throw Exception('فشل في حذف المعاملة: $e');
    }
  }

  /// حساب إجمالي المبيعات (إجمالي المدفوعات من المتاجر)
  static Future<double> getTotalSales(String networkId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('networkId', isEqualTo: networkId)
          .where('type', isEqualTo: 'payment')
          .where('status', isEqualTo: 'completed')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount.abs();
      }

      return total;
    } catch (e) {
      return 0;
    }
  }
}
