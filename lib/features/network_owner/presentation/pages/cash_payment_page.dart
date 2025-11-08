import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/cash_payment_request_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/providers/vendor_provider.dart';
import '../../data/services/firebase_cash_payment_service.dart';

class NetworkCashPaymentPage extends StatelessWidget {
  const NetworkCashPaymentPage({
    required this.onBack,
    this.onSubmit,
    super.key,
  });

  final VoidCallback onBack;
  final void Function(VendorModel vendor, double amount, String note)? onSubmit;

  @override
  Widget build(BuildContext context) {
    final networkId = context.select((AuthProvider p) => p.user?.id ?? '');

    return ChangeNotifierProvider(
      create: (_) => VendorProvider(networkId),
      child: _NetworkCashPaymentContent(
        onBack: onBack,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _NetworkCashPaymentContent extends StatefulWidget {
  const _NetworkCashPaymentContent({
    required this.onBack,
    this.onSubmit,
  });

  final VoidCallback onBack;
  final void Function(VendorModel vendor, double amount, String note)? onSubmit;

  @override
  State<_NetworkCashPaymentContent> createState() => _NetworkCashPaymentContentState();
}

class _NetworkCashPaymentContentState extends State<_NetworkCashPaymentContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  VendorModel? _selectedVendor;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVendor == null) {
      CustomToast.warning(
        context,
        'اختر المتجر من القائمة المنسدلة',
        title: 'لم يتم اختيار متجر',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id;

    if (networkId == null) {
      CustomToast.error(
        context,
        'يرجى تسجيل الدخول للمتابعة',
        title: 'غير مسجل',
      );
      return;
    }

    final parsedAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    setState(() => _submitting = true);

    try {
      final networkName = authProvider.user?.networkName ?? authProvider.user?.name ?? 'الشبكة';

      // إنشاء طلب الدفعة
      final paymentRequest = CashPaymentRequestModel(
        id: '',
        networkId: networkId,
        networkName: networkName,
        vendorId: _selectedVendor!.id,
        vendorName: _selectedVendor!.name,
        amount: parsedAmount,
        note: _noteController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // حفظ في Firebase
      await FirebaseCashPaymentService.createPaymentRequest(paymentRequest);

      // استدعاء callback إذا وُجد
      widget.onSubmit?.call(
        _selectedVendor!,
        parsedAmount,
        _noteController.text.trim(),
      );

      if (!mounted) return;

      CustomToast.success(
        context,
        'تم إرسال الطلب إلى ${_selectedVendor!.name}',
        title: 'تم إرسال دفعة ${parsedAmount.toStringAsFixed(0)} ر.ي',
      );

      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        widget.onBack();
      }
    } on Exception catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorHandler.extractErrorMessage(e.toString());
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل إرسال الطلب',
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final vendors = vendorProvider.vendors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تسجيل دفعه نقدية',
          style: AppTypography.subheadline.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اختر المتجر',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (vendorProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<VendorModel>(
                      initialValue: _selectedVendor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                      ),
                      hint: Text(
                        vendors.isEmpty ? 'لا توجد متاجر مضافة' : 'اختر المتجر المستلم',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.gray500,
                        ),
                      ),
                      items: vendors
                          .map(
                            (vendor) => DropdownMenuItem<VendorModel>(
                              value: vendor,
                              child: Text(
                                vendor.name,
                                style: AppTypography.body.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.gray800,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: vendors.isEmpty
                          ? null
                          : (vendor) => setState(() {
                                _selectedVendor = vendor;
                              }),
                      validator: (value) => value == null ? 'يرجى اختيار المتجر' : null,
                    ),
                  SizedBox(height: 20.h),
                  Text(
                    'قيمة الدفعه النقدية',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'مثال: 15000',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال قيمة الدفعه';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'يرجى إدخال قيمة صحيحة أكبر من صفر';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'بيان الدفعه النقدية',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'أدخل تفاصيل الدفعه أو ملاحظات إضافية',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى كتابة بيان الدفعه';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : widget.onBack,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: const BorderSide(color: AppColors.gray300),
                          ),
                          child: Text(
                            'إلغاء',
                            style: AppTypography.body.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.gray600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: _submitting
                              ? SizedBox(
                                  height: 18.w,
                                  width: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'إرسال',
                                  style: AppTypography.body.copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  AppCard(
                    variant: AppCardVariant.outlined,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(14.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20.w,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'سيتم إرسال طلب موافقة للمتجر، وستُضاف المعاملة بحالة "انتظار الموافقة" حتى يتم تأكيدها.',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
