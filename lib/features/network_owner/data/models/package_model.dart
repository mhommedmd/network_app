import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String name;
  final String mikrotikName;
  final double sellingPrice;
  final double purchasePrice;
  final int validityDays;
  final int usageHours;
  final int dataSizeGB;
  final int dataSizeMB;
  final String color;
  final int stock;
  final String? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final String networkId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PackageModel({
    required this.id,
    required this.name,
    required this.mikrotikName,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.validityDays,
    required this.usageHours,
    required this.dataSizeGB,
    required this.dataSizeMB,
    required this.color,
    required this.stock,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.networkId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      mikrotikName: data['mikrotikName']?.toString() ?? '',
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      validityDays: (data['validityDays'] as num?)?.toInt() ?? 0,
      usageHours: (data['usageHours'] as num?)?.toInt() ?? 0,
      dataSizeGB: (data['dataSizeGB'] as num?)?.toInt() ?? 0,
      dataSizeMB: (data['dataSizeMB'] as num?)?.toInt() ?? 0,
      color: data['color']?.toString() ?? 'blue',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      iconCodePoint: data['iconCodePoint']?.toString(),
      iconFontFamily: data['iconFontFamily']?.toString(),
      iconFontPackage: data['iconFontPackage']?.toString(),
      networkId: data['networkId']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'mikrotikName': mikrotikName,
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
      'validityDays': validityDays,
      'usageHours': usageHours,
      'dataSizeGB': dataSizeGB,
      'dataSizeMB': dataSizeMB,
      'color': color,
      'stock': stock,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'networkId': networkId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  PackageModel copyWith({
    String? id,
    String? name,
    String? mikrotikName,
    double? sellingPrice,
    double? purchasePrice,
    int? validityDays,
    int? usageHours,
    int? dataSizeGB,
    int? dataSizeMB,
    String? color,
    int? stock,
    String? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    String? networkId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mikrotikName: mikrotikName ?? this.mikrotikName,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      validityDays: validityDays ?? this.validityDays,
      usageHours: usageHours ?? this.usageHours,
      dataSizeGB: dataSizeGB ?? this.dataSizeGB,
      dataSizeMB: dataSizeMB ?? this.dataSizeMB,
      color: color ?? this.color,
      stock: stock ?? this.stock,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      networkId: networkId ?? this.networkId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
