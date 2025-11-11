import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Theme & shared UI
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/providers/card_provider.dart';
import '../../data/services/firebase_notification_service.dart';
import '../../data/services/firebase_order_service.dart';
import '../../data/services/firebase_transaction_service.dart';
import '../../data/services/firebase_vendor_service.dart';
import 'cash_payment_page.dart';
import 'network_page.dart';
import 'network_stored_page.dart';
import 'notifications_page.dart';
import 'statistics_page.dart';

class NetworkOwnerHomePage extends StatelessWidget {
  const NetworkOwnerHomePage({
    super.key,
    this.onAddPackage,
    this.onImportCards,
    this.onAddMerchant,
    this.onNotificationsTap,
    this.onVendorTap,
    this.onViewInventory,
    this.onRecordCashPayment,
    this.networkName,
    this.ownerName,
    this.avatarUrl,
  });
  final VoidCallback? onAddPackage;
  final VoidCallback? onImportCards;
  final VoidCallback? onAddMerchant;
  final VoidCallback? onNotificationsTap;
  final StringCallback? onVendorTap;
  final VoidCallback? onViewInventory;
  final VoidCallback? onRecordCashPayment;
  final String? networkName;
  final String? ownerName;
  final String? avatarUrl;

  /// التحقق من صحة URL
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthProvider p) => p.user);
    final displayNetworkName = networkName ?? user?.networkName ?? user?.name ?? 'شبكة افاق نت';
    final displayOwnerName = ownerName ?? user?.name ?? 'المالك';

    final handleCashPayment = onRecordCashPayment ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NetworkCashPaymentPage(
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            );
    final handleInventoryTap = onViewInventory ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NetworkStoredPage(),
              ),
            );
    final handleNotificationsTap = onNotificationsTap ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsPage(
                  onNavigate: (action, data) {
                    // التنقل حسب نوع الإشعار
                    Navigator.of(context).pop(); // إغلاق صفحة الإشعارات أولاً

                    // حالياً: لا نقوم بأي تنقل إضافي
                    // يمكن إضافة تنقل لصفحة محددة لاحقاً إذا لزم الأمر
                  },
                ),
              ),
            );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(72.h),
        child: Container(
          padding: EdgeInsets.only(top: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C2B33).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24.w,
                    backgroundColor: const Color(0xFF0082FB).withOpacity(0.1),
                    backgroundImage: _isValidUrl(avatarUrl) ? NetworkImage(avatarUrl!) : null,
                    child: !_isValidUrl(avatarUrl)
                        ? Icon(
                            Icons.person,
                            color: const Color(0xFF0082FB),
                            size: 24.w,
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayNetworkName,
                          style: TextStyle(
                            color: const Color(0xFF1C2B33),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'مرحباً، $displayOwnerName',
                          style: TextStyle(
                            color: const Color(0xFF1C2B33).withOpacity(0.7),
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: FirebaseNotificationService.getUnreadCount(
                      user?.id ?? '',
                    ),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return IconButton(
                        onPressed: handleNotificationsTap,
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: const Color(0xFF0082FB),
                              size: 26.w,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: const BoxDecoration(
                                    color: AppColors.errorLight,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 18.w,
                                    minHeight: 18.w,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrimaryStatsSection(onViewInventory: handleInventoryTap),
                SizedBox(height: 32.h),
                _QuickActionsGrid(
                  onAddPackage: onAddPackage,
                  onImportCards: onImportCards,
                  onAddMerchant: onAddMerchant,
                  onRecordCashPayment: handleCashPayment,
                  onViewOrders: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NetworkOrdersPage(),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                _RecentOrdersSection(),
                SizedBox(height: 40.h),
                _MostActiveVendorsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quick actions as icon + label (centered)
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    this.onAddPackage,
    this.onImportCards,
    this.onAddMerchant,
    this.onRecordCashPayment,
    this.onViewOrders,
  });
  final VoidCallback? onAddPackage;
  final VoidCallback? onImportCards;
  final VoidCallback? onAddMerchant;
  final VoidCallback? onRecordCashPayment;
  final VoidCallback? onViewOrders;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionData>[
      if (onRecordCashPayment != null)
        _ActionData(
          icon: Icons.payments_outlined,
          label: 'دفعة نقدية',
          onTap: onRecordCashPayment!,
        ),
      _ActionData(
        icon: Icons.bar_chart_outlined,
        label: 'الإحصائيات',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const StatisticsPage(),
          ),
        ),
      ),
      if (onViewOrders != null)
        _ActionData(
          icon: Icons.receipt_long_outlined,
          label: 'الطلبات',
          onTap: onViewOrders!,
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map(
            (it) => _QuickActionIcon(data: it),
          )
          .toList(),
    );
  }
}

class _ActionData {
  _ActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionIcon extends StatelessWidget {
  const _QuickActionIcon({required this.data});
  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              data.icon,
              size: 24.r,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data.label,
            style: AppTypography.caption.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStatsSection extends StatefulWidget {
  const _PrimaryStatsSection({this.onViewInventory});

  final VoidCallback? onViewInventory;

  @override
  State<_PrimaryStatsSection> createState() => _PrimaryStatsSectionState();
}

class _PrimaryStatsSectionState extends State<_PrimaryStatsSection> {
  int _totalStock = 0;
  double _totalSales = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // تحميل إحصائيات الكروت
      await cardProvider.loadStats(networkId);

      // حساب إجمالي المبيعات من المعاملات
      final salesData = await FirebaseTransactionService.getTotalSales(networkId);

      if (mounted) {
        final stats = cardProvider.stats;
        final availableCards = (stats?['availableCards'] as int?) ?? 0;

        // استخدام WidgetsBinding لتجنب setState أثناء البناء
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _totalStock = availableCards;
              _totalSales = salesData;
              _isLoading = false;
            });
          }
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final handleInventoryTap = widget.onViewInventory ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NetworkStoredPage(),
              ),
            );

    if (_isLoading) {
      return Row(
        children: [
          Expanded(
            child: AppCard(
              variant: AppCardVariant.glass,
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 100),
                  SizedBox(height: 6.h),
                  const SkeletonLine(width: 150, height: 16),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppCard(
              variant: AppCardVariant.glass,
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 100),
                  SizedBox(height: 6.h),
                  const SkeletonLine(width: 150, height: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            data: _StatData(
              title: 'إجمالي الإيرادات',
              value: '${NumberFormat('#,###', 'ar').format(_totalSales)} ر.ي',
              valueColor: AppColors.success,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatCard(
            data: _StatData(
              title: 'المخزون المتبقي',
              value: '${NumberFormat('#,###', 'ar').format(_totalStock)} كرت',
              valueColor: AppColors.warningDark,
              onTap: handleInventoryTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    this.valueColor = AppColors.gray900,
    this.onTap,
  });
  final String title;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: data.onTap,
      variant: AppCardVariant.glass,
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: AppTypography.caption.copyWith(
              fontSize: 12.sp,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            data.value,
            style: AppTypography.body.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: data.valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم الطلبات الأخيرة
class _RecentOrdersSection extends StatefulWidget {
  @override
  State<_RecentOrdersSection> createState() => _RecentOrdersSectionState();
}

class _RecentOrdersSectionState extends State<_RecentOrdersSection> {
  List<OrderModel> _orders = [];
  Map<String, VendorModel> _vendorsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // استخدام addPostFrameCallback لتجنب setState أثناء البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadOrders();
      }
    });
  }

  void _loadOrders() {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    // تحميل المتاجر أولاً
    FirebaseVendorService.getVendorsByNetwork(networkId).listen(
      (vendors) {
        if (mounted) {
          setState(() {
            // استخدام realUserId كمفتاح لأن order.vendorId يحتوي على userId الحقيقي
            _vendorsMap = {for (final v in vendors) v.realUserId: v};
          });
        }
      },
      onError: (error) {
        // معالجة الخطأ بصمت
        if (mounted) {
          setState(() => _vendorsMap = {});
        }
      },
    );

    // تحميل الطلبات
    FirebaseOrderService.getNetworkOrders(networkId).listen(
      (orders) {
        if (mounted) {
          setState(() {
            // أخذ آخر 5 طلبات فقط
            _orders = orders.take(5).toList();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _orders = [];
          });
        }
      },
    );
  }

  void _navigateToOrdersPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NetworkOrdersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 22.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  'الطلبات الأخيرة',
                  style: AppTypography.subheadline.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
            if (_orders.isNotEmpty)
              TextButton(
                onPressed: _navigateToOrdersPage,
                child: Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),

        // عرض Skeleton أثناء التحميل
        if (_isLoading)
          ...List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AppCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SkeletonBox(width: 40, height: 40, borderRadius: 12),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SkeletonLine(width: 120, height: 14),
                              SizedBox(height: 6.h),
                              const SkeletonLine(width: 80),
                            ],
                          ),
                        ),
                        const SkeletonBox(width: 60, height: 24, borderRadius: 8),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLine(width: 80),
                        SkeletonLine(width: 100),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        // عرض الطلبات
        else if (_orders.isEmpty)
          AppCard(
            padding: EdgeInsets.all(24.w),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48.r,
                    color: AppColors.gray400,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'لا توجد طلبات حالياً',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._orders.map((order) {
            final vendor = _vendorsMap[order.vendorId];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _OrderCard(
                order: order,
                vendor: vendor,
                onTap: _navigateToOrdersPage,
              ),
            );
          }),
      ],
    );
  }
}

/// بطاقة الطلب المختصرة
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.vendor,
    required this.onTap,
  });

  final OrderModel order;
  final VendorModel? vendor;
  final VoidCallback onTap;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // أيقونة المتجر
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.blue100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: vendor != null
                    ? Center(
                        child: Text(
                          vendor!.avatar,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: AppColors.primary,
                        size: 20.w,
                      ),
              ),
              SizedBox(width: 12.w),
              // اسم المتجر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor?.name ?? 'متجر غير معروف',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      DateFormat('dd/MM/yyyy', 'ar').format(order.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              // حالة الطلب
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14.w,
                      color: statusColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // تفاصيل الطلب
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // عدد الكروت
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 14.w,
                    color: AppColors.gray500,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${order.totalCards} كرت',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
              // القيمة الإجمالية
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 14.w,
                    color: AppColors.gray500,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${NumberFormat('#,###', 'ar').format(order.totalAmount)} ر.ي',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// قسم المتاجر الأكثر نشاطاً
class _MostActiveVendorsSection extends StatefulWidget {
  @override
  State<_MostActiveVendorsSection> createState() => _MostActiveVendorsSectionState();
}

class _MostActiveVendorsSectionState extends State<_MostActiveVendorsSection> {
  List<Map<String, dynamic>> _topVendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTopVendors();
      }
    });
  }

  Future<void> _loadTopVendors() async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // جلب جميع المتاجر
      final vendorsSnapshot = await FirebaseVendorService.getVendorsByNetwork(networkId).first;

      // حساب النشاط لكل متجر (عدد الطلبات + عدد الدفعات)
      final vendorActivities = <Map<String, dynamic>>[];

      for (final vendor in vendorsSnapshot) {
        // عدد الطلبات
        final ordersSnapshot = await firestore
            .collection('orders')
            .where('vendorId', isEqualTo: vendor.realUserId)
            .where('networkId', isEqualTo: networkId)
            .get();

        // عدد الدفعات
        final paymentsSnapshot = await firestore
            .collection('cash_payment_requests')
            .where('vendorId', isEqualTo: vendor.realUserId)
            .where('networkId', isEqualTo: networkId)
            .get();

        final totalActivity = ordersSnapshot.docs.length + paymentsSnapshot.docs.length;

        // حساب الرصيد من transactions
        final transactionsSnapshot = await firestore
            .collection('transactions')
            .where('vendorId', isEqualTo: vendor.realUserId)
            .where('networkId', isEqualTo: networkId)
            .where('status', isEqualTo: 'completed')
            .get();

        double balance = 0;
        for (final doc in transactionsSnapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final type = data['type'] as String?;

          if (type == 'cash_payment_received') {
            balance -= amount.abs();
          } else if (amount > 0) {
            balance += amount;
          } else if (amount < 0) {
            balance += amount;
          }
        }

        // حساب المخزون
        final cardsSnapshot = await firestore
            .collection('vendor_cards')
            .where('vendorId', isEqualTo: vendor.realUserId)
            .where('networkId', isEqualTo: networkId)
            .where('status', isEqualTo: 'available')
            .get();

        vendorActivities.add({
          'vendor': vendor,
          'activity': totalActivity,
          'ordersCount': ordersSnapshot.docs.length,
          'paymentsCount': paymentsSnapshot.docs.length,
          'balance': balance,
          'stock': cardsSnapshot.docs.length,
        });
      }

      // ترتيب حسب النشاط (الأكثر نشاطاً أولاً)
      vendorActivities.sort((a, b) => (b['activity'] as int).compareTo(a['activity'] as int));

      // أخذ أول 3 متاجر فقط
      final top3 = vendorActivities.take(3).toList();

      if (mounted) {
        setState(() {
          _topVendors = top3;
          _isLoading = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.primary,
                  size: 22.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  'المتاجر الأكثر نشاطاً',
                  style: AppTypography.subheadline.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_isLoading)
          ...List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AppCard(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    const SkeletonBox(width: 46, height: 46, borderRadius: 12),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLine(width: 120, height: 14),
                          SizedBox(height: 6.h),
                          const SkeletonLine(width: 80),
                        ],
                      ),
                    ),
                    const SkeletonBox(width: 60, height: 30, borderRadius: 8),
                  ],
                ),
              ),
            ),
          )
        else if (_topVendors.isEmpty)
          AppCard(
            padding: EdgeInsets.all(24.w),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 48.r,
                    color: AppColors.gray400,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'لا توجد متاجر نشطة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._topVendors.map((vendorData) {
            final vendor = vendorData['vendor'] as VendorModel;
            final balance = vendorData['balance'] as double;
            final stock = vendorData['stock'] as int;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _ActiveVendorTile(
                vendor: vendor,
                balance: balance,
                stock: stock,
              ),
            );
          }),
      ],
    );
  }
}

/// بطاقة عرض المتجر النشط (نفس التصميم من accounts_page)
class _ActiveVendorTile extends StatelessWidget {
  const _ActiveVendorTile({
    required this.vendor,
    required this.balance,
    required this.stock,
  });

  final VendorModel vendor;
  final double balance;
  final int stock;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          // الأفاتار
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                vendor.avatar,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // معلومات المتجر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vendor.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 12.w, color: AppColors.gray500),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        vendor.ownerName,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.phone, size: 11.w, color: AppColors.gray500),
                    SizedBox(width: 3.w),
                    Text(
                      vendor.phone,
                      style: TextStyle(fontSize: 10.sp, color: AppColors.gray600),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11.w, color: AppColors.gray500),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        '${vendor.governorate}${vendor.district.isNotEmpty ? ' - ${vendor.district}' : ''}${vendor.address.isNotEmpty ? ' - ${vendor.address}' : ''}',
                        style: TextStyle(fontSize: 10.sp, color: AppColors.gray600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // الإحصائيات
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // الرصيد
              Text(
                '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: balance > 0 ? AppColors.error : AppColors.success,
                ),
              ),
              Text(
                'ر.ي',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              // المخزون
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.blue100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$stock كرت',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
