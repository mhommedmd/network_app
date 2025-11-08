import 'dart:ui' as ui show TextDirection;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../../network_owner/data/models/package_model.dart';
import '../../../network_owner/data/services/firebase_package_service.dart';
import '../../data/models/network_connection_model.dart';
import '../../data/services/firebase_sale_service.dart';
import '../../data/services/firebase_vendor_inventory_service.dart';

class SaleProcessPage extends StatefulWidget {
  const SaleProcessPage({
    super.key,
    this.onBack,
    this.initialNetwork,
    this.initialPackageName,
    this.preselectedNetwork,
    this.preselectedPackageId,
  });

  final VoidCallback? onBack;
  final String? initialNetwork;
  final String? initialPackageName;
  final NetworkConnectionModel? preselectedNetwork;
  final String? preselectedPackageId;

  @override
  State<SaleProcessPage> createState() => _SaleProcessPageState();
}

class _PackageWithQuantity {
  _PackageWithQuantity(this.package, this.availableStock) : quantity = 0;

  final PackageModel package;
  final int availableStock;
  int quantity;
}

class _SaleProcessPageState extends State<SaleProcessPage> {
  NetworkConnectionModel? _selectedNetwork;
  List<_PackageWithQuantity> _packages = [];
  bool _loadingPackages = false;
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _submitting = false;
  
  // Cache للحسابات لتحسين الأداء
  double? _cachedTotal;
  int? _cachedTotalQuantity;

  @override
  void initState() {
    super.initState();
    // تحميل البيانات المحددة مسبقاً
    if (widget.preselectedNetwork != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPreselectedData();
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreselectedData() async {
    if (widget.preselectedNetwork == null) return;

    setState(() {
      _selectedNetwork = widget.preselectedNetwork;
      _loadingPackages = true;
    });

    await _loadPackages();

    // إذا كان هناك باقة محددة مسبقاً، اضبط الكمية إلى 1
    if (widget.preselectedPackageId != null && _packages.isNotEmpty) {
      final preselectedPackage = _packages.firstWhere(
        (p) => p.package.id == widget.preselectedPackageId,
        orElse: () => _packages.first,
      );

      if (preselectedPackage.availableStock > 0) {
        setState(() {
          preselectedPackage.quantity = 1;
        });
      }
    }
  }

  Future<void> _selectNetwork() async {
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

    final connections = connectionsSnapshot.docs.map(NetworkConnectionModel.fromFirestore).toList();

    if (connections.isEmpty) {
      if (!mounted) return;
      CustomToast.warning(
        context,
        'قم بإضافة شبكة من صفحة الشبكات أولاً',
        title: 'لا توجد شبكات',
      );
      return;
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<NetworkConnectionModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Text(
                      'اختر الشبكة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: connections.length,
                  itemBuilder: (context, index) {
                    final network = connections[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.blue100,
                        child: Icon(
                          Icons.hub,
                          color: AppColors.primary,
                          size: 22.w,
                        ),
                      ),
                      title: Text(
                        network.networkName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(network.networkOwner),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pop(context, network),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedNetwork = selected;
        _packages = [];
        _loadingPackages = true;
      });

      // تحميل الباقات تلقائياً
      await _loadPackages();
    }
  }

  Future<void> _loadPackages() async {
    if (_selectedNetwork == null) return;

    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    try {
      // جلب الباقات المفعلة فقط
      final packagesSnapshot = await FirebasePackageService.getActivePackagesByNetwork(
        _selectedNetwork!.networkId,
      ).first;

      if (packagesSnapshot.isEmpty) {
        if (!mounted) return;
        setState(() {
          _packages = [];
          _loadingPackages = false;
        });
        CustomToast.warning(
          context,
          'الشبكة لم تضف أي باقات بعد',
          title: 'لا توجد باقات متاحة',
        );
        return;
      }

      // جلب المخزون
      final stock = await FirebaseVendorInventoryService.getVendorPackageStock(
        vendorId: vendorId,
        networkId: _selectedNetwork!.networkId,
      );

      setState(() {
        _packages = packagesSnapshot
            .map(
              (pkg) => _PackageWithQuantity(
                pkg,
                stock[pkg.id] ?? 0,
              ),
            )
            .where((p) => p.availableStock > 0)  // ← فقط الباقات التي لديها مخزون
            .toList();
        _loadingPackages = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _packages = [];
        _loadingPackages = false;
      });
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل تحميل الباقات',
      );
    }
  }

  Future<void> _performSale() async {
    if (_selectedNetwork == null) return;

    final selectedPackages = _packages.where((p) => p.quantity > 0).toList();

    if (selectedPackages.isEmpty) {
      CustomToast.warning(
        context,
        'قم باختيار باقة وتحديد الكمية',
        title: 'لم يتم اختيار باقات',
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && _validatePhone(phone) != null) {
      setState(() {});
      return;
    }

    setState(() => _submitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.user?.id ?? '';

      if (vendorId.isEmpty) {
        throw Exception('معرف المتجر غير موجود');
      }

      // إنشاء map للباقات والكميات
      final packageQuantities = <String, int>{};

      for (final pkgWithQty in selectedPackages) {
        packageQuantities[pkgWithQty.package.id] = pkgWithQty.quantity;
      }

      // بيع الكروت من Firebase (جلب أرقام حقيقية وتحديث حالتها وتسجيل البيع)
      final soldCards = await FirebaseSaleService.sellCards(
        vendorId: vendorId,
        networkId: _selectedNetwork!.networkId,
        networkName: _selectedNetwork!.networkName,
        packageQuantities: packageQuantities,
        customerPhone: phone.isNotEmpty ? phone : null,
      );

      if (!mounted) return;

      // عرض النجاح مع أرقام الكروت الحقيقية
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SaleSuccessDialog(
          packageCodes: soldCards,
          total: _calculateTotal(),
          customerPhone: phone.isNotEmpty ? phone : null,
        ),
      );

      // إعادة تعيين
      setState(() {
        _selectedNetwork = null;
        _packages = [];
        _phoneCtrl.clear();
        _submitting = false;
      });
    } on Exception catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل البيع',
      );
    }
  }

  String? _validatePhone(String v) {
    if (v.isEmpty) return null; // اختياري
    if (v.length < 9) return 'رقم غير كامل';
    if (!RegExp(r'^7\d{8}$').hasMatch(v.trim())) return 'رقم غير صالح';
    return null;
  }

  void _invalidateCache() {
    _cachedTotal = null;
    _cachedTotalQuantity = null;
  }

  double _calculateTotal() {
    if (_cachedTotal != null) return _cachedTotal!;
    
    _cachedTotal = _packages.fold<double>(
      0.0,
      (total, p) => total + (p.package.sellingPrice * p.quantity),
    );
    return _cachedTotal!;
  }

  int _getTotalQuantity() {
    if (_cachedTotalQuantity != null) return _cachedTotalQuantity!;
    
    _cachedTotalQuantity = _packages.fold<int>(0, (total, p) => total + p.quantity);
    return _cachedTotalQuantity!;
  }

  bool get _canSell => _selectedNetwork != null && _packages.any((p) => p.quantity > 0) && !_submitting;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          title: const Text('بيع سريع'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. اختيار الشبكة
                      _buildSelectionCard(
                        icon: Icons.hub,
                        title: 'الشبكة',
                        value: _selectedNetwork?.networkName,
                        hint: 'اضغط لاختيار الشبكة',
                        onTap: _selectNetwork,
                      ),

                      if (_selectedNetwork != null) ...[
                        SizedBox(height: 20.h),

                        // 2. قائمة الباقات
                        if (_loadingPackages)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.h),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'جاري تحميل الباقات...',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_packages.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.h),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64.w,
                                    color: AppColors.gray400,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'لا توجد باقات متاحة',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Icon(
                                Icons.wifi,
                                color: AppColors.primary,
                                size: 20.w,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'الباقات المتاحة',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray900,
                                ),
                              ),
                              const Spacer(),
                              if (_getTotalQuantity() > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    'المحدد: ${_getTotalQuantity()}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // قائمة الباقات
                          ..._packages.map(
                            _buildPackageCard,
                          ),

                          SizedBox(height: 16.h),

                          // رقم الهاتف (اختياري)
                          AppCard(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'رقم الهاتف',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gray700,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray100,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        'اختياري',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                // توضيح
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 14.w,
                                      color: AppColors.blue500,
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        'سيتم إرسال أرقام الكروت إلى رقم الهاتف عبر الواتساب',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.blue700,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '771234567',
                                    prefixIcon: Icon(
                                      Icons.phone_android,
                                      size: 20.w,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                    errorText: _phoneCtrl.text.isNotEmpty ? _validatePhone(_phoneCtrl.text) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_getTotalQuantity() > 0) ...[
                            SizedBox(height: 24.h),

                            // ملخص المبلغ
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.1),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        color: AppColors.primary,
                                        size: 24.w,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'ملخص العملية',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gray700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  ..._packages.where((p) => p.quantity > 0).map(
                                        (p) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 8.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  p.package.name,
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    color: AppColors.gray800,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${p.quantity} × ${p.package.sellingPrice.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: AppColors.gray600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  Divider(height: 20.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payments,
                                        color: AppColors.primary,
                                        size: 24.w,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          'المبلغ الإجمالي',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(
                                          _calculateTotal(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // زر البيع الثابت في الأسفل
              if (_getTotalQuantity() > 0)
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: _canSell ? _performSale : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size(double.infinity, 54.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 24),
                              SizedBox(width: 8.w),
                              Text(
                                'إتمام البيع (${_getTotalQuantity()} كرت)',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    String? value,
    String? hint,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: value != null ? AppColors.primary.withValues(alpha: 0.1) : AppColors.gray100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: value != null ? AppColors.primary : AppColors.gray400,
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.gray600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value ?? hint ?? '',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: value != null ? AppColors.gray900 : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16.w,
            color: onTap != null ? AppColors.gray400 : AppColors.gray300,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(_PackageWithQuantity pkgWithQty) {
    final isAvailable = pkgWithQty.availableStock > 0;
    
    // حساب حجم الباقة
    final pkg = pkgWithQty.package;
    final sizeGB = pkg.dataSizeGB > 0 
        ? pkg.dataSizeGB 
        : (pkg.dataSizeMB / 1024);
    final sizeText = sizeGB >= 1 
        ? '${sizeGB.toStringAsFixed(0)} GB' 
        : '${pkg.dataSizeMB} MB';

    return AppCard(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // أيقونة الباقة
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.wifi,
                  color: AppColors.primary,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 12.w),
              
              // معلومات الباقة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        // حجم الباقة
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            sizeText,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue700,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // الصلاحية
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '${pkg.validityDays} يوم',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // السعر
                        Text(
                          '${pkg.sellingPrice.toStringAsFixed(0)} ر.ي',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        // المتوفر
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'متوفر: ${pkgWithQty.availableStock}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
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
          if (isAvailable) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onTap: pkgWithQty.quantity > 0
                      ? () {
                          setState(() {
                            pkgWithQty.quantity--;
                            _invalidateCache();
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: pkgWithQty.quantity > 0 ? AppColors.primary.withValues(alpha: 0.1) : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: pkgWithQty.quantity > 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.gray200,
                      ),
                    ),
                    child: Text(
                      '${pkgWithQty.quantity}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: pkgWithQty.quantity > 0 ? AppColors.primary : AppColors.gray400,
                      ),
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onTap: pkgWithQty.quantity < pkgWithQty.availableStock
                      ? () {
                          setState(() {
                            pkgWithQty.quantity++;
                            _invalidateCache();
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: onTap != null ? AppColors.primary : AppColors.gray200,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 44.w,
          height: 44.w,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onTap != null ? Colors.white : AppColors.gray400,
            size: 22.w,
          ),
        ),
      ),
    );
  }
}

class _SaleSuccessDialog extends StatelessWidget {
  const _SaleSuccessDialog({
    required this.packageCodes,
    required this.total,
    this.customerPhone,
  });

  final Map<String, List<String>> packageCodes;
  final double total;
  final String? customerPhone;

  @override
  Widget build(BuildContext context) {
    final allCodes = packageCodes.values.expand((codes) => codes).toList();
    final totalQuantity = allCodes.length;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 36.w,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'تمت العملية بنجاح!',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '$totalQuantity كرت من ${packageCodes.length} باقة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.gray600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      CurrencyFormatter.format(total),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (customerPhone != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'رقم العميل: $customerPhone',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Codes grouped by package
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أكواد التفعيل',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...packageCodes.entries.map((entry) {
                      final packageName = entry.key;
                      final codes = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Package name
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '$packageName (${codes.length})',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Codes
                          ...codes.map(
                            (code) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: AppColors.gray200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      code,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: code),
                                      );
                                      CustomToast.info(
                                        context,
                                        'تم نسخه إلى الحافظة',
                                        title: 'تم نسخ الكود',
                                      );
                                    },
                                    icon: Icon(
                                      Icons.copy,
                                      size: 18.w,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'نسخ',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (allCodes.length > 1)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: allCodes.join('\n')));
                CustomToast.success(
                  context,
                  'تم نسخ ${allCodes.length} كود إلى الحافظة',
                  title: 'تم نسخ جميع الأكواد',
                );
              },
              icon: const Icon(Icons.copy_all),
              label: const Text('نسخ الكل'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
