import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات المتجر (نقطة البيع)
class VendorModel {
  VendorModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.governorate,
    required this.district,
    required this.address,
    required this.networkId,
    required this.balance,
    required this.stock,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      governorate: data['governorate'] as String? ?? '',
      district: data['district'] as String? ?? '',
      address: data['address'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      networkId: json['networkId'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'] as String))
          : null,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String governorate;
  final String district;
  final String address;
  final String networkId;
  final double balance;
  final int stock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'governorate': governorate,
      'district': district,
      'address': address,
      'networkId': networkId,
      'balance': balance,
      'stock': stock,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // إضافة id فقط إذا لم يكن فارغاً
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    // إضافة updatedAt فقط إذا كانت موجودة
    if (updatedAt != null) {
      json['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }

    // إضافة notes فقط إذا كانت موجودة
    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }

    return json;
  }

  String get location => '$governorate، $district';
  String get avatar => name.isNotEmpty ? name[0].toUpperCase() : 'م';
}
