import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_tab_bar.dart';
import '../../../../shared/widgets/packages/package_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../../network_owner/data/models/package_model.dart';
import '../../../network_owner/data/services/firebase_package_service.dart';
import '../../data/models/vendor_transaction_model.dart';
import '../../data/services/firebase_vendor_inventory_service.dart';
import '../../data/services/firebase_vendor_transaction_service.dart';
import 'send_order_page.dart';

typedef NetworkActionCallback = void Function(String networkId, String? networkName);

// مساعد لتحليل الألوان - مع caching للأداء
class ColorParser {
  static final Map<String, Color?> _cache = {};
  
  static const _colorMap = <String, Color>{
    'blue': AppColors.primary,
    'green': AppColors.success,
    'orange': AppColors.warning,
    'red': AppColors.error,
    'purple': Colors.purple,
    'teal': Colors.teal,
  };

  static Color? tryParse(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    
    // استخدام cache للألوان المحولة
    final key = colorString.toLowerCase();
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    
    final color = _colorMap[key];
    _cache[key] = color;
    return color;
  }
}

class NetworkDetailsPage extends StatefulWidget {
  const NetworkDetailsPage({
    required this.networkId,
    this.networkOwnerId,
    this.networkName,
    super.key,
    this.onBack,
    this.onSendOrder,
    this.onOpenChat,
  });
  final String networkId;
  final String? networkOwnerId;
  final String? networkName;
  final VoidCallback? onBack;
  final NetworkActionCallback? onSendOrder;
  final NetworkActionCallback? onOpenChat;

  @override
  State<NetworkDetailsPage> createState() => _NetworkDetailsPageState();
}

class _NetworkDetailsPageState extends State<NetworkDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSendOrder() {
    final networkOwnerId = widget.networkOwnerId ?? widget.networkId;

    if (networkOwnerId.isEmpty) {
      CustomToast.error(
        context,
        'يرجى التأكد من الاتصال بالشبكة',
        title: 'معلومات غير متوفرة',
      );
      return;
    }

    // استدعاء الـ callback إن وجد (مثلاً عند الاستخدام داخل MainLayout)
    if (widget.onSendOrder != null) {
      widget.onSendOrder!(networkOwnerId, widget.networkName);
      return;
    }

    // خلاف ذلك، ننتقل إلى صفحة إرسال الطلب التقليدية
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SendOrderPage(
          networkId: networkOwnerId,
          networkName: widget.networkName ?? 'الشبكة',
        ),
      ),
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام networkOwnerId للحصول على الباقات
    // إذا لم يكن موجوداً، نستخدم networkId ذاته (تم تمريره كسلسلة)
    final networkOwnerId = widget.networkOwnerId ?? widget.networkId;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleSendOrder,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إرسال طلب', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _handleBack,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 36.w,
                        height: 36.w,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'تفاصيل الشبكة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppPrimaryTabBar(
                  controller: _tabController,
                  style: AppTabBarStyle.filledSegment,
                  isDense: true,
                  indicatorColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  enableBlur: false,
                  tabs: const [
                    AppPrimaryTab(label: 'الباقات'),
                    AppPrimaryTab(label: 'المعاملات'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPackagesTab(networkOwnerId),
                    _buildTransactionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackagesTab(String networkOwnerId) {
    final vendorId = context.read<AuthProvider>().user?.id ?? '';

    return StreamBuilder<List<PackageModel>>(
      stream: FirebasePackageService.getActivePackagesByNetwork(networkOwnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const SkeletonPackageCard(),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                  SizedBox(height: 16.h),
                  Text(
                    'خطأ في تحميل الباقات',
                    style: TextStyle(fontSize: 16.sp, color: AppColors.gray900),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12.sp, color: AppColors.gray600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final packages = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: packages.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: AppCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_outlined,
                                size: 64.w, color: AppColors.gray400,),
                            SizedBox(height: 16.h),
                            Text(
                              'لا توجد باقات',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'هذه الشبكة لم تضف أي باقات بعد',
                              style: TextStyle(
                                  fontSize: 14.sp, color: AppColors.gray600,),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : FutureBuilder<Map<String, int>>(
                  future: FirebaseVendorInventoryService.getVendorPackageStock(
                    vendorId: vendorId,
                    networkId: networkOwnerId,
                  ),
                  builder: (context, stockSnapshot) {
                    final packageStock = stockSnapshot.data ?? {};

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 16.h,),
                      child: Column(
                        children: packages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final pkg = entry.value;
                          final totalMb = pkg.dataSizeMB > 0
                              ? pkg.dataSizeMB
                              : pkg.dataSizeGB * 1024;

                          // الحصول على مخزون المتجر لهذه الباقة
                          final vendorStock = packageStock[pkg.id] ?? 0;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: PackageCard(
                              data: PackageCardData(
                                name: pkg.name,
                                sizeInMb: totalMb,
                                validityDays: pkg.validityDays,
                                usageWindowHours: pkg.usageHours,
                                retailPrice: pkg.sellingPrice,
                                wholesalePrice: pkg.purchasePrice,
                                quantityAvailable: vendorStock, // مخزون المتجر
                                type: PackageType
                                    .values[index % PackageType.values.length],
                                accentColor: ColorParser.tryParse(pkg.color),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    final vendorId = context.read<AuthProvider>().user?.id ?? '';
    final networkOwnerId = widget.networkOwnerId ?? widget.networkId;

    if (vendorId.isEmpty) {
      return const Center(child: Text('معلومات المستخدم غير متوفرة'));
    }

    return StreamBuilder<List<VendorTransactionModel>>(
      stream: FirebaseVendorTransactionService.getVendorNetworkTransactions(
        vendorId: vendorId,
        networkId: networkOwnerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Skeleton for balance card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLine(width: 80),
                      SizedBox(height: 6.h),
                      const SkeletonLine(width: 120, height: 24),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          const Expanded(
                            child: SkeletonBox(height: 70, borderRadius: 10),
                          ),
                          SizedBox(width: 10.w),
                          const Expanded(
                            child: SkeletonBox(height: 70, borderRadius: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // Skeleton transactions
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: const SkeletonTransactionCard(),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          final errorMessage = ErrorHandler.extractErrorMessage(snapshot.error);
          return Center(
            child: AppCard(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                  SizedBox(height: 16.h),
                  Text(
                    'خطأ في تحميل المعاملات',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.gray600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        return FutureBuilder<Map<String, double>>(
          future: FirebaseVendorTransactionService.getAccountSummary(
            vendorId: vendorId,
            networkId: networkOwnerId,
          ),
          builder: (context, summarySnapshot) {
            final summary = summarySnapshot.data ?? {};
            final balance = summary['balance'] ?? 0;
            final totalCharges = summary['totalCharges'] ?? 0;
            final totalPayments = summary['totalPayments'] ?? 0;

            return RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                children: [
                  // Balance and totals (نفس تصميم merchant_transactions_page)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الرصيد الحالي',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.gray600,),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${balance >= 0 ? '+' : ''}${_formatNumber(balance)}',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: balance > 0
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.symbol,
                              style: TextStyle(
                                  fontSize: 12.sp, color: AppColors.gray500,),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 12.w,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_down,
                                          size: 14.w,
                                          color: AppColors.error,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'المستحقات',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _formatNumber(totalCharges),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 12.w,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          size: 14.w,
                                          color: AppColors.success,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'المدفوعات',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _formatNumber(totalPayments),
                                      style: TextStyle(
                                        fontSize: 14.sp,
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
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المعاملات (${transactions.length})',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Transactions list (نفس تصميم merchant_transactions_page)
                  ...transactions.map(
                    (t) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _TransactionRow(transaction: t),
                    ),
                  ),

                  if (transactions.isEmpty)
                    AppCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 28.w,
                            color: AppColors.gray400,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'لا توجد معاملات',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'لم يتم تسجيل أي معاملات بعد',
                            style: TextStyle(
                                fontSize: 12.sp, color: AppColors.gray600,),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'ar');
    return formatter.format(number);
  }
}

/// بطاقة عرض المعاملة (نفس تصميم merchant_transactions_page)
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final VendorTransactionModel transaction;

  IconData _getTypeIcon() {
    // payment (دفعة نقدية) = أخضر / موجب
    // charge (طلب كروت) = أحمر / سالب
    if (transaction.isDebit) {
      return Icons.trending_down; // charge/سالب
    } else {
      return Icons.trending_up; // payment/موجب
    }
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'ar');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    // المنطق الجديد:
    // charge (طلب كروت) = سالب/أحمر
    // payment (دفعة نقدية) = موجب/أخضر
    final isPayment = !transaction.isDebit; // payment = true, charge = false
    final amountColor = isPayment ? AppColors.success : AppColors.error;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _getTypeIcon(),
              size: 20.w,
              color: amountColor,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                  style: TextStyle(fontSize: 11.sp, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPayment ? '+' : '-'}${_formatNumber(transaction.amount)}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              Text(
                CurrencyFormatter.symbol,
                style: TextStyle(fontSize: 11.sp, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
