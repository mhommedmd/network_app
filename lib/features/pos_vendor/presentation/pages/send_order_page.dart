import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../../network_owner/data/models/order_item_model.dart';
import '../../../network_owner/data/models/order_model.dart';
import '../../../network_owner/data/models/package_model.dart';
import '../../../network_owner/data/services/firebase_order_service.dart';
import '../../../network_owner/data/services/firebase_package_service.dart';
import '../../data/models/network_connection_model.dart';

/// صفحة إرسال طلب جديد
class SendOrderPage extends StatefulWidget {
  const SendOrderPage({
    this.networkId,
    this.networkName,
    super.key,
  });

  final String? networkId;
  final String? networkName;

  @override
  State<SendOrderPage> createState() => _SendOrderPageState();
}

class _SendOrderPageState extends State<SendOrderPage> {
  // معلومات الشبكة المختارة
  String? _selectedNetworkId;
  String? _selectedNetworkName;

  // Map لحفظ الكمية المطلوبة لكل باقة (packageId -> quantity)
  final Map<String, int> _packageQuantities = {};
  // Map لحفظ TextEditingController لكل باقة
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  
  // Cache للحسابات
  double? _cachedTotalAmount;
  int? _cachedTotalCards;

  @override
  void initState() {
    super.initState();
    // استخدام الشبكة المحددة مسبقاً إن وجدت
    _selectedNetworkId = widget.networkId;
    _selectedNetworkName = widget.networkName;
  }

  @override
  void dispose() {
    // تنظيف جميع الـ controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String packageId) {
    if (!_controllers.containsKey(packageId)) {
      final controller = TextEditingController(text: '0');
      // تأجيل الإضافة إلى ما بعد البناء
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controllers[packageId] = controller;
        }
      });
      return controller;
    }
    return _controllers[packageId]!;
  }

  void _invalidateCache() {
    _cachedTotalAmount = null;
    _cachedTotalCards = null;
  }

  void _onQuantityChanged(String packageId, String value) {
    // تحديث الكمية بدون setState لمنع اختفاء الكيبورد
    final quantity = int.tryParse(value) ?? 0;
    if (quantity > 0) {
      _packageQuantities[packageId] = quantity;
    } else {
      _packageQuantities.remove(packageId);
    }
    _invalidateCache();
  }
  
  void _onQuantitySubmitted(String packageId) {
    // تحديث واجهة المستخدم عند الانتهاء من الإدخال
    setState(() {});
  }

  int _getQuantity(String packageId) {
    return _packageQuantities[packageId] ?? 0;
  }

  double _calculateTotalAmount(List<PackageModel> packages) {
    if (_cachedTotalAmount != null) return _cachedTotalAmount!;
    
    double total = 0;
    for (final pkg in packages) {
      final quantity = _getQuantity(pkg.id);
      if (quantity > 0) {
        total += pkg.purchasePrice * quantity;
      }
    }
    _cachedTotalAmount = total;
    return total;
  }

  int _getTotalCards() {
    if (_cachedTotalCards != null) return _cachedTotalCards!;
    
    _cachedTotalCards = _packageQuantities.values.fold<int>(0, (total, qty) => total + qty);
    return _cachedTotalCards!;
  }

  Future<void> _selectNetwork() async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    if (vendorId.isEmpty) return;

    // جلب الشبكات المضافة
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
        title: 'لا توجد شبكات متاحة',
      );
      return;
    }

    // عرض قائمة الشبكات
    if (!mounted) return;
    final selected = await showModalBottomSheet<NetworkConnectionModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
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
                      child: Icon(Icons.hub, color: AppColors.primary, size: 20.w),
                    ),
                    title: Text(network.networkName),
                    subtitle: Text(network.networkOwner),
                    onTap: () => Navigator.pop(context, network),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedNetworkId = selected.networkId;
        _selectedNetworkName = selected.networkName;
        // إعادة تعيين الكميات عند تغيير الشبكة
        _packageQuantities.clear();
        for (final controller in _controllers.values) {
          controller.text = '0';
        }
        _invalidateCache();
      });
    }
  }

  Future<void> _sendOrder(List<PackageModel> packages) async {
    if (_packageQuantities.isEmpty) {
      CustomToast.warning(
        context,
        'قم باختيار باقة وتحديد الكمية',
        title: 'لم يتم اختيار باقات',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final vendor = authProvider.user;

    if (vendor == null) return;

    setState(() => _isLoading = true);

    try {
      // إنشاء قائمة العناصر
      final items = <OrderItemModel>[];

      for (final pkg in packages) {
        final quantity = _getQuantity(pkg.id);
        if (quantity > 0) {
          items.add(
            OrderItemModel(
              packageId: pkg.id,
              packageName: pkg.name,
              quantity: quantity,
              pricePerCard: pkg.purchasePrice,
              totalAmount: pkg.purchasePrice * quantity,
            ),
          );
        }
      }

      // التأكد من اختيار الشبكة
      if (_selectedNetworkId == null || _selectedNetworkName == null) {
        CustomToast.warning(
          context,
          'اختر الشبكة من القائمة المنسدلة',
          title: 'لم يتم اختيار شبكة',
        );
        setState(() => _isLoading = false);
        return;
      }

      // إنشاء الطلب
      final order = OrderModel(
        id: '',
        vendorId: vendor.id,
        vendorName: vendor.name,
        networkId: _selectedNetworkId!,
        networkName: _selectedNetworkName!,
        items: items,
        totalAmount: _calculateTotalAmount(packages),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirebaseOrderService.createOrder(order);

      if (!mounted) return;
      setState(() => _isLoading = false);

      CustomToast.success(
        context,
        'في انتظار موافقة الشبكة على طلبك',
        title: 'تم إرسال الطلب بنجاح',
      );

      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errorMessage = ErrorHandler.extractErrorMessage(e);
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل إرسال الطلب',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedNetworkName ?? 'طلب كروت',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selectedNetworkId != null)
            IconButton(
              onPressed: _selectNetwork,
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'تغيير الشبكة',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _selectedNetworkId == null
            ? _buildNetworkSelection()
            : StreamBuilder<List<PackageModel>>(
                stream: FirebasePackageService.getActivePackagesByNetwork(
                  _selectedNetworkId!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('خطأ: ${snapshot.error}'),
                    );
                  }

                  final packages = snapshot.data ?? [];

                  if (packages.isEmpty) {
                    return Center(
                      child: AppCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 64.w,
                              color: AppColors.gray400,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'لا توجد باقات متاحة',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // عنوان
                              Text(
                                'اختر الباقات والكميات',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray900,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // قائمة الباقات (تصميم محسّن مع تفاصيل)
                              ...packages.map((pkg) {
                                final quantity = _getQuantity(pkg.id);
                                final isSelected = quantity > 0;
                                
                                // حساب حجم الباقة
                                final sizeGB = pkg.dataSizeGB > 0 
                                    ? pkg.dataSizeGB 
                                    : (pkg.dataSizeMB / 1024);
                                final sizeText = sizeGB >= 1 
                                    ? '${sizeGB.toStringAsFixed(0)} GB' 
                                    : '${pkg.dataSizeMB} MB';

                                return Container(
                                  margin: EdgeInsets.only(bottom: 10.h),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.blue50 : Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.gray200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(14.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // الصف الأول: معلومات الباقة + حقل الإدخال
                                      Row(
                                        children: [
                                          // أيقونة الباقة
                                          Container(
                                            width: 44.w,
                                            height: 44.w,
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
                                                SizedBox(height: 3.h),
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
                                                      CurrencyFormatter.format(pkg.purchasePrice),
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          SizedBox(width: 10.w),
                                          
                                          // حقل إدخال الكمية
                                          Container(
                                            width: 70.w,
                                            height: 44.h,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10.r),
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : AppColors.gray300,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _getController(pkg.id),
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              textInputAction: TextInputAction.next,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected ? AppColors.primary : AppColors.gray700,
                                              ),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                                hintText: '0',
                                                hintStyle: TextStyle(
                                                  color: AppColors.gray400,
                                                  fontSize: 15.sp,
                                                ),
                                              ),
                                              onChanged: (value) => _onQuantityChanged(pkg.id, value),
                                              onSubmitted: (_) => _onQuantitySubmitted(pkg.id),
                                              onTap: () {
                                                // تحديد النص عند الضغط
                                                final controller = _getController(pkg.id);
                                                controller.selection = TextSelection(
                                                  baseOffset: 0,
                                                  extentOffset: controller.text.length,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // الصف الثاني: الكمية والمجموع (يظهر فقط إذا تم اختيار كمية)
                                      if (isSelected) ...[
                                        SizedBox(height: 10.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.shopping_cart_outlined,
                                                    size: 14.w,
                                                    color: AppColors.gray600,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    '$quantity كرت',
                                                    style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.gray700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calculate_outlined,
                                                    size: 14.w,
                                                    color: AppColors.primary,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    CurrencyFormatter.format(pkg.purchasePrice * quantity),
                                                    style: TextStyle(
                                                      fontSize: 13.sp,
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
                                  ),
                                );
                              }),

                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),

                      // الملخص والزر في الأسفل
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ملخص سريع
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.blue50,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'إجمالي الكروت',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.gray700,
                                          ),
                                        ),
                                        Text(
                                          '${_getTotalCards()} كرت',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      height: 16.h,
                                      color: AppColors.gray300,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'المجموع الكلي',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(
                                            _calculateTotalAmount(packages),
                                          ),
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // زر الإرسال
                              AppButton(
                                text: _isLoading ? 'جارِ الإرسال...' : 'إرسال الطلب',
                                size: AppButtonSize.large,
                                onPressed: _isLoading || _packageQuantities.isEmpty ? null : () => _sendOrder(packages),
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNetworkSelection() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub,
              size: 80.w,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 24.h),
            Text(
              'اختر الشبكة',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'اختر الشبكة التي تريد طلب كروت منها',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _selectNetwork,
              icon: const Icon(Icons.hub),
              label: const Text('اختيار الشبكة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
