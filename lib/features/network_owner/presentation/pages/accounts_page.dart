import 'package:cloud_firestore/cloud_firestore.dart';
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
    final networkId = context.select((AuthProvider p) => p.user?.id ?? '');

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
      final governorateMatch =
          _selectedGovernorate == null || _selectedGovernorate!.isEmpty || vendor.governorate == _selectedGovernorate;
      final districtMatch =
          _selectedDistrict == null || _selectedDistrict!.isEmpty || vendor.district == _selectedDistrict;
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
    // حذف المتجر مباشرة (الحوار معروض من Dismissible)
    final vendorProvider = context.read<VendorProvider>();

    // عرض مؤشر تحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await vendorProvider.deleteVendor(vendor.realUserId);

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

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
                        itemBuilder: (context, i) => const SkeletonCardWithIcon(),
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
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: _buildEmptyState(),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cols = _calcCrossAxisCount(
                                      constraints.maxWidth,
                                    );
                                    return GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        mainAxisSpacing: 12.h,
                                        crossAxisSpacing: 12.w,
                                        childAspectRatio: 2.8, // نسبة للتصميم المختصر
                                      ),
                                      itemCount: filteredVendors.length,
                                      itemBuilder: (context, i) {
                                        final vendor = filteredVendors[i];
                                        return _VendorTile(
                                          vendor: vendor,
                                          onTap: () => widget.onViewMerchantTransactions?.call(vendor.realUserId),
                                          onDelete: () => _handleDeleteVendor(vendor),
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
              _searchQuery.isEmpty ? 'اضغط على أيقونة البحث لإضافة متاجر جديدة' : 'جرب البحث بكلمات مختلفة',
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

class _VendorTile extends StatefulWidget {
  const _VendorTile({
    required this.vendor,
    this.onTap,
    this.onDelete,
  });
  final VendorModel vendor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  State<_VendorTile> createState() => _VendorTileState();
}

class _VendorTileState extends State<_VendorTile> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getVendorRealTimeData(),
      builder: (context, snapshot) {
        // استخدام البيانات الفعلية من Firebase أو البيانات المخزنة
        final realBalance = (snapshot.data?['balance'] as num?)?.toDouble() ?? widget.vendor.balance;
        final realStock = (snapshot.data?['stock'] as int?) ?? widget.vendor.stock;

        return Dismissible(
          key: Key(widget.vendor.id), // استخدام document ID (composite) للـ key
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            if (widget.onDelete == null) return false;

            // عرض حوار تأكيد للمتاجر
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.w),
                    SizedBox(width: 8.w),
                    const Text('حذف المتجر'),
                  ],
                ),
                content: Text(
                  'هل تريد حذف "${widget.vendor.name}" من قائمة المتاجر؟\n\nسيتم حذف جميع البيانات المرتبطة.',
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

            if (confirmed ?? false) {
              widget.onDelete!();
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 20.w),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.white, size: 28.w),
                SizedBox(width: 8.w),
                Text(
                  'حذف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          child: Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
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
                              widget.vendor.avatar,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.vendor.name,
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
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      widget.vendor.ownerName,
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.gray600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${realBalance >= 0 ? '+' : ''}${realBalance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: realBalance > 0 ? AppColors.error : AppColors.success,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'ر.ي',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: AppColors.blue100,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '$realStock كرت',
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
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 13.w, color: AppColors.gray500),
                        SizedBox(width: 5.w),
                        Text(
                          widget.vendor.phone,
                          style: TextStyle(fontSize: 11.5.sp, color: AppColors.gray700),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 13.w, color: AppColors.gray500),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            '${widget.vendor.governorate}${widget.vendor.district.isNotEmpty ? ' • ${widget.vendor.district}' : ''}${widget.vendor.address.isNotEmpty ? ' • ${widget.vendor.address}' : ''}',
                            style: TextStyle(fontSize: 11.5.sp, color: AppColors.gray700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// جلب البيانات الفعلية للمتجر (الرصيد والمخزون)
  Stream<Map<String, dynamic>> _getVendorRealTimeData() {
    // مراقبة تغييرات المعاملات لحساب الرصيد الفعلي
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('networkId', isEqualTo: widget.vendor.networkId)
        .where('vendorId', isEqualTo: widget.vendor.realUserId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .asyncMap((transactionsSnapshot) async {
      // حساب الرصيد من المعاملات
      double totalCharges = 0; // المستحقات (موجب)
      double totalPayments = 0; // المدفوعات (سالب)

      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = data['type'] as String?;

        // دعم المعاملات القديمة والجديدة
        if (type == 'cash_payment_received') {
          // معاملات قديمة: مبلغ موجب ولكنها دفعات
          totalPayments += amount.abs();
        } else if (amount > 0) {
          // موجب = مستحقات (charge, fee)
          totalCharges += amount;
        } else if (amount < 0) {
          // سالب = مدفوعات (payment, refund)
          totalPayments += amount.abs();
        }
      }

      // الرصيد = المستحقات - المدفوعات
      final balance = totalCharges - totalPayments;

      // حساب المخزون الفعلي من vendor_cards
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('vendor_cards')
          .where('vendorId', isEqualTo: widget.vendor.realUserId)
          .where('networkId', isEqualTo: widget.vendor.networkId)
          .where('status', isEqualTo: 'available')
          .get();

      final stock = cardsSnapshot.docs.length;

      return {'balance': balance, 'stock': stock};
    });
  }
}
