import '../models/order_models.dart';

final List<OrderDetails> mockOrders = [
  const OrderDetails(
    id: 101,
    vendor: Vendor(
      id: 'vendor1',
      name: 'متجر الرقمية التقنية',
      owner: 'علي سالم الرومي',
      avatar: 'ع',
      phone: '+967 773 123 456',
      location: 'صنعاء، شارع الزبيري',
    ),
    timestamp: 'منذ 15 دقيقة',
    status: 'pending',
    items: [
      OrderItem(
        id: 1,
        packageName: 'باقة يومية ممتازة',
        dataSize: '5 جيجا',
        validity: '7 أيام',
        quantity: 20,
        unitPrice: 50,
        totalPrice: 1000,
        availableStock: 25,
      ),
      OrderItem(
        id: 2,
        packageName: 'باقة أسبوعية مميزة',
        dataSize: '10 جيجا',
        validity: '30 يوم',
        quantity: 10,
        unitPrice: 150,
        totalPrice: 1500,
        availableStock: 8,
      ),
      OrderItem(
        id: 3,
        packageName: 'باقة شهرية اقتصادية',
        dataSize: '20 جيجا',
        validity: '30 يوم',
        quantity: 5,
        unitPrice: 400,
        totalPrice: 2000,
        availableStock: 12,
      ),
    ],
  ),
  const OrderDetails(
    id: 102,
    vendor: Vendor(
      id: 'vendor2',
      name: 'مؤسسة الفجر التجارية',
      owner: 'فاطمة محمد المحمدي',
      avatar: 'ف',
      phone: '+967 733 987 654',
      location: 'تعز، التحرير',
    ),
    timestamp: 'منذ 30 دقيقة',
    status: 'pending',
    items: [
      OrderItem(
        id: 4,
        packageName: 'باقة تواصل أسبوعية',
        dataSize: '8 جيجا',
        validity: '14 يوم',
        quantity: 15,
        unitPrice: 120,
        totalPrice: 1800,
        availableStock: 20,
      ),
      OrderItem(
        id: 5,
        packageName: 'باقة سوشال يومية',
        dataSize: '3 جيجا',
        validity: '3 أيام',
        quantity: 25,
        unitPrice: 45,
        totalPrice: 1125,
        availableStock: 18,
      ),
    ],
  ),
  const OrderDetails(
    id: 103,
    vendor: Vendor(
      id: 'vendor3',
      name: 'شركة الأمل للتكنولوجيا',
      owner: 'محمد عبدالله الزبيدي',
      avatar: 'م',
      phone: '+967 770 456 789',
      location: 'عدن، المعلا',
    ),
    timestamp: 'منذ ساعة',
    status: 'pending',
    items: [
      OrderItem(
        id: 6,
        packageName: 'باقة بيانات شهرية',
        dataSize: '30 جيجا',
        validity: '30 يوم',
        quantity: 12,
        unitPrice: 320,
        totalPrice: 3840,
        availableStock: 10,
      ),
      OrderItem(
        id: 7,
        packageName: 'باقة أعمال مميزة',
        dataSize: '50 جيجا',
        validity: '60 يوم',
        quantity: 8,
        unitPrice: 550,
        totalPrice: 4400,
        availableStock: 6,
      ),
    ],
  ),
];

OrderDetails? findMockOrderById(int id) {
  for (final order in mockOrders) {
    if (order.id == id) {
      return order;
    }
  }
  return null;
}
