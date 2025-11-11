import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_tab_bar.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../../network_owner/data/models/order_model.dart';
import '../../../network_owner/data/services/firebase_order_service.dart';
import '../../data/models/network_connection_model.dart';
import '../../data/services/firebase_network_service.dart';
import 'network_details_page.dart';
import 'network_search_page.dart';

typedef NetworkSelectCallback = void Function(NetworkConnectionModel network);

class NetworksPage extends StatefulWidget {
  const NetworksPage({super.key, this.onNetworkSelect});
  final NetworkSelectCallback? onNetworkSelect;

  @override
  State<NetworksPage> createState() => _NetworksPageState();
}

class _NetworksPageState extends State<NetworksPage>
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

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NetworkSearchPage(),
      ),
    );
  }

  void _openDetails(NetworkConnectionModel connection) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NetworkDetailsPage(
          networkId: connection.networkId,
          networkOwnerId: connection.networkId,
          networkName: connection.networkName,
        ),
      ),
    );
  }

  Future<void> _removeNetwork(NetworkConnectionModel network) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الشبكة'),
        content: Text('هل تريد حذف "${network.networkName}" من القائمة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseNetworkService.removeNetworkConnection(network.id);

      if (!mounted) return;
      CustomToast.success(
        context,
        'تم إزالة الشبكة من قائمتك',
        title: 'تم حذف "${network.networkName}"',
      );
    } on Exception catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل الحذف',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F5F8),
        surfaceTintColor: const Color(0xFFF1F5F8),
        elevation: 0,
        titleSpacing: 20.w,
        title: Text(
          'الشبكات',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openSearch,
            icon: const Icon(Icons.search, color: AppColors.primary),
            tooltip: 'بحث',
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Container(
        color: const Color(0xFFF1F5F8),
        child: Column(
          children: [
            Container(
              margin: EdgeInsetsDirectional.only(
                top: 12.h,
                start: 20.w,
                end: 20.w,
                bottom: 12.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
                  AppPrimaryTab(label: 'الشبكات'),
                  AppPrimaryTab(label: 'الطلبات'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNetworksTab(),
                  _buildOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworksTab() {
    final vendorId = context.read<AuthProvider>().user?.id ?? '';

    return StreamBuilder<List<NetworkConnectionModel>>(
      stream: FirebaseNetworkService.getConnectedNetworks(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: const SkeletonCardWithIcon(),
            ),
          );
        }

        final networks = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            // Stream سيتم تحديثه تلقائياً
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (networks.isEmpty)
                  AppCard(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          size: 64.w,
                          color: AppColors.gray400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا توجد شبكات',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'استخدم أيقونة البحث في الأعلى لإضافة شبكة جديدة',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.gray600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: networks.map(_networkRow).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _networkRow(NetworkConnectionModel network) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        onTap: () {
          if (widget.onNetworkSelect != null) {
            widget.onNetworkSelect!(network);
          } else {
            _openDetails(network);
          }
        },
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            _NetworkAvatar(
              color: AppColors.primary,
              label: network.networkName.isNotEmpty
                  ? network.networkName.characters.first
                  : 'ش',
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.networkName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'المالك: ${network.networkOwner}',
                    style: AppTypography.caption.colored(AppColors.gray500),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'العنوان: ${network.governorate}، ${network.district}',
                    style: AppTypography.caption.colored(AppColors.gray500),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeNetwork(network),
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final vendorId = context.read<AuthProvider>().user?.id ?? '';

    if (vendorId.isEmpty) {
      return const Center(child: Text('معلومات المستخدم غير متوفرة'));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: FirebaseOrderService.getVendorOrders(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: const SkeletonOrderCard(),
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
                    'خطأ في تحميل الطلبات',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ],
              ),
            ),
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
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64.w,
                              color: AppColors.gray400,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'لا توجد طلبات',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'لم ترسل أي طلبات بعد',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.gray600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _VendorOrderCard(order: order);
                  },
                ),
        );
      },
    );
  }
}

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.subheadline.copyWith(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// بطاقة عرض الطلب للمتجر
class _VendorOrderCard extends StatelessWidget {
  const _VendorOrderCard({required this.order});

  final OrderModel order;

  Color get _statusColor {
    switch (order.status) {
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

  String get _statusText {
    switch (order.status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'مرفوض';
      default:
        return order.status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('dd/MM/yyyy', 'ar').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف العلوي
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.networkName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border:
                      Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          const Divider(color: AppColors.gray200, height: 1),
          SizedBox(height: 12.h),

          // التفاصيل - قائمة الباقات
          ...order.items.map((item) {
            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 16.w, color: AppColors.primary,),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      item.packageName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantity} كرت',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 12.h),
          const Divider(color: AppColors.gray200, height: 1),
          SizedBox(height: 12.h),

          // الإجمالي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 18.w, color: AppColors.gray500,),
                  SizedBox(width: 8.w),
                  Text(
                    'إجمالي: ${order.totalCards} كرت',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(order.totalAmount),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
