import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/firebase_card_service.dart';

class CardProvider extends ChangeNotifier {
  List<CardModel> _cards = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;

  // تحميل الكروت لشبكة معينة
  void loadCards(String networkId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      FirebaseCardService.getCardsByNetwork(networkId).listen(
        (cards) {
          _cards = cards;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _isLoading = false;
          _error = error.toString();
          notifyListeners();
        },
      );
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // تحميل الكروت حسب الحالة
  void loadCardsByStatus(String networkId, CardStatus status) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      FirebaseCardService.getCardsByStatus(networkId, status).listen(
        (cards) {
          _cards = cards;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _isLoading = false;
          _error = error.toString();
          notifyListeners();
        },
      );
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // تحميل الكروت لباقة معينة
  void loadCardsByPackage(String networkId, String packageId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      FirebaseCardService.getCardsByPackage(networkId, packageId).listen(
        (cards) {
          _cards = cards;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _isLoading = false;
          _error = error.toString();
          notifyListeners();
        },
      );
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // استيراد كروت جديدة
  Future<bool> importCards(List<CardModel> cards) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseCardService.importCards(cards);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // إضافة كرت واحد
  Future<bool> addCard(CardModel card) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseCardService.addCard(card);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // تحديث حالة الكرت
  Future<bool> updateCardStatus(String cardId, CardStatus status,
      {String? usedBy, String? soldTo,}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseCardService.updateCardStatus(cardId, status,
          usedBy: usedBy, soldTo: soldTo,);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // حذف كرت
  Future<bool> deleteCard(String cardId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseCardService.deleteCard(cardId);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCards(List<String> cardIds) async {
    if (cardIds.isEmpty) return true;
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseCardService.deleteCards(cardIds);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // تحميل إحصائيات الكروت
  Future<void> loadStats(String networkId) async {
    try {
      _stats = await FirebaseCardService.getCardStats(networkId);
      notifyListeners();
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // البحث في الكروت
  void searchCards(String networkId, String query) {
    if (query.isEmpty) {
      loadCards(networkId);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      FirebaseCardService.searchCards(networkId, query).listen(
        (cards) {
          _cards = cards;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _isLoading = false;
          _error = error.toString();
          notifyListeners();
        },
      );
    } on Exception catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // تصدير الكروت
  Future<List<Map<String, dynamic>>> exportCards(String networkId) async {
    try {
      return await FirebaseCardService.exportCardsToCSV(networkId);
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // مسح الأخطاء
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // إعادة تعيين الحالة
  void reset() {
    _cards = [];
    _isLoading = false;
    _error = null;
    _stats = null;
    notifyListeners();
  }
}
