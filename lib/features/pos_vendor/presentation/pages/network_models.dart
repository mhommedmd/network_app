import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NetworkInfo {
  const NetworkInfo({
    required this.id,
    required this.name,
    required this.owner,
    required this.activeUsers,
    required this.color,
    required this.city,
  });
  final int id;
  final String name;
  final String owner;
  final int activeUsers;
  final Color color;
  final String city; // City / Governorate
}

// Mock master list (could be replaced by repository later)
const List<NetworkInfo> kAllNetworks = [
  NetworkInfo(
    id: 1,
    name: 'شبكة النور',
    owner: 'محمد السالم',
    activeUsers: 120,
    color: AppColors.primary,
    city: 'صنعاء',
  ),
  NetworkInfo(
    id: 2,
    name: 'شبكة السرعة',
    owner: 'أحمد القحطاني',
    activeUsers: 95,
    color: AppColors.success,
    city: 'عدن',
  ),
  NetworkInfo(
    id: 3,
    name: 'شبكة الأفق',
    owner: 'سعيد الغامدي',
    activeUsers: 60,
    color: Colors.indigo,
    city: 'تعز',
  ),
  NetworkInfo(
    id: 4,
    name: 'شبكة المستقبل',
    owner: 'خالد العتيبي',
    activeUsers: 210,
    color: Colors.orange,
    city: 'حضرموت',
  ),
  NetworkInfo(
    id: 5,
    name: 'شبكة النخبة',
    owner: 'ياسر المالكي',
    activeUsers: 45,
    color: Colors.purple,
    city: 'إب',
  ),
  NetworkInfo(
    id: 6,
    name: 'شبكة برج المدينة',
    owner: 'عبدالله العمري',
    activeUsers: 300,
    color: AppColors.error,
    city: 'صنعاء',
  ),
];
