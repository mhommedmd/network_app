import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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
    for (var controller in _controllers.values) {
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

  void _updateQuantity(String packageId, int quantity) {
    if (!_controllers.containsKey(packageId)) {
      // إنشاء الـ controller أولاً إذا لم يكن موجوداً
      _controllers[packageId] = TextEditingController(text: '0');
    }

    setState(() {
      if (quantity > 0) {
        _packageQuantities[packageId] = quantity;
      } else {
        _packageQuantities.remove(packageId);
      }
      _controllers[packageId]!.text = quantity.toString();
    });
  }

  void _onQuantityChanged(String packageId, String value) {
    final quantity = int.tryParse(value) ?? 0;
    setState(() {
      if (quantity > 0) {
        _packageQuantities[packageId] = quantity;
      } else {
        _packageQuantities.remove(packageId);
      }
    });
  }

  int _getQuantity(String packageId) {
    return _packageQuantities[packageId] ?? 0;
  }

  double _calculateTotalAmount(List<PackageModel> packages) {
    double total = 0;
    for (var pkg in packages) {
      final quantity = _getQuantity(pkg.id);
      if (quantity > 0) {
        total += pkg.purchasePrice * quantity;
      }
    }
    return total;
  }

  int _getTotalCards() {
    return _packageQuantities.values.fold(0, (sum, qty) => sum + qty);
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

    final connections = connectionsSnapshot.docs
        .map((doc) => NetworkConnectionModel.fromFirestore(doc))
        .toList();

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
                      child:
                          Icon(Icons.hub, color: AppColors.primary, size: 20.w),
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
        for (var controller in _controllers.values) {
          controller.text = '0';
        }
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

      for (var pkg in packages) {
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
    } catch (e) {
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
                stream: FirebasePackageService.getPackagesByNetwork(
                    _selectedNetworkId!),
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

                              // قائمة الباقات
                              ...packages.map((pkg) {
                                final quantity = _getQuantity(pkg.id);
                                final isSelected = quantity > 0;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.blue50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.gray200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // معلومات الباقة
                                      Row(
                                        children: [
                                          Container(
                                            width: 50.w,
                                            height: 50.w,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.wifi,
                                                color: AppColors.primary,
                                                size: 24.w,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pkg.name,
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  'السعر: ${CurrencyFormatter.format(pkg.purchasePrice)}',
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 12.h),
                                      Divider(
                                          color: AppColors.gray200, height: 1),
                                      SizedBox(height: 12.h),

                                      // محدد الكمية
                                      Row(
                                        children: [
                                          Text(
                                            'الكمية:',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.gray700,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Container(
                                              height: 50.h,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.gray300,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // زر الإنقاص
                                                  IconButton(
                                                    onPressed: () {
                                                      if (quantity > 0) {
                                                        _updateQuantity(pkg.id,
                                                            quantity - 1);
                                                      }
                                                    },
                                                    icon: const Icon(Icons
                                                        .remove_circle_outline),
                                                    color: quantity > 0
                                                        ? AppColors.primary
                                                        : AppColors.gray300,
                                                    iconSize: 24.w,
                                                  ),

                                                  // حقل الإدخال
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          _getController(
                                                              pkg.id),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 18.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : AppColors.gray900,
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        hintText: '0',
                                                      ),
                                                      onChanged: (value) =>
                                                          _onQuantityChanged(
                                                              pkg.id, value),
                                                    ),
                                                  ),

                                                  // زر الزيادة
                                                  IconButton(
                                                    onPressed: () {
                                                      _updateQuantity(
                                                          pkg.id, quantity + 1);
                                                    },
                                                    icon: const Icon(Icons
                                                        .add_circle_outline),
                                                    color: AppColors.primary,
                                                    iconSize: 24.w,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // المجموع الفرعي
                                      if (isSelected) ...[
                                        SizedBox(height: 8.h),
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'المجموع الفرعي',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: AppColors.gray700,
                                                ),
                                              ),
                                              Text(
                                                CurrencyFormatter.format(
                                                    pkg.purchasePrice *
                                                        quantity),
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                        height: 16.h, color: AppColors.gray300),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                              _calculateTotalAmount(packages)),
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
                                text: _isLoading
                                    ? 'جارِ الإرسال...'
                                    : 'إرسال الطلب',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.large,
                                onPressed:
                                    _isLoading || _packageQuantities.isEmpty
                                        ? null
                                        : () => _sendOrder(packages),
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send,
                                        color: Colors.white),
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
