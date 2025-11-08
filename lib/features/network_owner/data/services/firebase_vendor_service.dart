import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';

/// خدمة Firebase لإدارة المتاجر (نقاط البيع)
class FirebaseVendorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'vendors';

  /// إضافة متجر جديد
  /// يستخدم composite key: {networkId}_{vendorId} للسماح بتعدد الشبكات
  static Future<String> addVendor(VendorModel vendor) async {
    try {
      final vendorData = vendor.toJson();
      // حفظ user ID الحقيقي في document
      vendorData['userId'] = vendor.realUserId;

      // استخدام composite key: networkId_vendorId
      // هذا يسمح لنفس المتجر بالانضمام لعدة شبكات
      final documentId = '${vendor.networkId}_${vendor.realUserId}';

      await _firestore.collection(_collection).doc(documentId).set(vendorData);

      // إنشاء اتصال في network_connections (مهم جداً لعرض الرصيد!)
      await _createNetworkConnection(vendor);

      return documentId;
    } on FirebaseException catch (e) {
      throw Exception('فشل في إضافة المتجر: [${e.code}] ${e.message}');
    } on Exception catch (e) {
      throw Exception('فشل في إضافة المتجر: $e');
    }
  }

  /// إنشاء اتصال بين المتجر والشبكة في network_connections
  static Future<void> _createNetworkConnection(VendorModel vendor) async {
    try {
      // التحقق من وجود اتصال مسبق
      final existingConnection = await _firestore
          .collection('network_connections')
          .where('vendorId', isEqualTo: vendor.realUserId)
          .where('networkId', isEqualTo: vendor.networkId)
          .limit(1)
          .get();
      
      // إذا كان الاتصال موجوداً مسبقاً، لا نضيفه مرة أخرى
      if (existingConnection.docs.isNotEmpty) {
        return;
      }
      
      // جلب بيانات المستخدم (vendor) من users collection
      final userDoc = await _firestore.collection('users').doc(vendor.realUserId).get();
      
      if (!userDoc.exists) {
        return;
      }
      
      final userData = userDoc.data()!;
      
      // جلب بيانات الشبكة من users collection
      final networkDoc = await _firestore.collection('users').doc(vendor.networkId).get();
      String networkName = 'شبكة';
      String networkOwner = '';
      
      if (networkDoc.exists) {
        final networkData = networkDoc.data()!;
        networkName = networkData['networkName'] as String? ?? 
                      networkData['name'] as String? ?? 
                      'شبكة';
        networkOwner = networkData['name'] as String? ?? '';
      }
      
      final connectionData = {
        'vendorId': vendor.realUserId,
        'networkId': vendor.networkId,
        'networkName': networkName,
        'networkOwner': networkOwner,
        'governorate': userData['governorate'] as String? ?? vendor.governorate,
        'district': userData['district'] as String? ?? vendor.district,
        'isActive': true,
        'connectedAt': Timestamp.fromDate(vendor.createdAt),
        'balance': vendor.balance, // الرصيد الابتدائي (عادة 0)
        'totalOrders': 0,
      };
      
      await _firestore.collection('network_connections').add(connectionData);
    } on Exception {
      // لا نرمي خطأ لأننا لا نريد أن نفشل عملية إضافة المتجر بالكامل
    }
  }

  /// تحديث معلومات متجر (يستخدم composite key)
  static Future<void> updateVendor(VendorModel vendor) async {
    try {
      final documentId = '${vendor.networkId}_${vendor.realUserId}';
      await _firestore.collection(_collection).doc(documentId).update({
        ...vendor.toJson(),
        'updatedAt': Timestamp.now(),
      });
    } on Exception catch (e) {
      throw Exception('فشل في تحديث المتجر: $e');
    }
  }

  /// حذف متجر (يستخدم composite key)
  /// يحذف المتجر من vendors collection و network_connections
  static Future<void> deleteVendor(String vendorId, String networkId) async {
    try {
      final documentId = '${networkId}_$vendorId';
      
      // 1. حذف document المتجر من vendors
      await _firestore.collection(_collection).doc(documentId).delete();
      
      // 2. حذف الاتصال من network_connections
      final connectionsSnapshot = await _firestore
          .collection('network_connections')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .get();
      
      for (final doc in connectionsSnapshot.docs) {
        await doc.reference.delete();
      }
    } on Exception catch (e) {
      throw Exception('فشل في حذف المتجر: $e');
    }
  }

  /// الحصول على متجر واحد (يستخدم composite key)
  static Future<VendorModel?> getVendor(String vendorId, {String? networkId}) async {
    try {
      // إذا كان networkId موجوداً، نستخدم composite key
      if (networkId != null) {
        final documentId = '${networkId}_$vendorId';
        final doc = await _firestore.collection(_collection).doc(documentId).get();
        if (doc.exists) {
          return VendorModel.fromFirestore(doc);
        }
        return null;
      }
      
      // للتوافق مع الكود القديم: البحث في جميع vendors بهذا userId
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: vendorId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return VendorModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } on Exception catch (e) {
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
          snapshot.docs.map(VendorModel.fromFirestore).toList();
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

      // استخراج userId من كل document (لأننا نستخدم composite key الآن)
      final addedVendorIds = addedVendorsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // البحث في users بنوع posVendor
      final Query query =
          _firestore.collection('users').where('type', isEqualTo: 'posVendor');

      final snapshot = await query.get();

      var vendors = <VendorModel>[];

      for (final doc in snapshot.docs) {
        // تخطي المتاجر المضافة بالفعل لهذه الشبكة
        if (addedVendorIds.contains(doc.id)) continue;

        final data = doc.data()! as Map<String, dynamic>;

        // تحويل من User إلى VendorModel
        final vendor = VendorModel(
          id: doc.id,
          userId: doc.id, // userId من users collection
          name: data['name'] as String? ?? '', // اسم المتجر
          ownerName: data['ownerName'] as String? ?? '', // اسم مالك المتجر
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
    } on Exception catch (e) {
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

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final governorate = data['governorate'] as String?;
        if (governorate != null && governorate.isNotEmpty) {
          governorates.add(governorate);
        }
      }

      final result = governorates.toList()..sort();
      return result;
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على المحافظات: $e');
    }
  }

  /// الحصول على قائمة المديريات لمحافظة معينة (من users بنوع posVendor)
  static Future<List<String>> getDistrictsByGovernorate(
      String governorate,) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'posVendor')
          .where('governorate', isEqualTo: governorate)
          .get();

      final districts = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final district = data['district'] as String?;
        if (district != null && district.isNotEmpty) {
          districts.add(district);
        }
      }

      final result = districts.toList()..sort();
      return result;
    } on Exception catch (e) {
      throw Exception('فشل في الحصول على المديريات: $e');
    }
  }

  /// تحديث رصيد متجر (يستخدم composite key)
  static Future<void> updateVendorBalance(
      String vendorId, String networkId, double newBalance,) async {
    try {
      final documentId = '${networkId}_$vendorId';
      await _firestore.collection(_collection).doc(documentId).update({
        'balance': newBalance,
        'updatedAt': Timestamp.now(),
      });
    } on Exception catch (e) {
      throw Exception('فشل في تحديث الرصيد: $e');
    }
  }

  /// تحديث مخزون متجر (يستخدم composite key)
  static Future<void> updateVendorStock(String vendorId, String networkId, int newStock) async {
    try {
      final documentId = '${networkId}_$vendorId';
      await _firestore.collection(_collection).doc(documentId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });
    } on Exception catch (e) {
      throw Exception('فشل في تحديث المخزون: $e');
    }
  }
}
