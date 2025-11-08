import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';

/// صفحة الإحصائيات الشاملة للشبكة
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _isLoading = true;
  
  // إحصائيات الكروت
  int _totalImportedCards = 0;
  Map<String, Map<String, dynamic>> _transferredCardsPerVendor = {};
  
  // إحصائيات المعاملات
  int _totalOrders = 0;
  double _totalOrdersAmount = 0;
  int _totalPayments = 0;
  double _totalPaymentsAmount = 0;
  
  // أرصدة المتاجر
  Map<String, Map<String, dynamic>> _vendorBalances = {};
  double _totalBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';
    
    if (networkId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await Future.wait([
        _loadCardsStatistics(networkId),
        _loadTransactionsStatistics(networkId),
        _loadVendorBalances(networkId),
      ]);
      
      setState(() => _isLoading = false);
    } on Exception {
      setState(() => _isLoading = false);
    }
  }

  /// تحميل إحصائيات الكروت
  Future<void> _loadCardsStatistics(String networkId) async {
    final firestore = FirebaseFirestore.instance;
    
    // عدد الكروت المستوردة الإجمالي
    final importedCardsSnapshot = await firestore
        .collection('cards')
        .where('networkId', isEqualTo: networkId)
        .get();
    
    _totalImportedCards = importedCardsSnapshot.docs.length;
    
    // عدد الكروت المنقولة لكل متجر
    final transferredCardsSnapshot = await firestore
        .collection('vendor_cards')
        .where('networkId', isEqualTo: networkId)
        .get();
    
    final Map<String, Map<String, dynamic>> vendorCards = {};
    
    for (final doc in transferredCardsSnapshot.docs) {
      final data = doc.data();
      final vendorId = data['vendorId'] as String?;
      final vendorName = data['vendorName'] as String? ?? 'متجر';
      
      if (vendorId != null) {
        if (!vendorCards.containsKey(vendorId)) {
          vendorCards[vendorId] = {
            'name': vendorName,
            'count': 0,
          };
        }
        vendorCards[vendorId]!['count'] = 
            (vendorCards[vendorId]!['count'] as int) + 1;
      }
    }
    
    _transferredCardsPerVendor = vendorCards;
  }

  /// تحميل إحصائيات المعاملات
  Future<void> _loadTransactionsStatistics(String networkId) async {
    final firestore = FirebaseFirestore.instance;
    
    // إحصائيات الطلبات
    final ordersSnapshot = await firestore
        .collection('orders')
        .where('networkId', isEqualTo: networkId)
        .where('status', isEqualTo: 'approved')
        .get();
    
    _totalOrders = ordersSnapshot.docs.length;
    _totalOrdersAmount = ordersSnapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + ((doc.data()['totalAmount'] as num?)?.toDouble() ?? 0),
    );
    
    // إحصائيات الدفعات النقدية
    final paymentsSnapshot = await firestore
        .collection('cash_payment_requests')
        .where('networkId', isEqualTo: networkId)
        .where('status', isEqualTo: 'approved')
        .get();
    
    _totalPayments = paymentsSnapshot.docs.length;
    _totalPaymentsAmount = paymentsSnapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  /// تحميل أرصدة المتاجر
  Future<void> _loadVendorBalances(String networkId) async {
    final firestore = FirebaseFirestore.instance;
    
    // جلب جميع المعاملات حسب المتجر
    final transactionsSnapshot = await firestore
        .collection('transactions')
        .where('networkId', isEqualTo: networkId)
        .where('status', isEqualTo: 'completed')
        .get();
    
    final Map<String, Map<String, dynamic>> balances = {};
    
    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final vendorId = data['vendorId'] as String?;
      final vendorName = data['vendorName'] as String? ?? 'متجر';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final type = data['type'] as String?;
      
      if (vendorId != null) {
        if (!balances.containsKey(vendorId)) {
          balances[vendorId] = {
            'name': vendorName,
            'balance': 0.0,
          };
        }
        
        // حساب الرصيد
        if (type == 'cash_payment_received') {
          balances[vendorId]!['balance'] = 
              (balances[vendorId]!['balance'] as double) - amount.abs();
        } else if (amount > 0) {
          balances[vendorId]!['balance'] = 
              (balances[vendorId]!['balance'] as double) + amount;
        } else if (amount < 0) {
          balances[vendorId]!['balance'] = 
              (balances[vendorId]!['balance'] as double) + amount;
        }
      }
    }
    
    _vendorBalances = balances;
    _totalBalance = balances.values.fold<double>(
      0,
      (sum, vendor) => sum + (vendor['balance'] as double),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإحصائيات',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // إحصائيات الكروت
                      _buildSectionTitle('إحصائيات الكروت'),
                      SizedBox(height: 12.h),
                      _buildCardsStatistics(),
                      
                      SizedBox(height: 32.h),
                      
                      // إحصائيات المعاملات
                      _buildSectionTitle('المعاملات المالية'),
                      SizedBox(height: 12.h),
                      _buildTransactionsStatistics(),
                      
                      SizedBox(height: 32.h),
                      
                      // أرصدة المتاجر
                      _buildSectionTitle('المعاملات الآجلة للمتاجر'),
                      SizedBox(height: 12.h),
                      _buildVendorBalances(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          AppCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const SkeletonLine(width: double.infinity, height: 40),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          AppCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const SkeletonLine(width: double.infinity, height: 50),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          AppCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const SkeletonLine(width: double.infinity, height: 60),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTypography.subheadline.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildCardsStatistics() {
    return Column(
      children: [
        // إجمالي الكروت المستوردة
        AppCard(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.blue100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي الكروت المستوردة',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${NumberFormat('#,###', 'ar').format(_totalImportedCards)} كرت',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // الكروت المنقولة لكل متجر
        AppCard(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.send_outlined,
                    size: 18.w,
                    color: AppColors.gray700,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'الكروت المنقولة للمتاجر',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
              
              if (_transferredCardsPerVendor.isEmpty) ...[
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    'لا توجد كروت منقولة',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: 12.h),
                ..._transferredCardsPerVendor.entries.map((entry) {
                  final vendorName = entry.value['name'] as String;
                  final count = entry.value['count'] as int;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              vendorName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            vendorName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.gray700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###', 'ar').format(count)} كرت',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsStatistics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 18.w,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'الطلبات',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${NumberFormat('#,###', 'ar').format(_totalOrders)}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${NumberFormat('#,###', 'ar').format(_totalOrdersAmount)} ر.ي',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 18.w,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'الدفعات',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${NumberFormat('#,###', 'ar').format(_totalPayments)}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${NumberFormat('#,###', 'ar').format(_totalPaymentsAmount)} ر.ي',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorBalances() {
    // ترتيب المتاجر حسب الرصيد (الأكبر أولاً)
    final sortedVendors = _vendorBalances.entries.toList()
      ..sort((a, b) {
        final balanceA = a.value['balance'] as double;
        final balanceB = b.value['balance'] as double;
        return balanceB.compareTo(balanceA);
      });
    
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18.w,
                color: AppColors.gray700,
              ),
              SizedBox(width: 8.w),
              Text(
                'أرصدة المتاجر',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          
          if (sortedVendors.isEmpty) ...[
            SizedBox(height: 16.h),
            Center(
              child: Text(
                'لا توجد معاملات',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 12.h),
            ...sortedVendors.map((entry) {
              final vendorName = entry.value['name'] as String;
              final balance = entry.value['balance'] as double;
              
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.gray200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          vendorName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        vendorName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.gray800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${balance >= 0 ? '+' : ''}${NumberFormat('#,###', 'ar').format(balance)} ر.ي',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: balance > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            SizedBox(height: 8.h),
            Divider(color: AppColors.gray300, height: 1),
            SizedBox(height: 12.h),
            
            // إجمالي المعاملات الآجلة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي المعاملات الآجلة',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  '${_totalBalance >= 0 ? '+' : ''}${NumberFormat('#,###', 'ar').format(_totalBalance)} ر.ي',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _totalBalance > 0 ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

