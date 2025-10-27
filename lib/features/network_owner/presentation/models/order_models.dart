class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.owner,
    required this.avatar,
    required this.phone,
    required this.location,
  });

  final String id;
  final String name;
  final String owner;
  final String avatar;
  final String phone;
  final String location;
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.packageName,
    required this.dataSize,
    required this.validity,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.availableStock,
  });

  final int id;
  final String packageName;
  final String dataSize;
  final String validity;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int availableStock;

  bool get isAvailable => availableStock >= quantity;
}

class OrderDetails {
  const OrderDetails({
    required this.id,
    required this.vendor,
    required this.timestamp,
    required this.status,
    required this.items,
  });

  final int id;
  final Vendor vendor;
  final String timestamp;
  final String status;
  final List<OrderItem> items;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  bool get hasInsufficientStock => items.any((item) => !item.isAvailable);
  bool get allItemsAvailable => items.every((item) => item.isAvailable);

  OrderItem? get primaryItem => items.isEmpty ? null : items.first;

  int get totalAvailableStock =>
      items.fold(0, (sum, item) => sum + item.availableStock);
}
