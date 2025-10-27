import '../models/merchant.dart';

const List<Merchant> mockMerchants = [
  Merchant(
    id: 1,
    name: 'متجر النور للاتصالات',
    owner: 'علي أحمد الرومي',
    avatar: 'ع',
    phone: '777123456',
    location: 'صنعاء، الحصبة',
    balance: 15000,
    credit: 45000,
    debit: 30000,
    status: 'active',
    totalOrders: 45,
    monthlyOrders: 12,
    stock: 320,
  ),
  Merchant(
    id: 2,
    name: 'مؤسسة الفجر التجارية',
    owner: 'فاطمة محمد المحمدي',
    avatar: 'ف',
    phone: '733987654',
    location: 'تعز، التحرير',
    balance: -5000,
    credit: 25000,
    debit: 30000,
    status: 'active',
    totalOrders: 67,
    monthlyOrders: 18,
    stock: 140,
  ),
  Merchant(
    id: 3,
    name: 'شركة الأمل للتكنولوجيا',
    owner: 'محمد عبدالله الزبيدي',
    avatar: 'م',
    phone: '770456789',
    location: 'عدن، المعلا',
    balance: 25000,
    credit: 55000,
    debit: 30000,
    status: 'active',
    totalOrders: 89,
    monthlyOrders: 25,
    stock: 520,
  ),
  Merchant(
    id: 4,
    name: 'متجر الحكمة الذكي',
    owner: 'سارة أحمد الحدادي',
    avatar: 'س',
    phone: '777654321',
    location: 'صنعاء، شميلة',
    balance: 8500,
    credit: 38500,
    debit: 30000,
    status: 'pending',
    totalOrders: 34,
    monthlyOrders: 8,
    stock: 60,
  ),
  Merchant(
    id: 5,
    name: 'مركز الياسمين للاتصالات',
    owner: 'خالد سالم الأهدل',
    avatar: 'خ',
    phone: '733123789',
    location: 'الحديدة، كيلو 16',
    balance: -2000,
    credit: 18000,
    debit: 20000,
    status: 'suspended',
    totalOrders: 23,
    monthlyOrders: 5,
    stock: 25,
  ),
];

const List<Merchant> mockNewMerchants = [
  Merchant(
    id: 101,
    name: 'متجر المستقبل الحديث',
    owner: 'أروى خالد السماوي',
    avatar: 'أ',
    phone: '771112233',
    location: 'إب، الظهار',
    balance: 6400,
    credit: 26400,
    debit: 20000,
    status: 'active',
    totalOrders: 17,
    monthlyOrders: 6,
    stock: 78,
  ),
  Merchant(
    id: 102,
    name: 'حلويات السعادة',
    owner: 'سندس يحيى الورقي',
    avatar: 'س',
    phone: '735889900',
    location: 'صنعاء، التحرير',
    balance: 4200,
    credit: 24200,
    debit: 20000,
    status: 'pending',
    totalOrders: 11,
    monthlyOrders: 4,
    stock: 53,
  ),
  Merchant(
    id: 103,
    name: 'مكتبة الريادة',
    owner: 'منصور عبدالرحمن المؤيد',
    avatar: 'م',
    phone: '770998877',
    location: 'تعز، صينة',
    balance: -1200,
    credit: 18800,
    debit: 20000,
    status: 'active',
    totalOrders: 29,
    monthlyOrders: 9,
    stock: 112,
  ),
];

List<Merchant> searchNewMerchants(String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return const [];
  }
  return mockNewMerchants
      .where(
        (merchant) =>
            merchant.name.toLowerCase().contains(trimmed) ||
            merchant.owner.toLowerCase().contains(trimmed) ||
            merchant.location.toLowerCase().contains(trimmed),
      )
      .toList();
}
