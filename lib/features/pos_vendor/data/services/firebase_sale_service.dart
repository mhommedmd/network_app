import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../network_owner/data/models/card_model.dart';
import '../models/sale_model.dart';

class FirebaseSaleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// بيع كروت - جلب الكروت المتاحة وتحديث حالتها
  static Future<Map<String, List<String>>> sellCards({
    required String vendorId,
    required String networkId,
    required String networkName,
    required Map<String, int> packageQuantities,
    String? customerPhone,
  }) async {
    final soldCards = <String, List<String>>{};

    try {
      // تنفيذ عملية البيع داخل Transaction
      await _firestore.runTransaction((transaction) async {
        for (final entry in packageQuantities.entries) {
          final packageId = entry.key;
          final quantity = entry.value;

          if (quantity <= 0) continue;

          // جلب الكروت المتاحة لهذه الباقة
          final cardsQuery = await _firestore
              .collection('vendor_cards')
              .where('vendorId', isEqualTo: vendorId)
              .where('networkId', isEqualTo: networkId)
              .where('packageId', isEqualTo: packageId)
              .where('status', isEqualTo: 'available')
              .limit(quantity)
              .get();

          if (cardsQuery.docs.length < quantity) {
            throw Exception(
              'عدد الكروت المتاحة غير كافٍ. متوفر: ${cardsQuery.docs.length}، مطلوب: $quantity',
            );
          }

          final cardNumbers = <String>[];

          // تحديث حالة الكروت إلى sold
          for (final cardDoc in cardsQuery.docs) {
            final cardData = cardDoc.data();
            final cardNumber = cardData['cardNumber'] as String;
            cardNumbers.add(cardNumber);

            transaction.update(
              cardDoc.reference,
              {
                'status': 'sold',
                'soldAt': FieldValue.serverTimestamp(),
                'soldTo': customerPhone ?? 'غير محدد',
              },
            );
          }

          // تخزين أرقام الكروت حسب اسم الباقة
          final packageName =
              cardsQuery.docs.first.data()['packageName'] as String? ?? 'باقة';
          soldCards[packageName] = cardNumbers;
        }
      });

      // تسجيل عملية البيع في مجموعة sales (خارج Transaction)
      final totalCards = soldCards.values.expand((cards) => cards).length;
      final totalAmount =
          await _calculateTotalAmount(packageQuantities, networkId);

      await _recordSale(
        vendorId: vendorId,
        networkId: networkId,
        networkName: networkName,
        packageCodes: soldCards,
        totalAmount: totalAmount,
        customerPhone: customerPhone,
        totalCards: totalCards,
      );

      return soldCards;
    } catch (e) {
      throw Exception('فشل في بيع الكروت: $e');
    }
  }

  /// الحصول على الكروت المتاحة لباقة معينة
  static Future<List<CardModel>> getAvailableCards({
    required String vendorId,
    required String networkId,
    required String packageId,
    int? limit,
  }) async {
    try {
      var query = _firestore
          .collection('vendor_cards')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('packageId', isEqualTo: packageId)
          .where('status', isEqualTo: 'available')
          .orderBy('importedAt');

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => CardModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('فشل في جلب الكروت المتاحة: $e');
    }
  }

  /// تسجيل عملية بيع في مجموعة sales
  static Future<void> _recordSale({
    required String vendorId,
    required String networkId,
    required String networkName,
    required Map<String, List<String>> packageCodes,
    required double totalAmount,
    String? customerPhone,
    required int totalCards,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('sales').add({
        'vendorId': vendorId,
        'networkId': networkId,
        'networkName': networkName,
        'packageCodes': packageCodes,
        'totalAmount': totalAmount,
        'customerPhone': customerPhone,
        'totalCards': totalCards,
        'soldAt': Timestamp.fromDate(now),
      });

      // طباعة للتأكد من التسجيل
      print(
          '✅ Sale recorded: vendorId=$vendorId, totalAmount=$totalAmount, totalCards=$totalCards');
    } catch (e) {
      print('❌ Error recording sale: $e');
      throw Exception('فشل في تسجيل البيع: $e');
    }
  }

  /// حساب المبلغ الإجمالي للبيع
  static Future<double> _calculateTotalAmount(
      Map<String, int> packageQuantities, String networkId) async {
    try {
      double totalAmount = 0.0;

      for (final entry in packageQuantities.entries) {
        final packageId = entry.key;
        final quantity = entry.value;

        if (quantity <= 0) continue;

        // جلب سعر الباقة من Firebase
        final packageDoc =
            await _firestore.collection('packages').doc(packageId).get();

        if (packageDoc.exists) {
          final packageData = packageDoc.data()!;
          final sellingPrice =
              (packageData['sellingPrice'] as num?)?.toDouble() ?? 0.0;
          final packageAmount = sellingPrice * quantity;
          totalAmount += packageAmount;
          print(
              '💵 Package: $packageId, price: $sellingPrice x $quantity = $packageAmount');
        }
      }

      print('💰 Total calculated amount: $totalAmount');
      return totalAmount;
    } catch (e) {
      print('❌ Error calculating total amount: $e');
      return 0.0;
    }
  }

  /// الحصول على آخر المبيعات للمتجر
  static Stream<List<SaleModel>> getRecentSales({
    required String vendorId,
    int limit = 10,
  }) {
    print('🔍 Setting up stream for recent sales: vendorId=$vendorId');
    return _firestore
        .collection('sales')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('soldAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      print('📥 Recent sales snapshot: ${snapshot.docs.length} documents');
      final sales = snapshot.docs.map((doc) {
        try {
          return SaleModel.fromFirestore(doc);
        } catch (e) {
          print('❌ Error parsing sale ${doc.id}: $e');
          rethrow;
        }
      }).toList();
      print('✅ Parsed ${sales.length} sales successfully');
      return sales;
    });
  }

  /// الحصول على تفاصيل عملية بيع
  static Future<SaleModel?> getSaleById(String saleId) async {
    try {
      final doc = await _firestore.collection('sales').doc(saleId).get();
      if (!doc.exists) return null;
      return SaleModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('فشل في جلب تفاصيل البيع: $e');
    }
  }
}
