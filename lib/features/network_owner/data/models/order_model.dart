import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_item_model.dart';

/// نموذج الطلب من المتجر إلى الشبكة
class OrderModel {
  OrderModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.networkId,
    required this.networkName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.notes,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    // قراءة items من الـ array
    final itemsList = data['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      vendorName: data['vendorName'] as String? ?? '',
      networkId: data['networkId'] as String? ?? '',
      networkName: data['networkName'] as String? ?? '',
      items: items,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  final String id;
  final String vendorId;
  final String vendorName;
  final String networkId;
  final String networkName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? notes;

  // حساب إجمالي الكروت
  int get totalCards => items.fold(0, (total, item) => total + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'networkId': networkId,
      'networkName': networkName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  OrderModel copyWith({
    String? status,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? notes,
  }) {
    return OrderModel(
      id: id,
      vendorId: vendorId,
      vendorName: vendorName,
      networkId: networkId,
      networkName: networkName,
      items: items,
      totalAmount: totalAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      notes: notes ?? this.notes,
    );
  }
}
