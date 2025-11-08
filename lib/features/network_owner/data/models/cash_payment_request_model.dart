import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج طلب الدفعة النقدية من الشبكة إلى المتجر
class CashPaymentRequestModel {
  CashPaymentRequestModel({
    required this.id,
    required this.networkId,
    required this.networkName,
    required this.vendorId,
    required this.vendorName,
    required this.amount,
    required this.note,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.processedBy,
  });

  factory CashPaymentRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return CashPaymentRequestModel(
      id: doc.id,
      networkId: data['networkId'] as String? ?? '',
      networkName: data['networkName'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      vendorName: data['vendorName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      note: data['note'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      processedBy: data['processedBy'] as String?,
    );
  }

  final String id;
  final String networkId;
  final String networkName;
  final String vendorId;
  final String vendorName;
  final double amount;
  final String note;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? processedBy;

  Map<String, dynamic> toJson() {
    return {
      'networkId': networkId,
      'networkName': networkName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'amount': amount,
      'note': note,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (processedBy != null) 'processedBy': processedBy,
    };
  }

  CashPaymentRequestModel copyWith({
    String? status,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? processedBy,
  }) {
    return CashPaymentRequestModel(
      id: id,
      networkId: networkId,
      networkName: networkName,
      vendorId: vendorId,
      vendorName: vendorName,
      amount: amount,
      note: note,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      processedBy: processedBy ?? this.processedBy,
    );
  }
}
