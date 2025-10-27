import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vendor_transaction_model.dart';

/// خدمة Firebase لإدارة معاملات المتجر مع الشبكة
class FirebaseVendorTransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  /// الحصول على معاملات المتجر مع شبكة معينة
  static Stream<List<VendorTransactionModel>> getVendorNetworkTransactions({
    required String vendorId,
    required String networkId,
  }) {
    print(
        '🔍 Setting up transactions stream: vendorId=$vendorId, networkId=$networkId');

    return _firestore
        .collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .where('networkId', isEqualTo: networkId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
          '📥 Transactions snapshot received: ${snapshot.docs.length} transactions');

      final transactions = snapshot.docs.map((doc) {
        print(
            '   - Transaction: ${doc.id}, type: ${doc.data()['type']}, amount: ${doc.data()['amount']}');
        return VendorTransactionModel.fromFirestore(doc);
      }).toList();

      print('✅ Parsed ${transactions.length} transactions');
      return transactions;
    });
  }

  /// حساب ملخص الحساب (الرصيد، إجمالي الشحن، إجمالي الدفع)
  static Future<Map<String, double>> getAccountSummary({
    required String vendorId,
    required String networkId,
  }) async {
    try {
      print(
          '🔍 Calculating account summary: vendorId=$vendorId, networkId=$networkId');

      final snapshot = await _firestore
          .collection(_collection)
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'completed')
          .get();

      print('📊 Found ${snapshot.docs.length} completed transactions');

      double totalCharges = 0; // إجمالي الشحن (مدين)
      double totalPayments = 0; // إجمالي الدفع (دائن)

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        print('   - ${doc.id}: type=$type, amount=$amount');

        if (type == 'charge') {
          totalCharges += amount;
        } else if (type == 'payment') {
          totalPayments += amount;
        }
      }

      // الرصيد = الشحن - الدفع (موجب = دين على المتجر)
      final balance = totalCharges - totalPayments;

      print(
          '💰 Summary: charges=$totalCharges, payments=$totalPayments, balance=$balance');

      return {
        'balance': balance,
        'totalCharges': totalCharges,
        'totalPayments': totalPayments,
      };
    } catch (e) {
      print('❌ Error calculating summary: $e');
      return {
        'balance': 0,
        'totalCharges': 0,
        'totalPayments': 0,
      };
    }
  }
}
