import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/package_model.dart';
import '../../data/providers/package_provider.dart';

class Package {
  const Package({
    required this.name,
    required this.mikrotikName,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.validityDays,
    required this.usageHours,
    required this.dataSizeGB,
    required this.dataSizeMB,
    required this.color,
    this.id,
    this.stock = 0,
    this.isActive = true,
  });
  final dynamic id;
  final String name;
  final String mikrotikName;
  final double sellingPrice;
  final double purchasePrice;
  final int validityDays;
  final int usageHours;
  final int dataSizeGB;
  final int dataSizeMB;
  final String color;
  final int stock;
  final bool isActive;

  Package copyWith({
    dynamic id,
    String? name,
    String? mikrotikName,
    double? sellingPrice,
    double? purchasePrice,
    int? validityDays,
    int? usageHours,
    int? dataSizeGB,
    int? dataSizeMB,
    String? color,
    int? stock,
    bool? isActive,
  }) {
    return Package(
      id: id ?? this.id,
      name: name ?? this.name,
      mikrotikName: mikrotikName ?? this.mikrotikName,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      validityDays: validityDays ?? this.validityDays,
      usageHours: usageHours ?? this.usageHours,
      dataSizeGB: dataSizeGB ?? this.dataSizeGB,
      dataSizeMB: dataSizeMB ?? this.dataSizeMB,
      color: color ?? this.color,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ColorOption {
  const ColorOption({
    required this.name,
    required this.value,
    required this.preview,
  });
  final String name;
  final String value;
  final Color preview;
}

class EditPackagePage extends StatefulWidget {
  const EditPackagePage({
    required this.packageData,
    required this.onBack,
    required this.onSave,
    super.key,
  });
  final Package packageData;
  final VoidCallback onBack;
  final ValueCallback<Package> onSave;

  @override
  State<EditPackagePage> createState() => _EditPackagePageState();
}

class _EditPackagePageState extends State<EditPackagePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController mikrotikNameController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _daysController;
  late final TextEditingController _hoursController;
  late final TextEditingController _mbController;
  late final TextEditingController _gbController;

  bool _syncing = false;
  bool _editByGb = false;
  late String selectedColor;
  late bool _isActive;

  final List<ColorOption> colorOptions = const [
    ColorOption(name: 'أزرق', value: 'blue', preview: AppColors.primary),
    ColorOption(name: 'أخضر', value: 'green', preview: AppColors.success),
    ColorOption(name: 'أحمر', value: 'red', preview: AppColors.error),
    ColorOption(name: 'برتقالي', value: 'orange', preview: AppColors.warning),
    ColorOption(name: 'بنفسجي', value: 'purple', preview: Color(0xFF8b5cf6)),
    ColorOption(name: 'وردي', value: 'pink', preview: Color(0xFFec4899)),
    ColorOption(name: 'سماوي', value: 'cyan', preview: Color(0xFF06b6d4)),
    ColorOption(name: 'أصفر', value: 'yellow', preview: Color(0xFFeab308)),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _mbController.addListener(_onMbChanged);
    _gbController.addListener(_onGbChanged);
    _isActive = widget.packageData.isActive;
  }

  void _initializeControllers() {
    final pkg = widget.packageData;
    nameController = TextEditingController(text: pkg.name);
    mikrotikNameController = TextEditingController(text: pkg.mikrotikName);
    _salePriceController = TextEditingController(text: pkg.sellingPrice.toString());
    _purchasePriceController = TextEditingController(text: pkg.purchasePrice.toString());
    _daysController = TextEditingController(text: pkg.validityDays.toString());
    _hoursController = TextEditingController(text: pkg.usageHours.toString());
    _mbController = TextEditingController(text: pkg.dataSizeMB.toString());

    final computedGb = pkg.dataSizeGB > 0 ? pkg.dataSizeGB.toString() : (pkg.dataSizeMB / 1024).toStringAsFixed(2);
    _gbController = TextEditingController(
      text: computedGb == '0.00' ? '' : computedGb,
    );

    selectedColor = _resolveColorOption(pkg.color).value;
    _editByGb = pkg.dataSizeGB > 0 && pkg.dataSizeMB == 0;
  }

  @override
  void dispose() {
    _mbController.removeListener(_onMbChanged);
    _gbController.removeListener(_onGbChanged);
    nameController.dispose();
    mikrotikNameController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    _mbController.dispose();
    _gbController.dispose();
    super.dispose();
  }

  ColorOption _resolveColorOption(String value) {
    return colorOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => colorOptions.first,
    );
  }

  void _onMbChanged() {
    if (_syncing || _editByGb) return;
    _syncing = true;
    final mb = int.tryParse(_mbController.text) ?? 0;
    final gb = (mb / 1024).toStringAsFixed(2);
    _gbController.value = TextEditingValue(
      text: gb,
      selection: TextSelection.collapsed(offset: gb.length),
    );
    _syncing = false;
  }

  void _onGbChanged() {
    if (_syncing || !_editByGb) return;
    _syncing = true;
    final gb = double.tryParse(_gbController.text) ?? 0.0;
    final mb = (gb * 1024).round().toString();
    _mbController.value = TextEditingValue(
      text: mb,
      selection: TextSelection.collapsed(offset: mb.length),
    );
    _syncing = false;
  }

  Future<void> _togglePackageStatus() async {
    final newStatus = !_isActive;
    final statusText = newStatus ? 'تفعيل' : 'إيقاف';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$statusText الباقة'),
        content: Text(
          newStatus
              ? 'هل تريد تفعيل الباقة "${widget.packageData.name}"؟\n\nستظهر للمتاجر ويمكنهم طلب كروت منها.'
              : 'هل تريد إيقاف الباقة "${widget.packageData.name}"؟\n\nلن تظهر للمتاجر ولن يستطيعوا طلب كروت جديدة منها.\n\n⚠️ ملاحظة: الكروت الموجودة لدى المتاجر سابقاً لن تتأثر.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? AppColors.success : AppColors.warning,
            ),
            child: Text(statusText),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!mounted) return;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      final packageProvider = Provider.of<PackageProvider>(context, listen: false);
      final packageId = widget.packageData.id?.toString() ?? '';

      final success = await packageProvider.togglePackageStatus(
        packageId,
        isActive: newStatus,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        setState(() => _isActive = newStatus);
        CustomToast.success(
          context,
          newStatus ? 'الباقة مفعلة الآن' : 'الباقة متوقفة الآن',
          title: 'تم $statusText الباقة',
        );
      } else {
        CustomToast.error(
          context,
          ErrorHandler.extractErrorMessage(
            packageProvider.error ?? 'فشل في $statusText الباقة',
          ),
          title: 'فشلت العملية',
        );
      }
    }
  }

  Future<void> _deletePackage() async {
    final hasStock = widget.packageData.stock > 0;

    if (hasStock) {
      CustomToast.error(
        context,
        'يجب حذف جميع الكروت من المخزون أولاً (${widget.packageData.stock} كرت متبقي)',
        title: 'لا يمكن حذف الباقة',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28.w),
            SizedBox(width: 10.w),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف الباقة "${widget.packageData.name}"؟\n\nهذا الإجراء لا يمكن التراجع عنه!',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
      if (!mounted) return;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      final packageProvider = Provider.of<PackageProvider>(context, listen: false);
      final packageId = widget.packageData.id?.toString() ?? '';

      final success = await packageProvider.deletePackage(packageId);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        CustomToast.success(
          context,
          'تم حذف الباقة من النظام',
          title: 'تم الحذف بنجاح',
        );
        widget.onBack();
      } else {
        CustomToast.error(
          context,
          ErrorHandler.extractErrorMessage(
            packageProvider.error ?? 'فشل في حذف الباقة',
          ),
          title: 'فشل الحذف',
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = nameController.text.trim();
    final code = mikrotikNameController.text.trim();
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final mb = int.tryParse(_mbController.text) ?? 0;
    final gb = _editByGb ? double.tryParse(_gbController.text) ?? 0.0 : mb / 1024.0;

    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider = Provider.of<PackageProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      CustomToast.error(
        context,
        'يرجى تسجيل الدخول للمتابعة',
        title: 'غير مسجل',
      );
      return;
    }

    final now = DateTime.now();
    final packageId = widget.packageData.id?.toString() ?? '';

    final updatedPackageModel = PackageModel(
      id: packageId,
      name: name,
      mikrotikName: code,
      sellingPrice: salePrice,
      purchasePrice: purchasePrice,
      validityDays: days,
      usageHours: hours,
      dataSizeGB: gb.toInt(),
      dataSizeMB: mb,
      color: selectedColor,
      stock: widget.packageData.stock,
      networkId: currentUser.id,
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: now,
      isActive: _isActive,
    );

    final success = await packageProvider.updatePackage(packageId, updatedPackageModel);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (success) {
      CustomToast.success(
        context,
        'تم حفظ جميع التعديلات على الباقة',
        title: 'تم تحديث "$name"',
      );

      final updated = widget.packageData.copyWith(
        name: name,
        mikrotikName: code,
        sellingPrice: salePrice,
        purchasePrice: purchasePrice,
        validityDays: days,
        usageHours: hours,
        dataSizeMB: mb,
        dataSizeGB: gb.round(),
        color: selectedColor,
        isActive: _isActive,
      );
      widget.onSave(updated);
    } else {
      final errorMessage = ErrorHandler.extractErrorMessage(
        packageProvider.error ?? 'فشل في تحديث الباقة',
      );
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل التحديث',
      );
    }
  }

  Widget _buildTogglePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final background = selected ? AppColors.primary : AppColors.gray200;
    final foreground = selected ? Colors.white : AppColors.gray600;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22.w,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStock = widget.packageData.stock > 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(
          'تعديل الباقة',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C2B33),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF1C2B33),
          onPressed: widget.onBack,
          tooltip: 'رجوع',
        ),
        actions: [
          // زر الإيقاف/التفعيل
          IconButton(
            icon: Icon(
              _isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
            ),
            color: const Color(0xFF1C2B33),
            onPressed: _togglePackageStatus,
            tooltip: _isActive ? 'إيقاف الباقة' : 'تفعيل الباقة',
          ),
          // زر الحذف
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: const Color(0xFF1C2B33),
            onPressed: _deletePackage,
            tooltip: 'حذف الباقة',
          ),
        ],
      ),
      body: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // بطاقة حالة الباقة
                  if (!_isActive || hasStock)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: !_isActive ? AppColors.warning.withValues(alpha: 0.1) : AppColors.blue100,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: !_isActive ? AppColors.warning.withValues(alpha: 0.3) : AppColors.blue300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !_isActive ? Icons.pause_circle : Icons.inventory_2,
                            color: !_isActive ? AppColors.warning : AppColors.blue500,
                            size: 24.w,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isActive)
                                  Text(
                                    'الباقة متوقفة حالياً',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warningDark,
                                    ),
                                  ),
                                if (!_isActive)
                                  Text(
                                    'لن تظهر للمتاجر ولا يمكنهم طلب كروت منها',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                if (hasStock && _isActive)
                                  Text(
                                    'المخزون: ${widget.packageData.stock} كرت',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.blue500,
                                    ),
                                  ),
                                if (hasStock && _isActive)
                                  Text(
                                    'لا يمكن تعديل الحجم والصلاحية مع وجود كروت',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // بطاقة المعلومات الأساسية
                  AppCard(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.info_outline,
                          title: 'المعلومات الأساسية',
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 20.h),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'اسم الباقة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'الرجاء إدخال اسم الباقة' : null,
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: mikrotikNameController,
                          decoration: InputDecoration(
                            labelText: 'رمز الباقة (Mikrotik)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'الرجاء إدخال رمز الباقة' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // بطاقة حجم البيانات والصلاحية
                  AppCard(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.data_usage,
                          title: 'حجم البيانات والصلاحية',
                          color: AppColors.blue500,
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Text(
                              'طريقة الإدخال:',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _buildTogglePill(
                              label: 'ميجابايت',
                              selected: !_editByGb,
                              onTap: () => setState(() {
                                _editByGb = false;
                                _onMbChanged();
                              }),
                            ),
                            SizedBox(width: 8.w),
                            _buildTogglePill(
                              label: 'جيجابايت',
                              selected: _editByGb,
                              onTap: () => setState(() {
                                _editByGb = true;
                                _onGbChanged();
                              }),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mbController,
                                enabled: !_editByGb && !hasStock,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'الكمية (MB)',
                                  suffixText: 'MB',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: (_editByGb || hasStock) ? AppColors.gray100 : Colors.white,
                                ),
                                validator: (value) {
                                  if (!_editByGb) {
                                    final val = int.tryParse(value ?? '');
                                    if (val == null || val <= 0) {
                                      return 'قيمة غير صحيحة';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: TextFormField(
                                controller: _gbController,
                                enabled: _editByGb && !hasStock,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^[0-9]*\.?[0-9]*$'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'الكمية (GB)',
                                  suffixText: 'GB',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: (!_editByGb || hasStock) ? AppColors.gray100 : Colors.white,
                                ),
                                validator: (value) {
                                  if (_editByGb) {
                                    final val = double.tryParse(value ?? '');
                                    if (val == null || val <= 0) {
                                      return 'قيمة غير صحيحة';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _hoursController,
                                enabled: !hasStock,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'فترة الاستخدام (اختياري)',
                                  hintText: 'اتركه فارغاً للاستخدام المفتوح',
                                  suffixText: 'ساعة',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: hasStock ? AppColors.gray100 : Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null; // اختياري
                                  }
                                  final val = int.tryParse(value);
                                  if (val == null || val <= 0) {
                                    return 'أدخل قيمة صحيحة أو اتركه فارغاً';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: TextFormField(
                                controller: _daysController,
                                enabled: !hasStock,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'الصلاحية',
                                  suffixText: 'يوم',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: hasStock ? AppColors.gray100 : Colors.white,
                                ),
                                validator: (value) {
                                  final val = int.tryParse(value ?? '');
                                  if (val == null || val <= 0) {
                                    return 'قيمة غير صحيحة';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // بطاقة الأسعار
                  AppCard(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.payments_outlined,
                          title: 'الأسعار',
                          color: AppColors.success,
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _purchasePriceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^[0-9]*\.?[0-9]*$'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'سعر الشراء',
                                  suffixText: CurrencyFormatter.symbol,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  final val = double.tryParse(value ?? '');
                                  if (val == null || val <= 0) {
                                    return 'أدخل سعراً صحيحاً';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: TextFormField(
                                controller: _salePriceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^[0-9]*\.?[0-9]*$'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'سعر البيع',
                                  suffixText: CurrencyFormatter.symbol,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  final val = double.tryParse(value ?? '');
                                  final buy = double.tryParse(
                                        _purchasePriceController.text,
                                      ) ??
                                      0;
                                  if (val == null || val <= 0 || val <= buy) {
                                    return 'أدخل سعراً أعلى من الشراء';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // بطاقة المظهر
                  AppCard(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.palette_outlined,
                          title: 'المظهر والتخصيص',
                          color: AppColors.warning,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'اختيار اللون',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children: [
                            for (final option in colorOptions)
                              GestureDetector(
                                onTap: () => setState(() {
                                  selectedColor = option.value;
                                }),
                                child: Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    color: option.preview,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: option.value == selectedColor ? AppColors.gray900 : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: option.preview.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: option.value == selectedColor
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20.w,
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onBack,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            side: const BorderSide(color: AppColors.gray300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.save_outlined, size: 20.w),
                          label: Text(
                            'حفظ التعديلات',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
