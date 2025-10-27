import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج اتصال نقطة البيع بشبكة
class NetworkConnectionModel {
  NetworkConnectionModel({
    required this.id,
    required this.vendorId,
    required this.networkId,
    required this.networkName,
    required this.networkOwner,
    required this.governorate,
    required this.district,
    required this.isActive,
    required this.connectedAt,
    this.balance,
    this.totalOrders,
  });

  factory NetworkConnectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NetworkConnectionModel(
      id: doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      networkName: data['networkName'] as String? ?? '',
      networkOwner: data['networkOwner'] as String? ?? '',
      governorate: data['governorate'] as String? ?? '',
      district: data['district'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      connectedAt:
          (data['connectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String vendorId;
  final String networkId;
  final String networkName;
  final String networkOwner;
  final String governorate;
  final String district;
  final bool isActive;
  final DateTime connectedAt;
  final double? balance;
  final int? totalOrders;

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'networkId': networkId,
      'networkName': networkName,
      'networkOwner': networkOwner,
      'governorate': governorate,
      'district': district,
      'isActive': isActive,
      'connectedAt': Timestamp.fromDate(connectedAt),
      if (balance != null) 'balance': balance,
      if (totalOrders != null) 'totalOrders': totalOrders,
    };
  }
}
