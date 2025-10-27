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
  });
  final dynamic id; // يمكن أن يكون String أو int
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

  final List<ColorOption> colorOptions = const [
    ColorOption(name: 'أزرق', value: 'blue', preview: AppColors.primary),
    ColorOption(name: 'أخضر', value: 'green', preview: AppColors.success),
    ColorOption(name: 'أحمر', value: 'red', preview: AppColors.error),
    ColorOption(name: 'برتقالي', value: 'orange', preview: AppColors.warning),
    ColorOption(name: 'بنفسجي', value: 'purple', preview: Color(0xFF8b5cf6)),
    ColorOption(name: 'وردي', value: 'pink', preview: Color(0xFFec4899)),
    ColorOption(name: 'أصفر', value: 'yellow', preview: Color(0xFFeab308)),
    ColorOption(name: 'سماوي', value: 'cyan', preview: Color(0xFF06b6d4)),
    ColorOption(name: 'رمادي', value: 'gray', preview: AppColors.gray500),
    ColorOption(name: 'أسود', value: 'black', preview: AppColors.gray900),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _mbController.addListener(_onMbChanged);
    _gbController.addListener(_onGbChanged);
  }

  void _initializeControllers() {
    final pkg = widget.packageData;
    nameController = TextEditingController(text: pkg.name);
    mikrotikNameController = TextEditingController(text: pkg.mikrotikName);
    _salePriceController =
        TextEditingController(text: pkg.sellingPrice.toString());
    _purchasePriceController =
        TextEditingController(text: pkg.purchasePrice.toString());
    _daysController = TextEditingController(text: pkg.validityDays.toString());
    _hoursController = TextEditingController(text: pkg.usageHours.toString());
    _mbController = TextEditingController(text: pkg.dataSizeMB.toString());

    final computedGb = pkg.dataSizeGB > 0
        ? pkg.dataSizeGB.toString()
        : (pkg.dataSizeMB / 1024).toStringAsFixed(2);
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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

  void _handleCancel() => widget.onBack();

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = nameController.text.trim();
    final code = mikrotikNameController.text.trim();
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final mb = int.tryParse(_mbController.text) ?? 0;
    final gb = double.tryParse(_gbController.text) ?? (mb / 1024.0);

    // عرض مؤشر التحميل
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider =
        Provider.of<PackageProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      CustomToast.error(
        context,
        'يرجى تسجيل الدخول للمتابعة',
        title: 'غير مسجل',
      );
      return;
    }

    // إنشاء PackageModel محدث
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
      createdAt: DateTime.now(), // سيتم تجاهله في التحديث
      updatedAt: now,
      isActive: true,
    );

    // حفظ في Firebase
    final success =
        await packageProvider.updatePackage(packageId, updatedPackageModel);

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (success) {
      CustomToast.success(
        context,
        'تم حفظ جميع التعديلات على الباقة',
        title: 'تم تحديث "$name"',
      );

      // استدعاء callback القديم للتوافق
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

  @override
  Widget build(BuildContext context) {
    final hasStock = widget.packageData.stock > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعديل الباقة',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
          onPressed: widget.onBack,
          tooltip: 'رجوع',
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: AppCard(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الباقة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'الرجاء إدخال اسم الباقة'
                              : null,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: mikrotikNameController,
                      decoration: const InputDecoration(
                        labelText: 'رمز الباقة (اسم في نظام الميكروتيك)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'الرجاء إدخال اسم الباقة في النظام'
                              : null,
                    ),
                    SizedBox(height: 12.h),
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
                    SizedBox(height: 8.h),
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
                            decoration: const InputDecoration(
                              labelText: 'الكمية (ميجابايت)',
                              suffixText: 'MB',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (!_editByGb) {
                                final val = int.tryParse(value ?? '');
                                if (val == null || val <= 0) {
                                  return 'أدخل قيمة صالحة';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
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
                            decoration: const InputDecoration(
                              labelText: 'الكمية (جيجابايت)',
                              suffixText: 'GB',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_editByGb) {
                                final val = double.tryParse(value ?? '');
                                if (val == null || val <= 0) {
                                  return 'أدخل قيمة صالحة';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'فترة الاستخدام (بالساعات)',
                        suffixText: 'ساعة',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !hasStock,
                      validator: (value) {
                        final val = int.tryParse(value ?? '');
                        if (val == null || val <= 0) {
                          return 'أدخل قيمة صالحة';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'صلاحية الباقة (بالأيام)',
                        suffixText: 'يوم',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !hasStock,
                      validator: (value) {
                        final val = int.tryParse(value ?? '');
                        if (val == null || val <= 0) {
                          return 'أدخل قيمة صالحة';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    if (hasStock)
                      Container(
                        padding: EdgeInsets.all(12.w),
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'لا يمكن تعديل مدة أو حجم البيانات مع وجود ${widget.packageData.stock} كروت في المخزون.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            decoration: const InputDecoration(
                              labelText: 'سعر الشراء',
                              suffixText: CurrencyFormatter.symbol,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final val = double.tryParse(value ?? '');
                              if (val == null || val <= 0) {
                                return 'أدخل سعرًا صحيحًا';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
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
                            decoration: const InputDecoration(
                              labelText: 'سعر البيع',
                              suffixText: CurrencyFormatter.symbol,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final val = double.tryParse(value ?? '');
                              final buy = double.tryParse(
                                    _purchasePriceController.text,
                                  ) ??
                                  0;
                              if (val == null || val <= 0 || val <= buy) {
                                return 'أدخل سعر بيع أعلى من الشراء';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'اختيار اللون',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.w,
                      children: [
                        for (final option in colorOptions)
                          GestureDetector(
                            onTap: () => setState(() {
                              selectedColor = option.value;
                            }),
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: option.preview,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: option.value == selectedColor
                                      ? AppColors.gray900
                                      : Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 2,
                                    color: Colors.black12,
                                  ),
                                ],
                              ),
                              child: option.value == selectedColor
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _handleCancel,
                            child: const Text('إلغاء'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: const Text('حفظ التعديلات'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
