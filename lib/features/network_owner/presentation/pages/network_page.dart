import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/packages/package_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/order_model.dart';
import '../../data/models/package_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/providers/package_provider.dart';
import '../../data/services/firebase_order_service.dart';
import '../../data/services/firebase_vendor_service.dart';
import '../widgets/order_card.dart' as order_widget;
import 'network_stored_page.dart';

class ColorParser {
  // Cache للألوان لتحسين الأداء
  static final Map<String, Color?> _cache = {};

  static const _colorMap = <String, Color>{
    'blue': AppColors.primary,
    'green': AppColors.success,
    'red': AppColors.error,
    'orange': AppColors.warning,
    'purple': Color(0xFF8b5cf6),
    'pink': Color(0xFFec4899),
    'yellow': Color(0xFFeab308),
    'cyan': Color(0xFF06b6d4),
    'gray': AppColors.gray500,
    'grey': AppColors.gray500,
    'black': AppColors.gray900,
  };

  static Color? tryParse(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    final key = colorString.toLowerCase();
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final color = _colorMap[key];
    _cache[key] = color;
    return color;
  }
}

class NetworkPage extends StatelessWidget {
  const NetworkPage({
    super.key,
    this.onAddPackage,
    this.onEditPackage,
    this.onImportCards,
    this.onViewInventory,
    this.newPackage,
    this.updatedPackage,
    this.networkName,
  });

  final VoidCallback? onAddPackage;
  final JsonMapCallback? onEditPackage;
  final VoidCallback? onImportCards;
  final VoidCallback? onViewInventory;
  final JsonMap? newPackage;
  final JsonMap? updatedPackage;
  final String? networkName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(
          'إدارة الشبكة',
          style: TextStyle(
            color: const Color(0xFF1C2B33),
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1C2B33)),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SafeArea(
          top: false,
          child: NetworkPackagesSection(
            onAddPackage: onAddPackage,
            onImportCards: onImportCards,
            onEditPackage: onEditPackage,
            onViewInventory: onViewInventory,
            newPackage: newPackage,
            updatedPackage: updatedPackage,
          ),
        ),
      ),
    );
  }
}

class NetworkPackagesSection extends StatefulWidget {
  const NetworkPackagesSection({
    super.key,
    this.onAddPackage,
    this.onImportCards,
    this.onEditPackage,
    this.onViewInventory,
    this.newPackage,
    this.updatedPackage,
  });

  final VoidCallback? onAddPackage;
  final VoidCallback? onImportCards;
  final JsonMapCallback? onEditPackage;
  final VoidCallback? onViewInventory;
  final JsonMap? newPackage;
  final JsonMap? updatedPackage;

  @override
  State<NetworkPackagesSection> createState() => _NetworkPackagesSectionState();
}

class _NetworkPackagesSectionState extends State<NetworkPackagesSection> {
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
    final packageProvider = Provider.of<PackageProvider>(context, listen: false);
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

    final inventoryTap = widget.onViewInventory ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NetworkStoredPage(),
              ),
            );

    final hasActions = widget.onAddPackage != null || widget.onImportCards != null || widget.onViewInventory != null;
    return RefreshIndicator(
      onRefresh: () async {
        _loadPackages();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasActions) ...[
                    _NetworkActionsRow(
                      onAddPackage: widget.onAddPackage,
                      onImportCards: widget.onImportCards,
                      onViewInventory: inventoryTap,
                    ),
                    SizedBox(height: 12.h),
                  ],
                  Text(
                    'الباقات',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (packages.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pkg = packages[index];
                    final totalMb = pkg.dataSizeMB > 0 ? pkg.dataSizeMB : pkg.dataSizeGB * 1024;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _RealTimePackageCard(
                        package: pkg,
                        totalMb: totalMb,
                        index: index,
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
                                  'isActive': pkg.isActive,
                                }),
                      ),
                    );
                  },
                  childCount: packages.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NetworkActionsRow extends StatelessWidget {
  const _NetworkActionsRow({
    this.onAddPackage,
    this.onImportCards,
    this.onViewInventory,
  });

  final VoidCallback? onAddPackage;
  final VoidCallback? onImportCards;
  final VoidCallback? onViewInventory;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (onAddPackage != null) {
      buttons.add(
        _NetworkActionButton(
          icon: Icons.add_box_outlined,
          label: 'إضافة باقة',
          onTap: onAddPackage!,
        ),
      );
    }

    if (onImportCards != null) {
      buttons.add(
        _NetworkActionButton(
          icon: Icons.sim_card_download_outlined,
          label: 'استيراد كروت',
          onTap: onImportCards!,
        ),
      );
    }

    if (onViewInventory != null) {
      buttons.add(
        _NetworkActionButton(
          icon: Icons.inventory_2_outlined,
          label: 'المخزون',
          onTap: onViewInventory!,
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buttons,
    );
  }
}

class _NetworkActionButton extends StatelessWidget {
  const _NetworkActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96.w,
      child: InkWell(
        onTap: onTap,
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
                icon,
                size: 24.r,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkOrdersPage extends StatefulWidget {
  const NetworkOrdersPage({
    super.key,
    this.onApproveOrder,
    this.onRejectOrder,
  });

  final IntCallback? onApproveOrder;
  final IntCallback? onRejectOrder;

  @override
  State<NetworkOrdersPage> createState() => _NetworkOrdersPageState();
}

class _NetworkOrdersPageState extends State<NetworkOrdersPage> {
  Future<void> _handleApprove(OrderModel order) async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    try {
      // التحقق من وجود المتجر في users collection (المصدر الأساسي)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(order.vendorId).get();

      if (!userDoc.exists) {
        if (!mounted) return;
        CustomToast.error(
          context,
          'المتجر غير موجود في النظام',
          title: 'خطأ',
        );
        return;
      }

      // التحقق من وجود المتجر في vendors collection لهذه الشبكة
      final compositeId = '${networkId}_${order.vendorId}';
      final vendorDoc = await FirebaseFirestore.instance.collection('vendors').doc(compositeId).get();

      // إذا لم يكن المتجر مضافاً لهذه الشبكة، نضيفه تلقائياً
      if (!vendorDoc.exists) {
        if (!mounted) return;

        final shouldAdd = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 24.w),
                SizedBox(width: 8.w),
                const Text('متجر جديد'),
              ],
            ),
            content: Text(
              'المتجر "${order.vendorName}" غير مضاف في قائمتك.\n\n'
              'هل تريد إضافته تلقائياً والموافقة على الطلب؟',
              style: TextStyle(fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إضافة والموافقة'),
              ),
            ],
          ),
        );

        if (shouldAdd != true) return;

        // إضافة المتجر تلقائياً
        final userData = userDoc.data()!;
        final newVendor = VendorModel(
          id: order.vendorId,
          userId: order.vendorId, // userId الحقيقي للمتجر
          name: userData['name'] as String? ?? order.vendorName, // اسم المتجر من name
          ownerName: userData['ownerName'] as String? ?? userData['name'] as String? ?? '', // اسم المالك من ownerName
          phone: userData['phone'] as String? ?? '',
          governorate: userData['governorate'] as String? ?? '',
          district: userData['district'] as String? ?? '',
          address: userData['address'] as String? ?? '',
          networkId: networkId,
          balance: 0,
          stock: 0,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await FirebaseVendorService.addVendor(newVendor);
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(
        context,
        'فشل التحقق من بيانات المتجر: $e',
        title: 'خطأ',
      );
      return;
    }

    // إنشاء نص تفصيلي للباقات
    final packagesText = order.items.map((item) => '• ${item.packageName}: ${item.quantity} كرت').join('\n');

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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorHandler.extractErrorMessage(e);

      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل رفض الطلب',
      );
    }
  }

  Future<void> _handleDelete(OrderModel order) async {
    // الحذف مباشرة (الحوار معروض من OrderCard)
    try {
      await FirebaseOrderService.deleteOrder(order.id);

      if (!mounted) return;
      CustomToast.success(
        context,
        'تم حذف الطلب من السجلات',
        title: 'تم الحذف',
      );
    } on Exception catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorHandler.extractErrorMessage(e);

      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل حذف الطلب',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final networkId = authProvider.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: const Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1C2B33)),
        title: const Text(
          'الطلبات',
          style: TextStyle(color: Color(0xFF1C2B33)),
        ),
      ),
      body: networkId.isEmpty
          ? const Center(child: Text('معلومات الشبكة غير متوفرة'))
          : StreamBuilder<List<OrderModel>>(
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
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: order_widget.OrderCard(
                                order: order,
                                onApprove: () => _handleApprove(order),
                                onReject: () => _handleReject(order),
                                onDelete: () => _handleDelete(order),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
    );
  }
}

/// Widget لعرض بطاقة الباقة مع الكمية الفعلية المتزامنة من المخزون
class _RealTimePackageCard extends StatelessWidget {
  const _RealTimePackageCard({
    required this.package,
    required this.totalMb,
    required this.index,
    this.onEdit,
  });

  final PackageModel package;
  final int totalMb;
  final int index;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final networkId = context.read<AuthProvider>().user?.id ?? '';

    return StreamBuilder<int>(
      stream: _getAvailableCardsCount(networkId, package.id),
      builder: (context, snapshot) {
        // استخدام الكمية الفعلية من المخزون أو القيمة الافتراضية
        final availableCount = snapshot.data ?? package.stock;

        return PackageCard(
          data: PackageCardData(
            name: package.name,
            sizeInMb: totalMb,
            validityDays: package.validityDays,
            usageWindowHours: package.usageHours,
            retailPrice: package.sellingPrice,
            wholesalePrice: package.purchasePrice,
            quantityAvailable: availableCount,
            type: PackageType.values[index % PackageType.values.length],
            accentColor: ColorParser.tryParse(package.color),
            icon: _parseIconData(package.iconCodePoint, package.iconFontFamily, package.iconFontPackage),
            isActive: package.isActive,
          ),
          onEdit: onEdit,
        );
      },
    );
  }

  /// جلب عدد الكروت المتاحة لهذه الباقة من المخزون الفعلي
  Stream<int> _getAvailableCardsCount(String networkId, String packageId) {
    return FirebaseFirestore.instance
        .collection('cards')
        .where('networkId', isEqualTo: networkId)
        .where('packageId', isEqualTo: packageId)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// تحويل iconCodePoint إلى IconData
  /// يتم استخدام دالة منفصلة لتجنب مشاكل tree-shaking في Release mode
  IconData? _parseIconData(String? iconCodePoint, String? fontFamily, String? fontPackage) {
    if (iconCodePoint == null || iconCodePoint.isEmpty) {
      return null;
    }

    try {
      final codePoint = int.tryParse(iconCodePoint);
      if (codePoint == null) return null;

      return IconData(
        codePoint,
        fontFamily: fontFamily,
        fontPackage: fontPackage,
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing icon: $e');
      return null;
    }
  }
}
