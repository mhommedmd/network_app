import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme & shared UI
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/vendor_model.dart';
import '../../data/providers/card_provider.dart';
import '../../data/services/firebase_transaction_service.dart';
import '../../data/services/firebase_vendor_service.dart';
import 'cash_payment_page.dart';
import 'network_stored_page.dart';
import 'notifications_page.dart';

class NetworkOwnerHomePage extends StatelessWidget {
  const NetworkOwnerHomePage({
    super.key,
    this.onViewOrderDetails,
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
  final IntCallback? onViewOrderDetails;
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
    final displayNetworkName = networkName ??
        authProvider.user?.networkName ??
        authProvider.user?.name ??
        'شبكة افاق نت';
    final displayOwnerName = ownerName ?? authProvider.user?.name ?? 'المالك';

    final handleCashPayment = onRecordCashPayment ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NetworkCashPaymentPage(
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            );
    final handleNotificationsTap = onNotificationsTap ??
        () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            );

    return Scaffold(
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
                children: [
                  CircleAvatar(
                    radius: 24.w,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _isValidUrl(avatarUrl)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: !_isValidUrl(avatarUrl)
                        ? Icon(
                            Icons.person,
                            color: Colors.white,
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
                            color: Colors.white,
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
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: handleNotificationsTap,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 26.w,
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrimaryStatsSection(onViewInventory: onViewInventory),
                SizedBox(height: 32.h),
                _QuickActionsGrid(
                  onAddPackage: onAddPackage,
                  onImportCards: onImportCards,
                  onAddMerchant: onAddMerchant,
                  onRecordCashPayment: handleCashPayment,
                ),
                SizedBox(height: 40.h),
                _QuickAccessVendors(),
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
  });
  final VoidCallback? onAddPackage;
  final VoidCallback? onImportCards;
  final VoidCallback? onAddMerchant;
  final VoidCallback? onRecordCashPayment;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionData>[
      if (onRecordCashPayment != null)
        _ActionData(
          icon: Icons.payments_outlined,
          label: 'دفعة نقدية',
          onTap: onRecordCashPayment!,
        ),
      if (onAddPackage != null)
        _ActionData(
          icon: Icons.add_box_outlined,
          label: 'إضافة باقة',
          onTap: onAddPackage!,
        ),
      if (onImportCards != null)
        _ActionData(
          icon: Icons.sim_card_download_outlined,
          label: 'استيراد كروت',
          onTap: onImportCards!,
        ),
      if (onAddMerchant != null)
        _ActionData(
          icon: Icons.store_mall_directory_outlined,
          label: 'إضافة متجر',
          onTap: onAddMerchant!,
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
      final salesData =
          await FirebaseTransactionService.getTotalSales(networkId);

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
    } catch (e) {
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
                  const SkeletonLine(width: 100, height: 12),
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
                  const SkeletonLine(width: 100, height: 12),
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
              title: 'إجمالي المبيعات',
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

/// قسم المتاجر المفضلة للوصول السريع
class _QuickAccessVendors extends StatefulWidget {
  @override
  State<_QuickAccessVendors> createState() => _QuickAccessVendorsState();
}

class _QuickAccessVendorsState extends State<_QuickAccessVendors> {
  List<String?> _customVendorIds = [null, null, null]; // 3 slots
  List<VendorModel> _vendors = [];

  @override
  void initState() {
    super.initState();
    _loadCustomVendors();
    _loadVendorsList();
  }

  Future<void> _loadCustomVendors() async {
    final prefs = await SharedPreferences.getInstance();
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    setState(() {
      _customVendorIds = [
        prefs.getString('custom_vendor_0_$networkId'),
        prefs.getString('custom_vendor_1_$networkId'),
        prefs.getString('custom_vendor_2_$networkId'),
      ];
    });
  }

  void _loadVendorsList() {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) return;

    FirebaseVendorService.getVendorsByNetwork(networkId).listen(
      (vendors) {
        if (mounted) {
          setState(() {
            _vendors = vendors;
          });
        }
      },
      onError: (Object error) {
        // تسجيل الخطأ فقط
        print('❌ Error loading vendors: $error');
      },
    );
  }

  Future<void> _selectVendor(int slotIndex) async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) return;

    if (_vendors.isEmpty) {
      if (!mounted) return;
      CustomToast.warning(
        context,
        'قم بإضافة متاجر من صفحة المتاجر أولاً',
        title: 'لا توجد متاجر',
      );
      return;
    }

    // عرض قائمة المتاجر للاختيار
    final selectedVendor = await showDialog<VendorModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر متجر'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _vendors.length,
            itemBuilder: (context, index) {
              final vendor = _vendors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.blue100,
                  child: Text(
                    vendor.avatar,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                title: Text(vendor.name),
                subtitle: Text(
                  '${vendor.ownerName} • ${vendor.stock} كرت',
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () => Navigator.pop(context, vendor),
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

    if (selectedVendor != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'custom_vendor_${slotIndex}_$networkId', selectedVendor.id);

      setState(() {
        _customVendorIds[slotIndex] = selectedVendor.id;
      });
    }
  }

  Future<void> _removeVendor(int slotIndex) async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_vendor_${slotIndex}_$networkId');

    setState(() {
      _customVendorIds[slotIndex] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: AppColors.warning,
              size: 22.r,
            ),
            SizedBox(width: 8.w),
            Text(
              'المتاجر المفضلة',
              style: AppTypography.subheadline.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // 3 أزرار تخصيص
        ...List.generate(3, (index) {
          final vendorId = _customVendorIds[index];
          final vendor = vendorId != null
              ? _vendors.firstWhere(
                  (v) => v.id == vendorId,
                  orElse: () => VendorModel(
                    id: '',
                    name: '',
                    ownerName: '',
                    phone: '',
                    governorate: '',
                    district: '',
                    address: '',
                    networkId: '',
                    balance: 0,
                    stock: 0,
                    isActive: true,
                    createdAt: DateTime.now(),
                  ),
                )
              : null;

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: vendor != null && vendor.id.isNotEmpty
                ? _CustomVendorCard(
                    vendor: vendor,
                    onRemove: () => _removeVendor(index),
                  )
                : _CustomizeButton(
                    slotNumber: index + 1,
                    onTap: () => _selectVendor(index),
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
                  'اضغط لاختيار باقة',
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

/// بطاقة المتجر المخصص
class _CustomVendorCard extends StatelessWidget {
  const _CustomVendorCard({
    required this.vendor,
    required this.onRemove,
  });

  final VendorModel vendor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.w,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              vendor.avatar,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14.w, color: AppColors.gray500),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        vendor.ownerName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.inventory_2,
                        size: 14.w, color: AppColors.gray500),
                    SizedBox(width: 4.w),
                    Text(
                      '${vendor.stock} كرت',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: vendor.stock > 10
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.account_balance_wallet,
                        size: 14.w, color: AppColors.gray500),
                    SizedBox(width: 4.w),
                    Text(
                      '${vendor.balance.toStringAsFixed(0)} ر.ي',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: vendor.balance < 0
                            ? AppColors.errorDark
                            : AppColors.gray600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
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
    );
  }
}
