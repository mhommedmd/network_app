import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/network_connection_model.dart';

/// خدمة Firebase لإدارة اتصالات الشبكات لنقاط البيع
class FirebaseNetworkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'network_connections';

  /// البحث عن الشبكات المتاحة (من users بنوع networkOwner)
  static Future<List<NetworkConnectionModel>> searchAvailableNetworks({
    required String vendorId,
    String? searchQuery,
    String? governorate,
    String? district,
  }) async {
    try {
      // الحصول على الشبكات المضافة بالفعل
      final connectedSnapshot = await _firestore
          .collection(_collection)
          .where('vendorId', isEqualTo: vendorId)
          .get();

      final connectedNetworkIds = connectedSnapshot.docs
          .map((doc) => doc.data()['networkId'] as String)
          .toSet();

      // البحث في users بنوع networkOwner
      Query query = _firestore
          .collection('users')
          .where('type', isEqualTo: 'networkOwner');

      final snapshot = await query.get();

      var networks = <NetworkConnectionModel>[];

      for (var doc in snapshot.docs) {
        // تخطي الشبكات المضافة بالفعل
        if (connectedNetworkIds.contains(doc.id)) continue;

        final data = doc.data() as Map<String, dynamic>;

        // تحويل من User إلى NetworkConnectionModel
        final network = NetworkConnectionModel(
          id: '',
          vendorId: '',
          networkId: doc.id,
          networkName:
              data['networkName'] as String? ?? data['name'] as String? ?? '',
          networkOwner: data['name'] as String? ?? '',
          governorate: data['governorate'] as String? ?? '',
          district: data['district'] as String? ?? '',
          isActive: true,
          connectedAt: DateTime.now(),
        );

        networks.add(network);
      }

      // تطبيق فلاتر المحافظة والمديرية
      if (governorate != null && governorate.isNotEmpty) {
        networks = networks.where((n) => n.governorate == governorate).toList();
      }

      if (district != null && district.isNotEmpty) {
        networks = networks.where((n) => n.district == district).toList();
      }

      // تطبيق البحث النصي
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final lowerQuery = searchQuery.trim().toLowerCase();
        networks = networks.where((network) {
          return network.networkName.toLowerCase().contains(lowerQuery) ||
              network.networkOwner.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      networks.sort((a, b) => a.networkName.compareTo(b.networkName));
      return networks;
    } catch (e) {
      throw Exception('فشل في البحث عن الشبكات: $e');
    }
  }

  /// إضافة اتصال شبكة جديد
  static Future<String> addNetworkConnection(
      NetworkConnectionModel connection) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(connection.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة الشبكة: $e');
    }
  }

  /// الحصول على الشبكات المتصلة
  static Stream<List<NetworkConnectionModel>> getConnectedNetworks(
      String vendorId) {
    return _firestore
        .collection(_collection)
        .where('vendorId', isEqualTo: vendorId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final networks = snapshot.docs
          .map((doc) => NetworkConnectionModel.fromFirestore(doc))
          .toList();
      networks.sort((a, b) => b.connectedAt.compareTo(a.connectedAt));
      return networks;
    });
  }

  /// حذف اتصال شبكة
  static Future<void> removeNetworkConnection(String connectionId) async {
    try {
      await _firestore.collection(_collection).doc(connectionId).delete();
    } catch (e) {
      throw Exception('فشل في حذف الاتصال: $e');
    }
  }

  /// الحصول على المحافظات المتاحة من الشبكات
  static Future<List<String>> getNetworkGovernorates() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'networkOwner')
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

  /// الحصول على المديريات حسب المحافظة
  static Future<List<String>> getNetworkDistricts(String governorate) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'networkOwner')
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
}
