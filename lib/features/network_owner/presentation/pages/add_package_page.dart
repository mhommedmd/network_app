import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
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
  bool _editByGb = false; // false: edit MB, true: edit GB

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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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

  void _onCancel() => widget.onBack();

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final mb = int.tryParse(_mbController.text) ?? 0;
    final gb = double.tryParse(_gbController.text) ?? (mb / 1024.0);
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;

    // عرض مؤشر التحميل
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // حفظ في Firebase
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

    final now = DateTime.now();
    final package = PackageModel(
      id: '', // سيتم توليده من Firestore
      name: name,
      mikrotikName: code,
      sellingPrice: salePrice,
      purchasePrice: purchasePrice,
      validityDays: days,
      usageHours: hours,
      dataSizeGB: gb.toInt(),
      dataSizeMB: mb,
      color: _colorToString(_selectedColor),
      stock: 0, // المخزون صفر عند الإنشاء
      iconCodePoint: _selectedIcon.codePoint.toString(),
      iconFontFamily: _selectedIcon.fontFamily,
      iconFontPackage: _selectedIcon.fontPackage,
      networkId: currentUser.id,
      createdBy: currentUser.id,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    final success = await packageProvider.addPackage(package);

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

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

  @override
  Widget build(BuildContext context) {
    final colorOptions = <Color>[
      AppColors.primary,
      AppColors.error,
      AppColors.warning,
      AppColors.success,
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.brown,
    ];
    final iconOptions = <IconData>[
      Icons.wifi,
      Icons.data_usage,
      Icons.bolt,
      Icons.speed,
      Icons.stacked_bar_chart,
      Icons.cell_tower,
      Icons.sim_card,
      Icons.star,
      Icons.card_giftcard,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة باقة جديدة',
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
                    // حقل اسم الباقة
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الباقة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الرجاء إدخال اسم الباقة'
                          : null,
                    ),
                    SizedBox(height: 12.h),

                    // حقل رمز الباقة (اسم في الميكروتيك)
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'رمز الباقة (اسم في نظام الميكروتيك)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الرجاء إدخال رمز/اسم الباقة في نظام الميكروتيك'
                          : null,
                    ),
                    SizedBox(height: 12.h),

                    // اختيار طريقة الإدخال (MB أو GB)
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
                    SizedBox(height: 8.h),

                    // كمية الباقة بالميجابايت والجيجابايت
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
                            decoration: const InputDecoration(
                              labelText: 'الكمية (ميجابايت)',
                              suffixText: 'MB',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (!_editByGb) {
                                final val = int.tryParse(v ?? '');
                                if (val == null || val <= 0) {
                                  return 'أدخل قيمة أكبر من صفر';
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
                            enabled: _editByGb,
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
                            validator: (v) {
                              if (_editByGb) {
                                final val = double.tryParse(v ?? '');
                                if (val == null || val <= 0) {
                                  return 'أدخل قيمة أكبر من صفر';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // فترة الاستخدام بالساعات
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
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) {
                          return 'أدخل عدد ساعات صحيح';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),

                    // صلاحية الباقة بالأيام
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
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) {
                          return 'أدخل عدد أيام صحيح';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // أسعار الشراء والبيع
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
                              suffixText: 'ر.ي',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val < 0) {
                                return 'أدخل سعر شراء صحيح';
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
                              suffixText: 'ر.ي',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) {
                                return 'أدخل سعر بيع صحيح (> 0)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    // تنبيه تلقائي إذا كان سعر البيع أقل من الشراء
                    Builder(
                      builder: (context) {
                        final buy =
                            double.tryParse(_purchasePriceController.text) ?? 0;
                        final sell =
                            double.tryParse(_salePriceController.text) ?? 0;
                        if (sell > 0 && buy > 0 && sell < buy) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    'تنبيه: سعر البيع أقل من سعر الشراء',
                                    style: TextStyle(
                                      color: Colors.orange[800],
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

                    SizedBox(height: 16.h),

                    // اختيار لون الباقة
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
                        for (final c in colorOptions)
                          GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == c
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
                              child: _selectedColor == c
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          ),
                      ],
                    ),

                    // اختيار أيقونة الباقة
                    Text(
                      'اختيار الأيقونة',
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
                        for (final ic in iconOptions)
                          GestureDetector(
                            onTap: () => setState(() => _selectedIcon = ic),
                            child: Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: _selectedIcon == ic
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                ),
                              ),
                              child: Icon(
                                ic,
                                color: _selectedIcon == ic
                                    ? AppColors.primary
                                    : AppColors.gray600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // أزرار الإجراءات
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onCancel,
                            child: const Text('إلغاء'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: const Text('حفظ'),
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
