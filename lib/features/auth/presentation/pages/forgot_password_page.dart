import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../shared/widgets/app_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthProvider authProvider) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    final success = await authProvider.startPasswordRecovery(phone);

    if (!mounted) return;

    const defaultMessage = 'تعذر إرسال الطلب. يرجى التواصل مع الدعم الفني مباشرة.';
    final message = authProvider.error ?? (success ? 'تم استلام طلبك وسيتواصل معك فريق الدعم قريباً.' : defaultMessage);

    await Fluttertoast.showToast(
      msg: message,
      backgroundColor: success ? AppColors.success : AppColors.error,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );

    if (success) {
      context.go('/login');
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    if (!PhoneUtils.isValidYemeniPhone(value)) {
      return 'أدخل رقم هاتف يمني صالحاً';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 40.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'استعادة كلمة المرور',
                  style: AppTypography.headline.copyWith(color: AppColors.gray900),
                ),
                SizedBox(height: 8.h),
                Text(
                  'الخدمة قيد التطوير حالياً. يرجى إدخال رقم هاتفك وسيتواصل معك فريق الدعم.',
                  style: AppTypography.body.copyWith(color: AppColors.gray600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: AppColors.warning,
                        size: 26.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'كيف يتم التعامل مع طلبك؟',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'سيقوم فريق الدعم بمراجعة الطلب والتواصل معك لتأكيد الهوية وتعيين كلمة مرور جديدة.',
                              style: AppTypography.body.copyWith(
                                color: AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: languageProvider.phone,
                      hintText: '777123456',
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                    ),
                    validator: _validatePhone,
                  ),
                ),
                SizedBox(height: 24.h),
                AppButton(
                  text: 'إرسال الطلب',
                  onPressed: authProvider.isLoading ? null : () => _handleSubmit(authProvider),
                  loading: authProvider.isLoading,
                  fullWidth: true,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: authProvider.isLoading ? null : () => context.go('/login'),
                  child: Text(
                    'العودة لتسجيل الدخول',
                    style: AppTypography.body.copyWith(
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w600,
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
}
