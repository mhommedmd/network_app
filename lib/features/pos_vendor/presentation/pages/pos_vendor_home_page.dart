import 'dart:ui' as ui show TextDirection;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/packages/package_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../../network_owner/data/models/package_model.dart';
import '../../../network_owner/data/services/firebase_package_service.dart';
import '../../data/models/network_connection_model.dart';
import '../../data/services/firebase_vendor_inventory_service.dart';
import '../../data/services/firebase_sale_service.dart';
import '../../data/models/sale_model.dart';

typedef StartSaleCallback = void Function(int id);

class PosVendorHomePage extends StatelessWidget {
  const PosVendorHomePage({
    super.key,
    this.onStartSale,
    this.onRequestCards,
    this.onRecordCashPayment,
  });

  final StartSaleCallback? onStartSale;
  final VoidCallback? onRequestCards;
  final VoidCallback? onRecordCashPayment;

  /// التحقق من صحة URL
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'نقطة بيع';

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(72.h),
        child: Container(
          padding: EdgeInsets.only(top: 8.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
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
                textDirection: ui.TextDirection.rtl,
                children: [
                  // Profile avatar
                  CircleAvatar(
                    radius: 22.w,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: authProvider.user?.avatar != null &&
                            _isValidUrl(authProvider.user!.avatar!)
                        ? NetworkImage(authProvider.user!.avatar!)
                        : null,
                    child: authProvider.user?.avatar == null ||
                            !_isValidUrl(authProvider.user?.avatar ?? '')
                        ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 26.w,
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  // Vendor name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'مرحباً بك',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 28.w,
                        ),
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: const BoxDecoration(
                              color: AppColors.errorLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PosStatsSection(),
                SizedBox(height: 24.h),
                _quickActions(context),
                SizedBox(height: 32.h),
                _CustomNetworksSection(),
                SizedBox(height: 24.h),
                _RecentSalesSection(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.shopping_cart,
                color: AppColors.primary,
                label: 'بيع سريع',
                onTap: () => context.push('/sale-process'),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.add,
                color: AppColors.success,
                label: 'طلب كروت',
                onTap: () => context.push('/send-order'),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.payments_outlined,
                color: AppColors.warningDark,
                label: 'دفعات نقدية',
                onTap: onRecordCashPayment ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// قسم الإحصائيات
class _PosStatsSection extends StatefulWidget {
  @override
  State<_PosStatsSection> createState() => _PosStatsSectionState();
}

class _PosStatsSectionState extends State<_PosStatsSection> {
  late Stream<int> _availableCardsStream;
  late Stream<double> _monthSalesStream;
  String? _currentVendorId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.watch<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    // إنشاء streams فقط عند تغيير vendorId
    if (_currentVendorId != vendorId && vendorId.isNotEmpty) {
      _currentVendorId = vendorId;
      _availableCardsStream = _getAvailableCardsStream(vendorId);
      _monthSalesStream = _getMonthSalesStream(vendorId);
      print('✨ Streams initialized for vendor: $vendorId');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVendorId == null || _currentVendorId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // مبيعات الشهر
        Expanded(
          child: AppCard(
            backgroundColor: Colors.white,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مبيعات الشهر',
                  style: TextStyle(
                    color: AppColors.gray600,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                StreamBuilder<double>(
                  stream: _monthSalesStream,
                  builder: (context, salesSnapshot) {
                    if (salesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text(
                        '...',
                        style: TextStyle(
                          color: AppColors.gray900,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }

                    if (salesSnapshot.hasError) {
                      print('❌ Sales stream error: ${salesSnapshot.error}');
                      return Text(
                        '0 ر.ي',
                        style: TextStyle(
                          color: AppColors.gray900,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }

                    final monthSales = salesSnapshot.data ?? 0.0;
                    return Text(
                      CurrencyFormatter.format(monthSales),
                      style: TextStyle(
                        color: AppColors.gray900,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16.w),
        // الكروت المتاحة
        Expanded(
          child: AppCard(
            backgroundColor: Colors.white,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الكروت المتاحة',
                  style: TextStyle(
                    color: AppColors.gray600,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                StreamBuilder<int>(
                  stream: _availableCardsStream,
                  builder: (context, snapshot) {
                    final availableCards = snapshot.data ?? 0;
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting;

                    return Text(
                      isLoading
                          ? '...'
                          : '${NumberFormat('#,###', 'ar').format(availableCards)} كرت',
                      style: TextStyle(
                        color: AppColors.gray900,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Stream لحساب الكروت المتاحة (يتحدث تلقائياً)
  Stream<int> _getAvailableCardsStream(String vendorId) {
    print('🎯 Creating available cards stream for: $vendorId');
    return FirebaseFirestore.instance
        .collection('vendor_cards')
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      print('📦 Available cards updated: ${snapshot.docs.length}');
      return snapshot.docs.length;
    });
  }

  /// Stream لحساب مبيعات الشهر
  Stream<double> _getMonthSalesStream(String vendorId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    print('🎯 Creating month sales stream for: $vendorId from $startOfMonth');

    return FirebaseFirestore.instance
        .collection('sales')
        .where('vendorId', isEqualTo: vendorId)
        .where('soldAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .snapshots()
        .map((snapshot) {
      print('📊 Month sales snapshot received: ${snapshot.docs.length} sales');
      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
        print('   - Sale: ${doc.id}, amount: $amount');
      }
      print('💰 Total sales this month: $total');
      return total;
    });
  }
}

/// قسم الشبكات المخصصة
class _CustomNetworksSection extends StatefulWidget {
  @override
  State<_CustomNetworksSection> createState() => _CustomNetworksSectionState();
}

class _CustomNetworksSectionState extends State<_CustomNetworksSection> {
  List<String?> _customNetworkIds = [null, null, null]; // 3 slots

  @override
  void initState() {
    super.initState();
    _loadCustomNetworks();
  }

  Future<void> _loadCustomNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    setState(() {
      _customNetworkIds = [
        prefs.getString('custom_network_0_$vendorId'),
        prefs.getString('custom_network_1_$vendorId'),
        prefs.getString('custom_network_2_$vendorId'),
      ];
    });
  }

  Future<void> _selectNetwork(int slotIndex) async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    if (vendorId.isEmpty) return;

    // الحصول على الشبكات المضافة
    final firestore = FirebaseFirestore.instance;
    final connectionsSnapshot = await firestore
        .collection('network_connections')
        .where('vendorId', isEqualTo: vendorId)
        .where('isActive', isEqualTo: true)
        .get();

    final connections = connectionsSnapshot.docs
        .map((doc) => NetworkConnectionModel.fromFirestore(doc))
        .toList();

    if (connections.isEmpty) {
      if (!mounted) return;
      CustomToast.warning(
        context,
        'قم بإضافة شبكة من صفحة الشبكات أولاً',
        title: 'لا توجد شبكات',
      );
      return;
    }

    // عرض قائمة الشبكات للاختيار
    final selectedNetwork = await showDialog<NetworkConnectionModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر شبكة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final network = connections[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.blue100,
                  child: Icon(Icons.hub, color: AppColors.primary, size: 20.w),
                ),
                title: Text(network.networkName),
                subtitle: Text('${network.governorate}، ${network.district}'),
                onTap: () => Navigator.pop(context, network),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (selectedNetwork != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'custom_network_${slotIndex}_$vendorId', selectedNetwork.networkId);

      setState(() {
        _customNetworkIds[slotIndex] = selectedNetwork.networkId;
      });
    }
  }

  Future<void> _removeNetwork(int slotIndex) async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_network_${slotIndex}_$vendorId');

    setState(() {
      _customNetworkIds[slotIndex] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 أزرار تخصيص (بدون عنوان)
        ...List.generate(3, (index) {
          final networkId = _customNetworkIds[index];

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: networkId != null
                ? _CustomNetworkSection(
                    networkId: networkId,
                    onRemove: () => _removeNetwork(index),
                  )
                : _CustomizeButton(
                    slotNumber: index + 1,
                    onTap: () => _selectNetwork(index),
                  ),
          );
        }),
      ],
    );
  }
}

/// زر التخصيص
class _CustomizeButton extends StatelessWidget {
  const _CustomizeButton({
    required this.slotNumber,
    required this.onTap,
  });

  final int slotNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.gray300,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              Icons.add,
              color: AppColors.gray500,
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تخصيص $slotNumber',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'اضغط لاختيار شبكة',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16.w,
            color: AppColors.gray400,
          ),
        ],
      ),
    );
  }
}

/// قسم الشبكة المخصصة مع باقاتها
class _CustomNetworkSection extends StatelessWidget {
  const _CustomNetworkSection({
    required this.networkId,
    required this.onRemove,
  });

  final String networkId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    return FutureBuilder<NetworkConnectionModel?>(
      future: _getNetworkConnection(vendorId, networkId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: AppCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonCircle(size: 48),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonLine(width: 120, height: 16),
                            SizedBox(height: 6.h),
                            const SkeletonLine(width: 80, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        final connection = snapshot.data;
        if (connection == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الشبكة مع زر الحذف
            AppCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              backgroundColor: AppColors.blue50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      connection.networkName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    iconSize: 20.w,
                    color: AppColors.gray500,
                    tooltip: 'إزالة',
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // باقات الشبكة
            StreamBuilder<List<PackageModel>>(
              stream: FirebasePackageService.getPackagesByNetwork(networkId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.all(16.w),
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

                final packages = snapshot.data ?? [];

                if (packages.isEmpty) {
                  return AppCard(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'لا توجد باقات متاحة في هذه الشبكة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.gray600,
                      ),
                    ),
                  );
                }

                return FutureBuilder<Map<String, int>>(
                  future: FirebaseVendorInventoryService.getVendorPackageStock(
                    vendorId: vendorId,
                    networkId: networkId,
                  ),
                  builder: (context, stockSnapshot) {
                    final packageStock = stockSnapshot.data ?? {};

                    return _PackagesWrap(
                      packages: packages,
                      packageStock: packageStock,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<NetworkConnectionModel?> _getNetworkConnection(
      String vendorId, String networkId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('network_connections')
          .where('vendorId', isEqualTo: vendorId)
          .where('networkId', isEqualTo: networkId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return NetworkConnectionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }
}

/// عرض الباقات في Wrap
class _PackagesWrap extends StatelessWidget {
  const _PackagesWrap({
    required this.packages,
    required this.packageStock,
  });

  final List<PackageModel> packages;
  final Map<String, int> packageStock;

  @override
  Widget build(BuildContext context) {
    const double minCardWidth = 260;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final spacing = 14.w;
        var columns = (maxWidth / (minCardWidth + spacing)).floor();
        if (columns < 1) columns = 1;
        final cardWidth = columns == 1
            ? maxWidth
            : (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: packages.asMap().entries.map((entry) {
            final index = entry.key;
            final pkg = entry.value;
            final totalMb =
                pkg.dataSizeMB > 0 ? pkg.dataSizeMB : pkg.dataSizeGB * 1024;
            final vendorStock = packageStock[pkg.id] ?? 0;

            return SizedBox(
              width: cardWidth,
              child: PackageCard(
                data: PackageCardData(
                  name: pkg.name,
                  sizeInMb: totalMb,
                  validityDays: pkg.validityDays,
                  usageWindowHours: pkg.usageHours,
                  retailPrice: pkg.sellingPrice,
                  wholesalePrice: pkg.purchasePrice,
                  quantityAvailable: vendorStock,
                  type: PackageType.values[index % PackageType.values.length],
                  accentColor: _parseColor(pkg.color),
                ),
                onTap: () async {
                  // الحصول على معلومات الشبكة
                  final authProvider = context.read<AuthProvider>();
                  final vendorId = authProvider.user?.id ?? '';

                  final firestore = FirebaseFirestore.instance;
                  final connectionSnapshot = await firestore
                      .collection('network_connections')
                      .where('vendorId', isEqualTo: vendorId)
                      .where('networkId', isEqualTo: pkg.networkId)
                      .limit(1)
                      .get();

                  if (connectionSnapshot.docs.isEmpty) return;

                  final connection = NetworkConnectionModel.fromFirestore(
                      connectionSnapshot.docs.first);

                  if (!context.mounted) return;

                  // فتح صفحة البيع مع تحديد الشبكة والباقة مسبقاً
                  GoRouter.of(context).push(
                    '/sale-process',
                    extra: {
                      'preselectedNetwork': connection,
                      'preselectedPackageId': pkg.id,
                    },
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    final colorMap = <String, Color>{
      'blue': AppColors.primary,
      'green': AppColors.success,
      'orange': AppColors.warning,
      'red': AppColors.error,
      'purple': Colors.purple,
      'teal': Colors.teal,
    };

    return colorMap[colorString.toLowerCase()];
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24.w),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// قسم آخر المبيعات
class _RecentSalesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    if (vendorId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: AppColors.primary,
              size: 22.r,
            ),
            SizedBox(width: 8.w),
            Text(
              'آخر المبيعات',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        StreamBuilder<List<SaleModel>>(
          stream:
              FirebaseSaleService.getRecentSales(vendorId: vendorId, limit: 10),
          builder: (context, snapshot) {
            // معالجة الأخطاء
            if (snapshot.hasError) {
              print('❌ Error in recent sales stream: ${snapshot.error}');
              return AppCard(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'خطأ في تحميل المبيعات: ${snapshot.error}',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: AppCard(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          children: [
                            const SkeletonCircle(size: 40),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SkeletonLine(width: 150, height: 14),
                                  SizedBox(height: 6.h),
                                  const SkeletonLine(width: 100, height: 12),
                                ],
                              ),
                            ),
                            const SkeletonLine(width: 60, height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final sales = snapshot.data ?? [];
            print('📋 Recent sales loaded: ${sales.length} sales');

            if (sales.isEmpty) {
              return AppCard(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 48.w,
                      color: AppColors.gray400,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'لا توجد مبيعات بعد',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'ستظهر عمليات البيع هنا بعد إتمام أول عملية بيع',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.gray500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sales.map((sale) => _SaleItem(sale: sale)).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// عنصر عملية البيع
class _SaleItem extends StatelessWidget {
  const _SaleItem({required this.sale});

  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        onTap: () => _showSaleDetails(context, sale),
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // أيقونة البيع
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: AppColors.success,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            // تفاصيل البيع
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.networkName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        '${sale.totalCards} كرت',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.gray600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: const BoxDecoration(
                          color: AppColors.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        CurrencyFormatter.format(sale.totalAmount),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (sale.customerPhone != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'العميل: ${sale.customerPhone}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // الوقت والتاريخ
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(sale.soldAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatDate(sale.soldAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.w,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final saleDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (saleDate == today) {
      return 'اليوم';
    } else if (saleDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  void _showSaleDetails(BuildContext context, SaleModel sale) {
    showDialog<void>(
      context: context,
      builder: (context) => _SaleDetailsDialog(sale: sale),
    );
  }
}

/// حوار تفاصيل البيع
class _SaleDetailsDialog extends StatelessWidget {
  const _SaleDetailsDialog({required this.sale});

  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'تفاصيل عملية البيع',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: 20.w,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // معلومات البيع
            AppCard(
              padding: EdgeInsets.all(16.w),
              backgroundColor: AppColors.blue50,
              child: Column(
                children: [
                  _InfoRow('الشبكة', sale.networkName),
                  SizedBox(height: 8.h),
                  _InfoRow('الوقت',
                      DateFormat('yyyy/MM/dd - HH:mm').format(sale.soldAt)),
                  SizedBox(height: 8.h),
                  _InfoRow('إجمالي الكروت', '${sale.totalCards} كرت'),
                  SizedBox(height: 8.h),
                  _InfoRow('المبلغ الإجمالي',
                      CurrencyFormatter.format(sale.totalAmount)),
                  if (sale.customerPhone != null) ...[
                    SizedBox(height: 8.h),
                    _InfoRow('رقم العميل', sale.customerPhone!),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // أرقام الكروت
            Text(
              'أرقام الكروت المباعة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            SizedBox(height: 12.h),

            // قائمة الكروت
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sale.packageCodes.length,
                itemBuilder: (context, index) {
                  final entry = sale.packageCodes.entries.elementAt(index);
                  final packageName = entry.key;
                  final cardNumbers = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$packageName (${cardNumbers.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...cardNumbers.map((cardNumber) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cardNumber,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.gray600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _copyToClipboard(context, cardNumber),
                                    icon: const Icon(Icons.copy),
                                    iconSize: 16.w,
                                    color: AppColors.gray500,
                                    tooltip: 'نسخ',
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),

            // أزرار الإجراءات
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyAllCards(context),
                    icon: const Icon(Icons.copy_all),
                    label: const Text('نسخ الكل'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('تم'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _InfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.gray600,
            ),
          ),
        ),
        Text(
          ':',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.gray600,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.gray900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.info(
      context,
      'تم نسخه إلى الحافظة',
      title: 'تم النسخ',
    );
  }

  void _copyAllCards(BuildContext context) {
    final allCards =
        sale.packageCodes.values.expand((cards) => cards).join('\n');
    _copyToClipboard(context, allCards);
  }
}
