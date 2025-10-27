class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.owner,
    required this.avatar,
    required this.phone,
    required this.location,
    required this.balance,
    required this.credit,
    required this.debit,
    required this.status,
    required this.totalOrders,
    required this.monthlyOrders,
    required this.stock,
    this.joinDate,
    this.lastTransaction,
  });

  final int id;
  final String name;
  final String owner;
  final String avatar;
  final String phone;
  final String location;
  final double balance;
  final double credit;
  final double debit;
  final String status;
  final int totalOrders;
  final int monthlyOrders;
  final int stock;
  final String? joinDate;
  final String? lastTransaction;
}
