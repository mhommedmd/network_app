import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';

/// خدمة Firebase لإدارة المتاجر (نقاط البيع)
class FirebaseVendorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'vendors';

  /// إضافة متجر جديد
  static Future<String> addVendor(VendorModel vendor) async {
    try {
      final vendorData = vendor.toJson();
      // حفظ user ID أيضاً في document
      vendorData['userId'] = vendor.id;

      print('💾 محاولة حفظ المتجر في Firestore...');
      print('   Collection: $_collection');
      print('   User ID: ${vendor.id}');
      print('   Data: $vendorData');

      // استخدام user ID كـ document ID مباشرة
      await _firestore.collection(_collection).doc(vendor.id).set(vendorData);

      print('✅ تم حفظ المتجر بنجاح - Document ID = User ID: ${vendor.id}');

      return vendor.id;
    } on FirebaseException catch (e) {
      print('❌ Firebase Error:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      throw Exception('فشل في إضافة المتجر: [${e.code}] ${e.message}');
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      throw Exception('فشل في إضافة المتجر: $e');
    }
  }

  /// تحديث معلومات متجر
  static Future<void> updateVendor(VendorModel vendor) async {
    try {
      await _firestore.collection(_collection).doc(vendor.id).update({
        ...vendor.toJson(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث المتجر: $e');
    }
  }

  /// حذف متجر
  static Future<void> deleteVendor(String vendorId) async {
    try {
      await _firestore.collection(_collection).doc(vendorId).delete();
    } catch (e) {
      throw Exception('فشل في حذف المتجر: $e');
    }
  }

  /// الحصول على متجر واحد
  static Future<VendorModel?> getVendor(String vendorId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(vendorId).get();
      if (doc.exists) {
        return VendorModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في الحصول على المتجر: $e');
    }
  }

  /// الحصول على جميع المتاجر لشبكة معينة
  static Stream<List<VendorModel>> getVendorsByNetwork(String networkId) {
    return _firestore
        .collection(_collection)
        .where('networkId', isEqualTo: networkId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final vendors =
          snapshot.docs.map((doc) => VendorModel.fromFirestore(doc)).toList();
      vendors.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vendors;
    });
  }

  /// البحث عن المتاجر المتاحة للإضافة (من users بنوع posVendor)
  static Future<List<VendorModel>> searchAvailableVendors({
    required String networkId,
    String? searchQuery,
    String? governorate,
    String? district,
  }) async {
    try {
      // الحصول على المتاجر المضافة بالفعل
      final addedVendorsSnapshot = await _firestore
          .collection(_collection)
          .where('networkId', isEqualTo: networkId)
          .get();

      final addedVendorIds =
          addedVendorsSnapshot.docs.map((doc) => doc.id).toSet();

      // البحث في users بنوع posVendor
      Query query =
          _firestore.collection('users').where('type', isEqualTo: 'posVendor');

      final snapshot = await query.get();

      var vendors = <VendorModel>[];

      for (var doc in snapshot.docs) {
        // تخطي المتاجر المضافة بالفعل
        if (addedVendorIds.contains(doc.id)) continue;

        final data = doc.data() as Map<String, dynamic>;

        // تحويل من User إلى VendorModel
        final vendor = VendorModel(
          id: doc.id,
          name: data['name'] as String? ?? '',
          ownerName: data['name'] as String? ?? '', // نفس الاسم
          phone: data['phone'] as String? ?? '',
          governorate: data['governorate'] as String? ?? '',
          district: data['district'] as String? ?? '',
          address: data['address'] as String? ?? '',
          networkId: '', // فارغ لأنه لم يضف بعد
          balance: 0,
          stock: 0,
          isActive: true,
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );

        vendors.add(vendor);
      }

      // تطبيق فلاتر المحافظة والمديرية
      if (governorate != null && governorate.isNotEmpty) {
        vendors = vendors.where((v) => v.governorate == governorate).toList();
      }

      if (district != null && district.isNotEmpty) {
        vendors = vendors.where((v) => v.district == district).toList();
      }

      // تطبيق البحث النصي
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final lowerQuery = searchQuery.trim().toLowerCase();
        vendors = vendors.where((vendor) {
          return vendor.name.toLowerCase().contains(lowerQuery) ||
              vendor.ownerName.toLowerCase().contains(lowerQuery) ||
              vendor.phone.contains(searchQuery.trim());
        }).toList();
      }

      vendors.sort((a, b) => a.name.compareTo(b.name));
      return vendors;
    } catch (e) {
      throw Exception('فشل في البحث عن المتاجر: $e');
    }
  }

  /// الحصول على قائمة المحافظات المتاحة (من users بنوع posVendor)
  static Future<List<String>> getAvailableGovernorates() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'posVendor')
          .get();
      final governorates = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final governorate = data['governorate'] as String?;
        if (governorate != null && governorate.isNotEmpty) {
          governorates.add(governorate);
        }
      }

      final result = governorates.toList()..sort();
      return result;
    } catch (e) {
      throw Exception('فشل في الحصول على المحافظات: $e');
    }
  }

  /// الحصول على قائمة المديريات لمحافظة معينة (من users بنوع posVendor)
  static Future<List<String>> getDistrictsByGovernorate(
      String governorate) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'posVendor')
          .where('governorate', isEqualTo: governorate)
          .get();

      final districts = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final district = data['district'] as String?;
        if (district != null && district.isNotEmpty) {
          districts.add(district);
        }
      }

      final result = districts.toList()..sort();
      return result;
    } catch (e) {
      throw Exception('فشل في الحصول على المديريات: $e');
    }
  }

  /// تحديث رصيد متجر
  static Future<void> updateVendorBalance(
      String vendorId, double newBalance) async {
    try {
      await _firestore.collection(_collection).doc(vendorId).update({
        'balance': newBalance,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث الرصيد: $e');
    }
  }

  /// تحديث مخزون متجر
  static Future<void> updateVendorStock(String vendorId, int newStock) async {
    try {
      await _firestore.collection(_collection).doc(vendorId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث المخزون: $e');
    }
  }
}
