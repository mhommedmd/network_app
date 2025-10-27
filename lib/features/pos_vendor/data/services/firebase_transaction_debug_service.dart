import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة تشخيص مشاكل المعاملات
class FirebaseTransactionDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// طباعة جميع المعاملات في Firebase Console
  static Future<void> printAllTransactions() async {
    try {
      print('═══════════════════════════════════════');
      print('🔍 FETCHING ALL TRANSACTIONS FROM FIREBASE');
      print('═══════════════════════════════════════');

      final snapshot = await _firestore.collection('transactions').get();

      print(
          '\n📊 Total documents in transactions collection: ${snapshot.docs.length}\n');

      if (snapshot.docs.isEmpty) {
        print('❌ NO TRANSACTIONS FOUND IN FIREBASE!');
        print('   This means transactions are not being saved.');
        print('   Check the approveOrder and approvePaymentRequest functions.');
        return;
      }

      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        print('─────────────────────────────────────');
        print('Transaction #${i + 1}:');
        print('  ID: ${doc.id}');
        print('  vendorId: ${data['vendorId'] ?? 'MISSING!'}');
        print('  networkId: ${data['networkId'] ?? 'MISSING!'}');
        print('  type: ${data['type'] ?? 'MISSING!'}');
        print('  amount: ${data['amount'] ?? 'MISSING!'}');
        print('  description: ${data['description'] ?? 'MISSING!'}');
        print('  status: ${data['status'] ?? 'MISSING!'}');
        print('  date: ${data['date'] ?? 'MISSING!'}');
        print('  orderId: ${data['orderId'] ?? 'N/A'}');
        print('  paymentRequestId: ${data['paymentRequestId'] ?? 'N/A'}');
        print('─────────────────────────────────────');
      }

      print('\n═══════════════════════════════════════');
      print('✅ FINISHED PRINTING ALL TRANSACTIONS');
      print('═══════════════════════════════════════\n');
    } catch (e) {
      print('❌ ERROR FETCHING TRANSACTIONS: $e');
    }
  }

  /// طباعة المعاملات الخاصة بمتجر وشبكة معينة
  static Future<void> printVendorNetworkTransactions({
    required String vendorId,
    required String networkId,
  }) async {
    try {
      print('\n═══════════════════════════════════════');
      print('🔍 FETCHING TRANSACTIONS FOR:');
      print('   vendorId: $vendorId');
      print('   networkId: $networkId');
      print('═══════════════════════════════════════\n');

      final snapshot = await _firestore
          .collection('transactions')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .get();

      print('📊 Found ${snapshot.docs.length} transactions\n');

      if (snapshot.docs.isEmpty) {
        print('❌ NO TRANSACTIONS FOUND!');
        print('\nPossible reasons:');
        print('  1. vendorId or networkId is incorrect');
        print('  2. No orders have been approved yet');
        print('  3. Transactions were not saved properly');
        print('\nTo debug:');
        print('  - Call printAllTransactions() to see all transactions');
        print('  - Compare vendorId/networkId with what\'s in Firebase');
        return;
      }

      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        print('─────────────────────────────────────');
        print('Transaction #${i + 1}:');
        print('  ID: ${doc.id}');
        print('  type: ${data['type']}');
        print('  amount: ${data['amount']}');
        print('  description: ${data['description']}');
        print('  status: ${data['status']}');
        print('  date: ${data['date']}');
        print('─────────────────────────────────────');
      }

      print('\n✅ FINISHED\n');
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }

  /// اختبار الاستعلام مع orderBy
  static Future<void> testQueryWithOrderBy({
    required String vendorId,
    required String networkId,
  }) async {
    try {
      print('\n═══════════════════════════════════════');
      print('🔍 TESTING QUERY WITH ORDER BY:');
      print('   vendorId: $vendorId');
      print('   networkId: $networkId');
      print('═══════════════════════════════════════\n');

      final snapshot = await _firestore
          .collection('transactions')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .orderBy('date', descending: true)
          .get();

      print('📊 Query result: ${snapshot.docs.length} transactions\n');

      if (snapshot.docs.isEmpty) {
        print('❌ QUERY RETURNED EMPTY!');
        print('\nTrying without orderBy...\n');

        final snapshot2 = await _firestore
            .collection('transactions')
            .where('vendorId', isEqualTo: vendorId)
            .where('networkId', isEqualTo: networkId)
            .get();

        print('📊 Without orderBy: ${snapshot2.docs.length} transactions');

        if (snapshot2.docs.isNotEmpty) {
          print('\n⚠️ INDEX MISSING OR NOT READY!');
          print('   The query works without orderBy but fails with it.');
          print('   Wait for the index to finish building.');
        }
      } else {
        print('✅ Query with orderBy works!');
        print('   Index is ready and working.');
      }

      print('\n═══════════════════════════════════════\n');
    } catch (e) {
      print('❌ ERROR: $e');
      if (e.toString().contains('index')) {
        print('\n⚠️ INDEX REQUIRED!');
        print('   Create the index from the error message link.');
      }
    }
  }
}
