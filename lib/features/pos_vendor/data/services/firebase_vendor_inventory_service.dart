import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة لإدارة مخزون المتجر (POS Vendor) من الكروت
class FirebaseVendorInventoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// حساب عدد الكروت المتاحة لدى المتجر لكل باقة
  static Future<Map<String, int>> getVendorPackageStock({
    required String vendorId,
    required String networkId,
  }) async {
    try {
      // استعلام للحصول على الكروت المتاحة لدى المتجر
      final snapshot = await _firestore
          .collection('vendor_cards')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'available')
          .get();

      // حساب عدد الكروت لكل باقة
      final packageStock = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final packageId = data['packageId'] as String? ?? '';
        if (packageId.isNotEmpty) {
          packageStock[packageId] = (packageStock[packageId] ?? 0) + 1;
        }
      }

      return packageStock;
    } catch (e) {
      return {};
    }
  }

  /// حساب عدد الكروت المتاحة لباقة معينة
  static Future<int> getPackageStockCount({
    required String vendorId,
    required String networkId,
    required String packageId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('vendor_cards')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .where('packageId', isEqualTo: packageId)
          .where('status', isEqualTo: 'available')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
