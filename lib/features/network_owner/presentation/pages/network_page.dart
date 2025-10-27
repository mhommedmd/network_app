import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_tab_bar.dart';
import '../../../../shared/widgets/packages/package_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/order_model.dart';
import '../../data/providers/package_provider.dart';
import '../../data/services/firebase_order_service.dart';
import '../widgets/order_card.dart' as order_widget;

class ColorParser {
  static Color? tryParse(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    switch (colorString.toLowerCase()) {
      case 'blue':
        return AppColors.primary;
      case 'green':
        return AppColors.success;
      case 'red':
        return AppColors.error;
      case 'orange':
        return AppColors.warning;
      case 'purple':
        return const Color(0xFF8b5cf6);
      case 'pink':
        return const Color(0xFFec4899);
      case 'yellow':
        return const Color(0xFFeab308);
      case 'cyan':
        return const Color(0xFF06b6d4);
      case 'gray':
      case 'grey':
        return AppColors.gray500;
      case 'black':
        return AppColors.gray900;
      default:
        return null;
    }
  }
}

class NetworkPage extends StatelessWidget {
  const NetworkPage({
    super.key,
    this.onAddPackage,
    this.onEditPackage,
    this.onImportCards,
    this.onViewOrderDetails,
    this.onApproveOrder,
    this.onRejectOrder,
    this.newPackage,
    this.updatedPackage,
    this.networkName,
    this.initialTabIndex = 0,
  });
  final VoidCallback? onAddPackage;
  final JsonMapCallback? onEditPackage;
  final VoidCallback? onImportCards;
  final IntCallback? onViewOrderDetails;
  final IntCallback? onApproveOrder;
  final IntCallback? onRejectOrder;
  final JsonMap? newPackage;
  final JsonMap? updatedPackage;
  final String? networkName;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // استخدام اسم الشبكة أولاً، ثم اسم المستخدم كـ fallback
    final user = authProvider.user;
    final registeredNetworkName = user?.networkName?.trim();
    final registeredUserName = user?.name.trim();
    final fallbackName = networkName?.trim().isNotEmpty == true
        ? networkName!.trim()
        : 'اسم الشبكة';

    final displayName =
        registeredNetworkName != null && registeredNetworkName.isNotEmpty
            ? registeredNetworkName
            : registeredUserName != null && registeredUserName.isNotEmpty
                ? registeredUserName
                : fallbackName;
    final safeTabIndex = initialTabIndex < 0
        ? 0
        : initialTabIndex > 1
            ? 1
            : initialTabIndex;

    return DefaultTabController(
      length: 2,
      initialIndex: safeTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            displayName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
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
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NetworkTabBarWrapper(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PackagesTab(
                        onAddPackage: onAddPackage,
                        onImportCards: onImportCards,
                        onEditPackage: onEditPackage,
                        newPackage: newPackage,
                        updatedPackage: updatedPackage,
                      ),
                      _OrdersTab(
                        onApproveOrder: onApproveOrder,
                        onRejectOrder: onRejectOrder,
                        onViewOrderDetails: onViewOrderDetails,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkTabBarWrapper extends StatefulWidget {
  @override
  State<_NetworkTabBarWrapper> createState() => _NetworkTabBarWrapperState();
}

class _NetworkTabBarWrapperState extends State<_NetworkTabBarWrapper> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppPrimaryTabBar(
        style: AppTabBarStyle.filledSegment,
        isDense: true,
        enableBlur: false,
        outlineColor: Colors.transparent,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        radius: 6.r,
        tabs: const [
          AppPrimaryTab(
            label: 'الباقات',
          ),
          AppPrimaryTab(
            label: 'الطلبات',
          ),
        ],
      ),
    );
  }
}

class _PackagesTab extends StatefulWidget {
  const _PackagesTab({
    this.onAddPackage,
    this.onImportCards,
    this.onEditPackage,
    this.newPackage,
    this.updatedPackage,
  });
  final VoidCallback? onAddPackage;
  final VoidCallback? onImportCards;
  final JsonMapCallback? onEditPackage;
  final JsonMap? newPackage;
  final JsonMap? updatedPackage;

  @override
  State<_PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<_PackagesTab> {
  @override
  void initState() {
    super.initState();
    // استخدام WidgetsBinding لتجنب setState أثناء البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackages();
    });
  }

  void _loadPackages() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider =
        Provider.of<PackageProvider>(context, listen: false);
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isNotEmpty) {
      packageProvider.loadPackages(networkId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packageProvider = Provider.of<PackageProvider>(context);
    final packages = packageProvider.packages;

    if (packageProvider.isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: List.generate(
            5,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: const SkeletonPackageCard(),
            ),
          ),
        ),
      );
    }

    if (packageProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              packageProvider.error!,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadPackages,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadPackages();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            if (packages.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),
                    Icon(Icons.inbox, size: 80.w, color: Colors.grey[400]),
                    SizedBox(height: 16.h),
                    Text(
                      'لا توجد باقات',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ابدأ بإضافة أول باقة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              ...packages.asMap().entries.map((entry) {
                final index = entry.key;
                final pkg = entry.value;
                final totalMb =
                    pkg.dataSizeMB > 0 ? pkg.dataSizeMB : pkg.dataSizeGB * 1024;

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
                      quantityAvailable: pkg.stock,
                      type:
                          PackageType.values[index % PackageType.values.length],
                      accentColor: ColorParser.tryParse(pkg.color),
                    ),
                    onEdit: widget.onEditPackage == null
                        ? null
                        : () => widget.onEditPackage!({
                              'id': pkg.id,
                              'name': pkg.name,
                              'mikrotikName': pkg.mikrotikName,
                              'sellingPrice': pkg.sellingPrice,
                              'purchasePrice': pkg.purchasePrice,
                              'validityDays': pkg.validityDays,
                              'usageHours': pkg.usageHours,
                              'dataSizeGB': pkg.dataSizeGB,
                              'dataSizeMB': pkg.dataSizeMB,
                              'color': pkg.color,
                              'stock': pkg.stock,
                            }),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab({
    this.onApproveOrder,
    this.onRejectOrder,
    this.onViewOrderDetails,
  });
  final IntCallback? onApproveOrder;
  final IntCallback? onRejectOrder;
  final IntCallback? onViewOrderDetails;

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  Future<void> _handleApprove(OrderModel order) async {
    // إنشاء نص تفصيلي للباقات
    final packagesText = order.items
        .map((item) => '• ${item.packageName}: ${item.quantity} كرت')
        .join('\n');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الموافقة على الطلب'),
        content: Text(
          'هل تريد الموافقة على طلب "${order.vendorName}"؟\n\n'
          'سيتم نقل ${order.totalCards} كرت إلى مخزون المتجر:\n\n'
          '$packagesText',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseOrderService.approveOrder(order);

      if (!mounted) return;
      CustomToast.success(
        context,
        'تم نقل ${order.totalCards} كرت إلى مخزون المتجر بنجاح',
        title: 'تمت الموافقة',
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorHandler.extractErrorMessage(e);

      // تحديد نوع Toast حسب نوع الخطأ
      if (ErrorHandler.isStockError(e)) {
        CustomToast.warning(
          context,
          errorMessage,
          title: 'المخزون غير كافٍ',
        );
      } else {
        CustomToast.error(
          context,
          errorMessage,
          title: 'فشلت العملية',
        );
      }
    }
  }

  Future<void> _handleReject(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Text('هل تريد رفض طلب "${order.vendorName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseOrderService.rejectOrder(order.id);

      if (!mounted) return;
      CustomToast.warning(
        context,
        'تم رفض طلب ${order.vendorName}',
        title: 'تم الرفض',
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorHandler.extractErrorMessage(e);

      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل رفض الطلب',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) {
      return const Center(child: Text('معلومات الشبكة غير متوفرة'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: FirebaseOrderService.getNetworkOrders(networkId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const SkeletonOrderCard(),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            // Stream سيتم تحديثه تلقائياً
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: orders.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: AppCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64.w,
                              color: AppColors.gray400,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'لا توجد طلبات',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: order_widget.OrderCard(
                        order: order,
                        onApprove: () => _handleApprove(order),
                        onReject: () => _handleReject(order),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
