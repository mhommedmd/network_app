import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class FirebasePackageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'packages';

  // إضافة باقة جديدة
  static Future<String> addPackage(PackageModel package) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(package.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة الباقة: $e');
    }
  }

  // تحديث باقة موجودة
  static Future<void> updatePackage(
      String packageId, PackageModel package) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(packageId)
          .update(package.toFirestore());
    } catch (e) {
      throw Exception('فشل في تحديث الباقة: $e');
    }
  }

  // حذف باقة
  static Future<void> deletePackage(String packageId) async {
    try {
      await _firestore.collection(_collection).doc(packageId).delete();
    } catch (e) {
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
    } catch (e) {
      throw Exception('فشل في الحصول على الباقة: $e');
    }
  }

  // الحصول على جميع الباقات لشبكة معينة
  static Stream<List<PackageModel>> getPackagesByNetwork(String networkId) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PackageModel.fromFirestore(doc))
            .toList());
  }

  // البحث في الباقات
  static Stream<List<PackageModel>> searchPackages(
    String networkId,
    String searchQuery,
  ) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('isActive', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .where('name', isLessThan: searchQuery + 'z')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PackageModel.fromFirestore(doc))
            .toList());
  }

  // تحديث مخزون الباقة
  static Future<void> updatePackageStock(String packageId, int newStock) async {
    try {
      await _firestore.collection(_collection).doc(packageId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث المخزون: $e');
    }
  }

  // الحصول على إحصائيات الباقات
  static Future<Map<String, dynamic>> getPackageStats(String networkId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('networkId', isEqualTo: networkId)
          .get();

      int totalPackages = 0;
      int totalStock = 0;
      double totalValue = 0;

      for (var doc in snapshot.docs) {
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
    } catch (e) {
      throw Exception('فشل في الحصول على الإحصائيات: $e');
    }
  }
}
