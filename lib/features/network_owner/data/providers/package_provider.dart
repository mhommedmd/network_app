import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../services/firebase_package_service.dart';

class PackageProvider extends ChangeNotifier {
  List<PackageModel> _packages = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  List<PackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;

  // تحميل الباقات لشبكة معينة
  void loadPackages(String networkId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      FirebasePackageService.getPackagesByNetwork(networkId).listen(
        (packages) {
          _packages = packages;
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

  // إضافة باقة جديدة
  Future<bool> addPackage(PackageModel package) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebasePackageService.addPackage(package);

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

  // تحديث باقة
  Future<bool> updatePackage(String packageId, PackageModel package) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebasePackageService.updatePackage(packageId, package);

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

  // حذف باقة
  Future<bool> deletePackage(String packageId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebasePackageService.deletePackage(packageId);

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

  // تحديث مخزون الباقة
  Future<bool> updateStock(String packageId, int newStock) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebasePackageService.updatePackageStock(packageId, newStock);

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

  // تفعيل/إيقاف الباقة
  Future<bool> togglePackageStatus(String packageId, {required bool isActive}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebasePackageService.togglePackageStatus(packageId, isActive: isActive);

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

  // تحميل إحصائيات الباقات
  Future<void> loadStats(String networkId) async {
    try {
      _stats = await FirebasePackageService.getPackageStats(networkId);
      notifyListeners();
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // البحث في الباقات
  void searchPackages(String networkId, String query) {
    if (query.isEmpty) {
      loadPackages(networkId);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      FirebasePackageService.searchPackages(networkId, query).listen(
        (packages) {
          _packages = packages;
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

  // مسح الأخطاء
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // إعادة تعيين الحالة
  void reset() {
    _packages = [];
    _isLoading = false;
    _error = null;
    _stats = null;
    notifyListeners();
  }
}
