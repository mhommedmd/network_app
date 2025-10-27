/// عنصر في الطلب (باقة واحدة بكمية معينة)
class OrderItemModel {
  OrderItemModel({
    required this.packageId,
    required this.packageName,
    required this.quantity,
    required this.pricePerCard,
    required this.totalAmount,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      packageId: json['packageId'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      pricePerCard: (json['pricePerCard'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String packageId;
  final String packageName;
  final int quantity;
  final double pricePerCard;
  final double totalAmount;

  Map<String, dynamic> toJson() {
    return {
      'packageId': packageId,
      'packageName': packageName,
      'quantity': quantity,
      'pricePerCard': pricePerCard,
      'totalAmount': totalAmount,
    };
  }
}
