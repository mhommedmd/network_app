import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';
import '../services/firebase_vendor_service.dart';

/// Provider لإدارة حالة المتاجر
class VendorProvider with ChangeNotifier {
  VendorProvider(this._networkId) {
    _loadVendors();
  }

  final String _networkId;
  List<VendorModel> _vendors = [];
  bool _isLoading = false;
  String? _error;

  List<VendorModel> get vendors => _vendors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get vendorsCount => _vendors.length;

  void _loadVendors() {
    FirebaseVendorService.getVendorsByNetwork(_networkId).listen(
      (vendors) {
        _vendors = vendors;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// إعادة تحميل المتاجر (للاستخدام مع Pull-to-Refresh)
  Future<void> loadVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // الانتظار قليلاً للسماح بتحديث Stream
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  /// إضافة متجر جديد
  Future<bool> addVendor(VendorModel vendor) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseVendorService.addVendor(vendor);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تحديث معلومات متجر
  Future<bool> updateVendor(VendorModel vendor) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseVendorService.updateVendor(vendor);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// حذف متجر (يستخدم composite key)
  Future<bool> deleteVendor(String vendorId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseVendorService.deleteVendor(vendorId, _networkId);

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تحديث رصيد متجر (يستخدم composite key)
  Future<bool> updateVendorBalance(String vendorId, double newBalance) async {
    try {
      await FirebaseVendorService.updateVendorBalance(vendorId, _networkId, newBalance);
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// تحديث مخزون متجر (يستخدم composite key)
  Future<bool> updateVendorStock(String vendorId, int newStock) async {
    try {
      await FirebaseVendorService.updateVendorStock(vendorId, _networkId, newStock);
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
