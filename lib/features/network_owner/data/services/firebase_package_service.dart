import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class FirebasePackageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'packages';

  // إضافة باقة جديدة
  static Future<String> addPackage(PackageModel package) async {
    try {
      final docRef = await _firestore.collection(_collection).add(package.toFirestore());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('فشل في إضافة الباقة: $e');
    }
  }

  // تحديث باقة موجودة
  static Future<void> updatePackage(
    String packageId,
    PackageModel package,
  ) async {
    try {
      await _firestore.collection(_collection).doc(packageId).update(package.toFirestore());
    } on Exception catch (e) {
      throw Exception('فشل في تحديث الباقة: $e');
    }
  }

  // حذف باقة
  static Future<void> deletePackage(String packageId) async {
    try {
      await _firestore.collection(_collection).doc(packageId).delete();
    } on Exception catch (e) {
      throw Exception('فشل في حذف الباقة: $e');
    }
  }

  // الحصول على باقة واحدة
  static Future<PackageModel?> getPackage(String packageId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(packageId).get();
      if (doc.exists) {
        return PackageModel.fromFirestore(doc);
      }
      return null;
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على الباقة: $e');
    }
  }

  // الحصول على جميع الباقات لشبكة معينة (بما فيها الموقوفة لمالك الشبكة)
  static Stream<List<PackageModel>> getPackagesByNetwork(String networkId) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        // لا نفلتر حسب isActive - يجب أن تظهر جميع الباقات لمالك الشبكة
        .snapshots()
        .map((snapshot) {
      final packages = snapshot.docs.map(PackageModel.fromFirestore).toList();
      // ترتيب في الكود بدلاً من Firebase (لتجنب الحاجة لـ composite index)
      packages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return packages;
    });
  }

  // الحصول على الباقات المفعلة فقط (للمتاجر)
  static Stream<List<PackageModel>> getActivePackagesByNetwork(String networkId) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final packages = snapshot.docs.map(PackageModel.fromFirestore).toList();
      // ترتيب في الكود بدلاً من Firebase (لتجنب الحاجة لـ composite index)
      packages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return packages;
    });
  }

  // البحث في الباقات
  static Stream<List<PackageModel>> searchPackages(
    String networkId,
    String searchQuery,
  ) {
    // البحث النصي يتطلب composite index معقد
    // بدلاً من ذلك، نجلب كل الباقات ونفلترها في الكود
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final packages = snapshot.docs.map(PackageModel.fromFirestore).toList();

      // فلترة وبحث في الكود
      final searchLower = searchQuery.toLowerCase();
      final filtered = packages.where((pkg) {
        return pkg.name.toLowerCase().contains(searchLower) || pkg.mikrotikName.toLowerCase().contains(searchLower);
      }).toList();

      // ترتيب حسب الاسم
      filtered.sort((a, b) => a.name.compareTo(b.name));

      return filtered;
    });
  }

  // تحديث مخزون الباقة
  static Future<void> updatePackageStock(String packageId, int newStock) async {
    try {
      await _firestore.collection(_collection).doc(packageId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });
    } on Exception catch (e) {
      throw Exception('فشل في تحديث المخزون: $e');
    }
  }

  // تفعيل/إيقاف الباقة
  static Future<void> togglePackageStatus(String packageId, {required bool isActive}) async {
    try {
      await _firestore.collection(_collection).doc(packageId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } on Exception catch (e) {
      throw Exception('فشل في ${isActive ? 'تفعيل' : 'إيقاف'} الباقة: $e');
    }
  }

  // الحصول على إحصائيات الباقات
  static Future<Map<String, dynamic>> getPackageStats(String networkId) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('networkId', isEqualTo: networkId).get();

      var totalPackages = 0;
      var totalStock = 0;
      double totalValue = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] as bool? ?? true;

        // فقط الباقات النشطة
        if (!isActive) continue;

        totalPackages++;
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0.0;

        totalStock += stock;
        totalValue += stock * sellingPrice;
      }

      return {
        'totalPackages': totalPackages,
        'totalStock': totalStock,
        'totalValue': totalValue,
      };
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على الإحصائيات: $e');
    }
  }
}
