import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/services/firebase_transaction_service.dart';
import '../../data/services/firebase_vendor_service.dart';

class MerchantTransactionsPage extends StatefulWidget {
  const MerchantTransactionsPage({
    required this.vendorId,
    required this.onBack,
    super.key,
  });
  final String vendorId;
  final VoidCallback onBack;

  @override
  State<MerchantTransactionsPage> createState() =>
      _MerchantTransactionsPageState();
}

class _MerchantTransactionsPageState extends State<MerchantTransactionsPage> {
  VendorModel? _vendor;
  Map<String, dynamic>? _accountSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id;

    if (networkId == null) {
      setState(() {
        _error = 'لا يوجد مستخدم مسجل دخول';
        _isLoading = false;
      });
      return;
    }

    try {
      // تحميل بيانات المتجر
      final vendor = await FirebaseVendorService.getVendor(widget.vendorId);

      // تحميل ملخص الحساب
      final summary = await FirebaseTransactionService.getAccountSummary(
        vendorId: widget.vendorId,
        networkId: networkId,
      );

      setState(() {
        _vendor = vendor;
        _accountSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'charge':
        return Icons.trending_up;
      case 'payment':
        return Icons.trending_down;
      case 'refund':
        return Icons.refresh;
      case 'fee':
        return Icons.receipt;
      case 'adjustment':
        return Icons.timeline;
      default:
        return Icons.description;
    }
  }

  // removed unused labels mapping after simplification

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'ar');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('معاملات المتجر'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
          backgroundColor: AppColors.primary,
          surfaceTintColor: AppColors.primary,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Skeleton for merchant info
              const SkeletonCardWithIcon(),
              SizedBox(height: 12.h),
              // Skeleton for balance card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLine(width: 80, height: 12),
                    SizedBox(height: 6.h),
                    const SkeletonLine(width: 120, height: 24),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonBox(
                            height: 70,
                            borderRadius: 10,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: SkeletonBox(
                            height: 70,
                            borderRadius: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Skeleton for transactions header
              Align(
                alignment: Alignment.centerRight,
                child: SkeletonLine(width: 100, height: 14),
              ),
              SizedBox(height: 8.h),
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
        ),
      );
    }

    if (_error != null || _vendor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('معاملات المتجر'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
          backgroundColor: AppColors.primary,
          surfaceTintColor: AppColors.primary,
        ),
        body: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                SizedBox(height: 16.h),
                Text(
                  _error ?? 'لم يتم العثور على المتجر',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.gray700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _vendor!.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: FirebaseTransactionService.getTransactionsByVendor(
          vendorId: widget.vendorId,
          networkId: networkId,
        ),
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              await _loadVendorData();
            },
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              children: [
                // معلومات المتجر الأساسية
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            _vendor!.avatar,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _vendor!.name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 14.w, color: AppColors.gray500),
                                SizedBox(width: 4.w),
                                Text(
                                  _vendor!.ownerName,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.phone,
                                    size: 14.w, color: AppColors.gray500),
                                SizedBox(width: 4.w),
                                Text(
                                  _vendor!.phone,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Balance and totals
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرصيد الحالي',
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.gray600),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_vendor!.balance >= 0 ? '+' : ''}${_formatNumber(_vendor!.balance)}',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: _vendor!.balance >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.symbol,
                            style: TextStyle(
                                fontSize: 12.sp, color: AppColors.gray500),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      if (_accountSummary != null) ...[
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
                                      _formatNumber(
                                          _accountSummary!['totalCharges']
                                                  as double? ??
                                              0),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.successDark,
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
                                      AppColors.primary.withValues(alpha: 0.08),
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
                                          color: AppColors.primary,
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
                                      _formatNumber(
                                          _accountSummary!['totalPayments']
                                                  as double? ??
                                              0),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

                // Transactions list
                ...transactions.map(
                  (t) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _TransactionRow(
                      transaction: t,
                      getTypeIcon: _getTypeIcon,
                      formatNumber: _formatNumber,
                    ),
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
                              fontSize: 12.sp, color: AppColors.gray600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.getTypeIcon,
    required this.formatNumber,
  });

  final TransactionModel transaction;
  final IconData Function(String type) getTypeIcon;
  final String Function(double number) formatNumber;

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    final amountColor = isPositive ? AppColors.success : AppColors.error;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              getTypeIcon(transaction.type),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaction.reference,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    const Text('•', style: TextStyle(color: AppColors.gray300)),
                    SizedBox(width: 6.w),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                      style:
                          TextStyle(fontSize: 11.sp, color: AppColors.gray500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${formatNumber(transaction.amount)}',
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
