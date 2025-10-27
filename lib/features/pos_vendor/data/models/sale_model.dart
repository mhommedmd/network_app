import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String vendorId;
  final String networkId;
  final String networkName;
  final Map<String, List<String>> packageCodes; // packageName -> [cardNumbers]
  final double totalAmount;
  final String? customerPhone;
  final DateTime soldAt;
  final int totalCards;

  SaleModel({
    required this.id,
    required this.vendorId,
    required this.networkId,
    required this.networkName,
    required this.packageCodes,
    required this.totalAmount,
    this.customerPhone,
    required this.soldAt,
    required this.totalCards,
  });

  factory SaleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // تحويل packageCodes من Map<String, dynamic> إلى Map<String, List<String>>
    final packageCodesData =
        data['packageCodes'] as Map<String, dynamic>? ?? {};
    final packageCodes = <String, List<String>>{};

    packageCodesData.forEach((key, value) {
      if (value is List) {
        packageCodes[key] = value.cast<String>();
      }
    });

    return SaleModel(
      id: doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      networkName: data['networkName'] as String? ?? '',
      packageCodes: packageCodes,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      customerPhone: data['customerPhone'] as String?,
      soldAt: (data['soldAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCards: data['totalCards'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'networkId': networkId,
      'networkName': networkName,
      'packageCodes': packageCodes,
      'totalAmount': totalAmount,
      'customerPhone': customerPhone,
      'soldAt': Timestamp.fromDate(soldAt),
      'totalCards': totalCards,
    };
  }
}
