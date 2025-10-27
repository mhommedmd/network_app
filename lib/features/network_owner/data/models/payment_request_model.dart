import 'package:cloud_firestore/cloud_firestore.dart';

/// حالة طلب الدفعة
enum PaymentRequestStatus {
  pending, // في الانتظار
  approved, // تمت الموافقة
  rejected, // مرفوض
}

/// نموذج طلب الدفعة النقدية
class PaymentRequestModel {
  PaymentRequestModel({
    required this.id,
    required this.vendorId,
    required this.networkId,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.notes,
  });

  factory PaymentRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRequestModel(
      id: doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  final String id;
  final String vendorId;
  final String networkId;
  final double amount;
  final String description;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'vendorId': vendorId,
      'networkId': networkId,
      'amount': amount,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (approvedAt != null) {
      json['approvedAt'] = Timestamp.fromDate(approvedAt!);
    }

    if (rejectedAt != null) {
      json['rejectedAt'] = Timestamp.fromDate(rejectedAt!);
    }

    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }

    return json;
  }

  static PaymentRequestStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return PaymentRequestStatus.approved;
      case 'rejected':
        return PaymentRequestStatus.rejected;
      default:
        return PaymentRequestStatus.pending;
    }
  }
}
