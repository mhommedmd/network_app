import 'package:cloud_firestore/cloud_firestore.dart';

enum CardStatus {
  available,
  transferred,
  sold,
  used,
  expired,
  blocked,
}

class CardModel {
  final String id;
  final String cardNumber;
  final String pin;
  final String packageId;
  final String packageName;
  final double price;
  final DateTime expiryDate;
  final CardStatus status;
  final String? soldTo;
  final DateTime? soldAt;
  final String? usedBy;
  final DateTime? usedAt;
  final String networkId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  CardModel({
    required this.id,
    required this.cardNumber,
    required this.pin,
    required this.packageId,
    required this.packageName,
    required this.price,
    required this.expiryDate,
    required this.status,
    this.soldTo,
    this.soldAt,
    this.usedBy,
    this.usedAt,
    required this.networkId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  factory CardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CardModel(
      id: doc.id,
      cardNumber: data['cardNumber']?.toString() ?? '',
      pin: data['pin']?.toString() ?? '',
      packageId: data['packageId']?.toString() ?? '',
      packageName: data['packageName']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      status: CardStatus.values.firstWhere(
        (e) => e.name == data['status']?.toString(),
        orElse: () => CardStatus.available,
      ),
      soldTo: data['soldTo']?.toString(),
      soldAt: data['soldAt'] != null
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      usedBy: data['usedBy']?.toString(),
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
      networkId: data['networkId']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notes: data['notes']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cardNumber': cardNumber,
      'pin': pin,
      'packageId': packageId,
      'packageName': packageName,
      'price': price,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.name,
      'soldTo': soldTo,
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'networkId': networkId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
    };
  }

  CardModel copyWith({
    String? id,
    String? cardNumber,
    String? pin,
    String? packageId,
    String? packageName,
    double? price,
    DateTime? expiryDate,
    CardStatus? status,
    String? soldTo,
    DateTime? soldAt,
    String? usedBy,
    DateTime? usedAt,
    String? networkId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      pin: pin ?? this.pin,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      price: price ?? this.price,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      soldTo: soldTo ?? this.soldTo,
      soldAt: soldAt ?? this.soldAt,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      networkId: networkId ?? this.networkId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }
}
