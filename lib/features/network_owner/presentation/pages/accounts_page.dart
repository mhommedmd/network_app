import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/vendor_model.dart';
import '../../data/providers/vendor_provider.dart';
import 'vendor_search_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    this.onViewMerchantTransactions,
  });
  final void Function(String)? onViewMerchantTransactions;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final networkId = authProvider.user?.id ?? '';

    return ChangeNotifierProvider(
      create: (_) => VendorProvider(networkId),
      child: _AccountsPageContent(
        onViewMerchantTransactions: onViewMerchantTransactions,
      ),
    );
  }
}

class _AccountsPageContent extends StatefulWidget {
  const _AccountsPageContent({
    this.onViewMerchantTransactions,
  });
  final void Function(String)? onViewMerchantTransactions;

  @override
  State<_AccountsPageContent> createState() => _AccountsPageContentState();
}

class _AccountsPageContentState extends State<_AccountsPageContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGovernorate;
  String? _selectedDistrict;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _calcCrossAxisCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 850) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  List<VendorModel> _applyFilters(List<VendorModel> vendors) {
    final lowerQuery = _searchQuery.trim().toLowerCase();
    return vendors.where((vendor) {
      final nameMatch = lowerQuery.isEmpty ||
          vendor.name.toLowerCase().contains(lowerQuery) ||
          vendor.ownerName.toLowerCase().contains(lowerQuery);
      final governorateMatch = _selectedGovernorate == null ||
          _selectedGovernorate!.isEmpty ||
          vendor.governorate == _selectedGovernorate;
      final districtMatch = _selectedDistrict == null ||
          _selectedDistrict!.isEmpty ||
          vendor.district == _selectedDistrict;
      return nameMatch && governorateMatch && districtMatch;
    }).toList();
  }

  void _openSearchPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VendorSearchPage(),
      ),
    );
  }

  Future<void> _handleDeleteVendor(VendorModel vendor) async {
    // عرض تأكيد الحذف
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المتجر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد حذف "${vendor.name}" من قائمة المتاجر؟'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.warningLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningDark, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'سيتم حذف جميع البيانات المرتبطة بهذا المتجر',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.warningDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // حذف المتجر
    final vendorProvider = context.read<VendorProvider>();
    final success = await vendorProvider.deleteVendor(vendor.id);

    if (!mounted) return;

    if (success) {
      CustomToast.success(
        context,
        'تم حذف جميع البيانات المرتبطة بالمتجر',
        title: 'تم حذف "${vendor.name}"',
      );
    } else {
      final errorMessage = ErrorHandler.extractErrorMessage(
        vendorProvider.error ?? 'حدث خطأ غير متوقع',
      );
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل الحذف',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final vendors = vendorProvider.vendors;
    final filteredVendors = _applyFilters(vendors);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المتاجر',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'بحث وإضافة متاجر',
            onPressed: _openSearchPage,
            icon: const Icon(
              Icons.add_business,
              color: Colors.white,
            ),
          ),
        ],
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
          child: vendorProvider.isLoading
              ? Padding(
                  padding: EdgeInsets.all(16.w),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = _calcCrossAxisCount(constraints.maxWidth);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 10.h,
                          crossAxisSpacing: 10.w,
                          childAspectRatio: 2.4,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, i) =>
                            const SkeletonCardWithIcon(),
                      );
                    },
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // شريط البحث المحلي (اختياري)
                      if (vendors.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: TextField(
                            controller: _searchController,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              labelText: 'بحث في المتاجر المضافة',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),

                      // قائمة المتاجر
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await vendorProvider.loadVendors();
                          },
                          color: AppColors.primary,
                          child: filteredVendors.isEmpty
                              ? SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.5,
                                    child: _buildEmptyState(),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cols = _calcCrossAxisCount(
                                        constraints.maxWidth);
                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        mainAxisSpacing: 10.h,
                                        crossAxisSpacing: 10.w,
                                        childAspectRatio: 2.4,
                                      ),
                                      itemCount: filteredVendors.length,
                                      itemBuilder: (context, i) {
                                        final vendor = filteredVendors[i];
                                        return _VendorTile(
                                          vendor: vendor,
                                          onTap: () => widget
                                              .onViewMerchantTransactions
                                              ?.call(vendor.id),
                                          onDelete: () =>
                                              _handleDeleteVendor(vendor),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.blue100,
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: Icon(
                Icons.store,
                size: 32.w,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isEmpty ? 'لا توجد متاجر' : 'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isEmpty
                  ? 'اضغط على أيقونة البحث لإضافة متاجر جديدة'
                  : 'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  const _VendorTile({
    required this.vendor,
    this.onTap,
    this.onDelete,
  });
  final VendorModel vendor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      child: Stack(
        children: [
          Row(
            textDirection:
                TextDirection.ltr, // إبقاء الرصيد في أقصى اليسار بصريًا
            children: [
              // لوحة الرصيد + المخزون (يسار الكرت)
              SizedBox(
                width: 96.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الرصيد
                    Text(
                      'الرصيد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          vendor.balance.toInt().toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: vendor.balance >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'ر.ي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // فاصل بين الرصيد والمخزون
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: AppColors.gray200,
                      ),
                    ),
                    // المخزون
                    Text(
                      'المخزون',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      vendor.stock.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              // معلومات المتجر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // الصورة الرمزية
                        Container(
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: AppColors.blue100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              vendor.avatar,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // الاسم والمالك
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray900,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppColors.gray500,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      vendor.ownerName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.gray700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // الهاتف والموقع
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 14, color: AppColors.gray500),
                        SizedBox(width: 4.w),
                        Text(
                          vendor.phone,
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.gray700),
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.place,
                            size: 14, color: AppColors.gray500),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            vendor.location,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // تمت إزالة شارة المخزون من يمين الكرت (نقلناها لليسار)
                  ],
                ),
              ),
            ],
          ),
          // زر الحذف
          if (onDelete != null)
            Positioned(
              top: 0,
              left: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18.w,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
