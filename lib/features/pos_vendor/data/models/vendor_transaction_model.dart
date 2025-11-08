import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج معاملة المتجر مع الشبكة
class VendorTransactionModel {
  VendorTransactionModel({
    required this.id,
    required this.vendorId,
    required this.networkId,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.date,
    this.orderId,
    this.paymentRequestId,
  });

  factory VendorTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return VendorTransactionModel(
      id: doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderId: data['orderId'] as String?,
      paymentRequestId: data['paymentRequestId'] as String?,
    );
  }

  final String id;
  final String vendorId;
  final String networkId;
  final String type; // charge (مدين - طلب كروت)، payment (دائن - دفعة نقدية)
  final double amount;
  final String description;
  final String status; // pending, completed, rejected
  final DateTime date;
  final String? orderId;
  final String? paymentRequestId;

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'networkId': networkId,
      'type': type,
      'amount': amount,
      'description': description,
      'status': status,
      'date': Timestamp.fromDate(date),
      if (orderId != null && orderId!.isNotEmpty) 'orderId': orderId,
      if (paymentRequestId != null && paymentRequestId!.isNotEmpty)
        'paymentRequestId': paymentRequestId,
    };
  }

  // هل المعاملة مدين (طلب كروت)؟
  bool get isDebit => type == 'charge';

  // هل المعاملة دائن (دفعة نقدية)؟
  bool get isCredit => type == 'payment';
}
