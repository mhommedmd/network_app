import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';

/// خدمة تتبع الكروت المباعة من قبل أصحاب المتاجر
/// تقوم بمراقبة حالة الكروت وتحديثها من (transferred) إلى (sold)
class FirebaseCardTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// مراقبة الكروت المباعة في الوقت الفعلي
  /// يستمع للتغييرات على كروت المتاجر ويحدث حالتها في Firebase
  Stream<List<CardModel>> watchSoldCards(String networkId) {
    return _firestore
        .collection('cards')
        .where('networkId', isEqualTo: networkId)
        .where('status', isEqualTo: 'transferred')
        .snapshots()
        .asyncMap((snapshot) async {
      final soldCards = <CardModel>[];

      for (final doc in snapshot.docs) {
        final card = CardModel.fromFirestore(doc);

        // التحقق من حالة البيع في مجموعة المتاجر
        final isSold = await _checkIfCardSoldByVendor(card);

        if (isSold) {
          // تحديث حالة الكرت إلى مباع
          await _markCardAsSold(card);
          soldCards.add(card.copyWith(status: CardStatus.sold));
        }
      }

      return soldCards;
    });
  }

  /// التحقق من بيع الكرت من قبل المتجر
  Future<bool> _checkIfCardSoldByVendor(CardModel card) async {
    try {
      // البحث في معاملات المتاجر
      final vendorTransactions = await _firestore
          .collection('vendor_transactions')
          .where('cardNumber', isEqualTo: card.cardNumber)
          .where('type', isEqualTo: 'sale')
          .get();

      if (vendorTransactions.docs.isNotEmpty) {
        return true;
      }

      // البحث في سجلات المبيعات
      final salesRecords = await _firestore
          .collection('sales')
          .where('cardNumber', isEqualTo: card.cardNumber)
          .where('status', isEqualTo: 'completed')
          .get();

      return salesRecords.docs.isNotEmpty;
    } on Exception catch (e) {
      print('خطأ في التحقق من بيع الكرت: $e');
      return false;
    }
  }

  /// تحديث حالة الكرت إلى مباع
  Future<void> _markCardAsSold(CardModel card) async {
    try {
      await _firestore.collection('cards').doc(card.id).update({
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });

      print('✅ تم تحديث الكرت ${card.cardNumber} إلى حالة (مباع)');
    } on Exception catch (e) {
      print('❌ خطأ في تحديث حالة الكرت: $e');
    }
  }

  /// مزامنة جميع الكروت المباعة (استخدام لمرة واحدة)
  /// يفحص جميع الكروت المنقولة ويحدث حالة المباعة منها
  Future<int> syncAllSoldCards(String networkId) async {
    try {
      final transferredCards = await _firestore
          .collection('cards')
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'transferred')
          .get();

      var updatedCount = 0;

      for (final doc in transferredCards.docs) {
        final card = CardModel.fromFirestore(doc);
        final isSold = await _checkIfCardSoldByVendor(card);

        if (isSold) {
          await _markCardAsSold(card);
          updatedCount++;
        }
      }

      print('✅ تم مزامنة $updatedCount كرت إلى حالة (مباع)');
      return updatedCount;
    } on Exception catch (e) {
      print('❌ خطأ في مزامنة الكروت المباعة: $e');
      return 0;
    }
  }

  /// الحصول على إحصائيات الكروت المباعة
  Future<Map<String, dynamic>> getSoldCardsStats(String networkId) async {
    try {
      final soldCards = await _firestore
          .collection('cards')
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'sold')
          .get();

      final packageCounts = <String, int>{};
      for (final doc in soldCards.docs) {
        final card = CardModel.fromFirestore(doc);
        packageCounts.update(
          card.packageName,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      return {
        'totalSold': soldCards.docs.length,
        'packageBreakdown': packageCounts,
      };
    } on Exception catch (e) {
      print('❌ خطأ في الحصول على إحصائيات الكروت المباعة: $e');
      return {'totalSold': 0, 'packageBreakdown': <String, int>{}};
    }
  }

  /// تشغيل المراقبة التلقائية للكروت المباعة
  /// يقوم بفحص الكروت كل 5 دقائق وتحديث الحالة
  static void startAutomaticTracking(String networkId) {
    final service = FirebaseCardTrackingService();

    // المراقبة المباشرة عبر Stream
    service.watchSoldCards(networkId).listen((soldCards) {
      if (soldCards.isNotEmpty) {
        print('🔔 تم اكتشاف ${soldCards.length} كرت مباع جديد');
      }
    });

    print('✅ تم تفعيل المراقبة التلقائية للكروت المباعة');
  }
}


