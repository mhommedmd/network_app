import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات المعاملة
class TransactionModel {
  TransactionModel({
    required this.id,
    required this.vendorId,
    required this.networkId,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    required this.reference,
    required this.status,
    required this.balanceAfter,
    required this.createdBy,
    this.method,
    this.notes,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      reference: data['reference'] as String? ?? '',
      status: data['status'] as String? ?? 'completed',
      balanceAfter: (data['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      method: data['method'] as String?,
      notes: data['notes'] as String?,
    );
  }

  final String id;
  final String vendorId;
  final String networkId;
  final DateTime date;
  final String type; // 'charge', 'payment', 'refund', 'fee', 'adjustment'
  final double amount;
  final String description;
  final String reference;
  final String status; // 'completed', 'pending', 'failed'
  final double balanceAfter;
  final String createdBy;
  final String? method; // 'cash', 'bank_transfer', 'mobile_wallet'
  final String? notes;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'vendorId': vendorId,
      'networkId': networkId,
      'date': Timestamp.fromDate(date),
      'type': type,
      'amount': amount,
      'description': description,
      'reference': reference,
      'status': status,
      'balanceAfter': balanceAfter,
      'createdBy': createdBy,
    };

    if (method != null && method!.isNotEmpty) {
      json['method'] = method;
    }

    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }

    return json;
  }
}
