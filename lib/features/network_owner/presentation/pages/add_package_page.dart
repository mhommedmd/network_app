import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/package_model.dart';
import '../../data/providers/package_provider.dart';

class AddPackagePage extends StatefulWidget {
  const AddPackagePage({
    required this.onBack,
    required this.onSave,
    super.key,
  });

  final VoidCallback onBack;
  final JsonMapCallback onSave;

  @override
  State<AddPackagePage> createState() => _AddPackagePageState();
}

class _AddPackagePageState extends State<AddPackagePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _mbController = TextEditingController();
  final _gbController = TextEditingController();
  final _hoursController = TextEditingController();
  final _daysController = TextEditingController();
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;

  Color _selectedColor = AppColors.primary;
  IconData _selectedIcon = Icons.wifi;
  bool _syncing = false;
  bool _editByGb = false;

  @override
  void initState() {
    super.initState();
    _mbController.addListener(_onMbChanged);
    _gbController.addListener(_onGbChanged);
    _purchasePriceController = TextEditingController();
    _salePriceController = TextEditingController();
  }

  @override
  void dispose() {
    _mbController.removeListener(_onMbChanged);
    _gbController.removeListener(_onGbChanged);
    _nameController.dispose();
    _codeController.dispose();
    _mbController.dispose();
    _gbController.dispose();
    _hoursController.dispose();
    _daysController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  void _onMbChanged() {
    if (_syncing) return;
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
    if (_syncing) return;
    _syncing = true;
    final gb = double.tryParse(_gbController.text) ?? 0.0;
    final mb = (gb * 1024).round().toString();
    _mbController.value = TextEditingValue(
      text: mb,
      selection: TextSelection.collapsed(offset: mb.length),
    );
    _syncing = false;
  }

  String _colorToString(Color color) {
    if (color == AppColors.primary) return 'blue';
    if (color == AppColors.error) return 'red';
    if (color == AppColors.warning) return 'orange';
    if (color == AppColors.success) return 'green';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.brown) return 'brown';
    return 'blue';
  }

  void _onCancel() => widget.onBack();

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final mb = int.tryParse(_mbController.text) ?? 0;
    final gb = _editByGb ? double.tryParse(_gbController.text) ?? 0.0 : mb / 1024.0;
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
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
    final package = PackageModel(
      id: '',
      name: name,
      mikrotikName: code,
      sellingPrice: salePrice,
      purchasePrice: purchasePrice,
      validityDays: days,
      usageHours: hours,
      dataSizeGB: gb.toInt(),
      dataSizeMB: mb,
      color: _colorToString(_selectedColor),
      stock: 0,
      iconCodePoint: _selectedIcon.codePoint.toString(),
      iconFontFamily: _selectedIcon.fontFamily,
      iconFontPackage: _selectedIcon.fontPackage,
      networkId: currentUser.id,
      createdBy: currentUser.id,
      createdAt: now,
      updatedAt: now,
    );

    final success = await packageProvider.addPackage(package);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (success) {
      CustomToast.success(
        context,
        'يمكنك الآن بيع هذه الباقة للمتاجر',
        title: 'تم إضافة "$name"',
      );
      widget.onSave({
        'name': name,
        'mikrotikName': code,
      });
    } else {
      final errorMessage = ErrorHandler.extractErrorMessage(
        packageProvider.error ?? 'فشل في حفظ الباقة',
      );
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل حفظ الباقة',
      );
    }
  }

  Widget _buildTogglePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bg = selected ? AppColors.primary : AppColors.gray200;
    final fg = selected ? Colors.white : AppColors.gray600;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
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
    final colorOptions = <Color>[
      AppColors.primary,
      AppColors.success,
      AppColors.error,
      AppColors.warning,
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.pink,
    ];

    final iconOptions = <IconData>[
      Icons.wifi,
      Icons.data_usage,
      Icons.bolt,
      Icons.speed,
      Icons.cell_tower,
      Icons.sim_card,
      Icons.card_giftcard,
      Icons.star,
      Icons.diamond,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة باقة جديدة',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.info_outline,
                    title: 'المعلومات الأساسية',
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الباقة',
                      hintText: 'مثال: باقة 10 جيجا',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء إدخال اسم الباقة' : null,
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'رمز الباقة (Mikrotik)',
                      hintText: 'مثال: 10GB_30Days',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء إدخال رمز الباقة' : null,
                  ),
                  SizedBox(height: 20.h),
                  _buildSectionHeader(
                    icon: Icons.data_usage,
                    title: 'حجم البيانات والصلاحية',
                    color: AppColors.blue500,
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
                        onTap: () => setState(() => _editByGb = false),
                      ),
                      SizedBox(width: 8.w),
                      _buildTogglePill(
                        label: 'جيجابايت',
                        selected: _editByGb,
                        onTap: () => setState(() => _editByGb = true),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mbController,
                          enabled: !_editByGb,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'الكمية (ميجابايت)',
                            suffixText: 'MB',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          validator: (v) {
                            if (!_editByGb) {
                              final val = int.tryParse(v ?? '');
                              if (val == null || val <= 0) {
                                return 'أدخل قيمة صحيحة';
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
                          enabled: _editByGb,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*\.?[0-9]*$'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'الكمية (جيجابايت)',
                            suffixText: 'GB',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          validator: (v) {
                            if (_editByGb) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) {
                                return 'أدخل قيمة صحيحة';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hoursController,
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
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return null;
                            }
                            final val = int.tryParse(v);
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
                          ),
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0) {
                              return 'أدخل قيمة صحيحة';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _buildSectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'الأسعار',
                    color: AppColors.success,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*\.?[0-9]*$'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'سعر الشراء',
                            suffixText: 'ر.ي',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val < 0) {
                              return 'أدخل سعر صحيح';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _salePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*\.?[0-9]*$'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'سعر البيع',
                            suffixText: 'ر.ي',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0) {
                              return 'أدخل سعر صحيح';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Builder(
                    builder: (context) {
                      final buy = double.tryParse(_purchasePriceController.text) ?? 0;
                      final sell = double.tryParse(_salePriceController.text) ?? 0;
                      if (sell > 0 && buy > 0 && sell < buy) {
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 20.w,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'تنبيه: سعر البيع أقل من سعر الشراء',
                                  style: TextStyle(
                                    color: AppColors.warningDark,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 20.h),
                  _buildSectionHeader(
                    icon: Icons.palette_outlined,
                    title: 'المظهر والتخصيص',
                    color: AppColors.warning,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'اختيار اللون',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: [
                      for (final c in colorOptions)
                        GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == c ? AppColors.gray900 : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _selectedColor == c
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
                  SizedBox(height: 16.h),
                  Text(
                    'اختيار الأيقونة',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      for (final ic in iconOptions)
                        GestureDetector(
                          onTap: () => setState(() => _selectedIcon = ic),
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: _selectedIcon == ic ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: _selectedIcon == ic ? AppColors.primary : AppColors.gray300,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              ic,
                              color: _selectedIcon == ic ? AppColors.primary : AppColors.gray600,
                              size: 24.w,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onCancel,
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
                      SizedBox(width: 10.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.add_circle_outline, size: 20.w),
                          label: Text(
                            'إضافة الباقة',
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
