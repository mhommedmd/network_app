import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';

class FirebaseCardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'cards';

  // إضافة كروت جديدة (استيراد)
  static Future<List<String>> importCards(List<CardModel> cards) async {
    try {
      final batch = _firestore.batch();
      final cardIds = <String>[];

      for (final card in cards) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, card.toFirestore());
        cardIds.add(docRef.id);
      }

      await batch.commit();
      return cardIds;
    } on Exception catch (e) {
      throw Exception('فشل في استيراد الكروت: $e');
    }
  }

  // إضافة كرت واحد
  static Future<String> addCard(CardModel card) async {
    try {
      final docRef = await _firestore.collection(_collection).add(card.toFirestore());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('فشل في إضافة الكرت: $e');
    }
  }

  // تحديث حالة الكرت
  static Future<void> updateCardStatus(
    String cardId,
    CardStatus status, {
    String? usedBy,
    String? soldTo,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (status == CardStatus.sold && soldTo != null) {
        updateData['soldTo'] = soldTo;
        updateData['soldAt'] = Timestamp.now();
      }

      if (status == CardStatus.used && usedBy != null) {
        updateData['usedBy'] = usedBy;
        updateData['usedAt'] = Timestamp.now();
      }

      await _firestore.collection(_collection).doc(cardId).update(updateData);
    } on Exception catch (e) {
      throw Exception('فشل في تحديث حالة الكرت: $e');
    }
  }

  // حذف كرت
  static Future<void> deleteCard(String cardId) async {
    try {
      await _firestore.collection(_collection).doc(cardId).delete();
    } on Exception catch (e) {
      throw Exception('فشل في حذف الكرت: $e');
    }
  }

  static Future<void> deleteCards(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final id in cardIds) {
        final docRef = _firestore.collection(_collection).doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
    } on Exception catch (e) {
      throw Exception('فشل في حذف الكروت: $e');
    }
  }

  // الحصول على كرت واحد
  static Future<CardModel?> getCard(String cardId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(cardId).get();
      if (doc.exists) {
        return CardModel.fromFirestore(doc);
      }
      return null;
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على الكرت: $e');
    }
  }

  // الحصول على الكروت حسب الشبكة
  static Stream<List<CardModel>> getCardsByNetwork(String networkId) {
    return _firestore.collection(_collection).where('networkId', isEqualTo: networkId).snapshots().map((snapshot) {
      final cards = snapshot.docs.map(CardModel.fromFirestore).toList();
      // ترتيب حسب تاريخ الإنشاء في الكود
      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cards;
    });
  }

  // الحصول على الكروت حسب الحالة
  static Stream<List<CardModel>> getCardsByStatus(
    String networkId,
    CardStatus status,
  ) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CardModel.fromFirestore).toList(),
        );
  }

  // الحصول على الكروت حسب الحالة (مرة واحدة)
  static Future<List<CardModel>> getCardsByStatusOnce(
    String networkId,
    CardStatus status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: status.name)
          .get();

      return snapshot.docs.map(CardModel.fromFirestore).toList();
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على الكروت: $e');
    }
  }

  // البحث في الكروت
  static Stream<List<CardModel>> searchCards(
    String networkId,
    String searchQuery,
  ) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('cardNumber', isGreaterThanOrEqualTo: searchQuery)
        .where('cardNumber', isLessThan: '${searchQuery}z')
        .orderBy('cardNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CardModel.fromFirestore).toList(),
        );
  }

  // الحصول على كروت باقة معينة
  static Stream<List<CardModel>> getCardsByPackage(
    String networkId,
    String packageId,
  ) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('packageId', isEqualTo: packageId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CardModel.fromFirestore).toList(),
        );
  }

  // الحصول على إحصائيات الكروت
  static Future<Map<String, dynamic>> getCardStats(String networkId) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('networkId', isEqualTo: networkId).get();

      final totalCards = snapshot.docs.length;
      var availableCards = 0;
      var soldCards = 0;
      var usedCards = 0;
      var expiredCards = 0;
      double totalValue = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;

        totalValue += price;

        switch (status) {
          case 'available':
            availableCards++;
          case 'sold':
            soldCards++;
          case 'used':
            usedCards++;
          case 'expired':
            expiredCards++;
        }
      }

      return {
        'totalCards': totalCards,
        'availableCards': availableCards,
        'soldCards': soldCards,
        'usedCards': usedCards,
        'expiredCards': expiredCards,
        'totalValue': totalValue,
      };
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على إحصائيات الكروت: $e');
    }
  }

  // تصدير الكروت إلى CSV
  static Future<List<Map<String, dynamic>>> exportCardsToCSV(
    String networkId,
  ) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('networkId', isEqualTo: networkId).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'cardNumber': data['cardNumber'],
          'pin': data['pin'],
          'packageName': data['packageName'],
          'price': data['price'],
          'status': data['status'],
          'expiryDate': (data['expiryDate'] as Timestamp).toDate().toIso8601String(),
          'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
        };
      }).toList();
    } on Exception catch (e) {
      throw Exception('فشل في تصدير الكروت: $e');
    }
  }
}
