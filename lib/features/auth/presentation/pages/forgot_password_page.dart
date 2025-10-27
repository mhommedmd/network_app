import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/widgets/app_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _newPasswordFormKey = GlobalKey<FormState>();

  late final TextEditingController _phoneController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _otpVerified = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleNext(AuthProvider authProvider) async {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      // خطوة 1: إدخال رقم الهاتف
      if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

      final phone = _phoneController.text.trim();
      final started = await authProvider.startPasswordRecovery(phone);

      if (!mounted) return;

      if (started) {
        await Fluttertoast.showToast(
          msg:
              'تم إرسال كود التحقق (ملاحظة: قيد التطوير - تحقق من Debug Console)',
          backgroundColor: AppColors.success,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        if (!mounted) return;
        setState(() => _currentStep = 1);
      } else if (authProvider.error != null) {
        await Fluttertoast.showToast(
          msg: authProvider.error!,
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
      }
      return;
    }

    if (_currentStep == 1) {
      // خطوة 2: التحقق من الكود
      if (!(_otpFormKey.currentState?.validate() ?? false)) return;

      final phone = _phoneController.text.trim();
      final otp = _otpController.text.trim();
      final verified = authProvider.verifyPasswordResetOtp(phone, otp);

      if (!mounted) return;

      if (verified) {
        setState(() {
          _otpVerified = true;
          _currentStep = 2;
        });
        await Fluttertoast.showToast(
          msg: 'تم التحقق من الكود بنجاح ✓',
          backgroundColor: AppColors.success,
          textColor: Colors.white,
        );
      } else if (authProvider.error != null) {
        await Fluttertoast.showToast(
          msg: authProvider.error!,
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
      }
      return;
    }

    if (_currentStep == 2) {
      // خطوة 3: تعيين كلمة المرور الجديدة
      if (!(_newPasswordFormKey.currentState?.validate() ?? false)) return;

      final phone = _phoneController.text.trim();
      final otp = _otpController.text.trim();
      final newPassword = _newPasswordController.text;

      final success = await authProvider.completePasswordReset(
        phone: phone,
        otp: otp,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (success) {
        await Fluttertoast.showToast(
          msg: 'تم إعادة تعيين كلمة المرور بنجاح ✓\nيمكنك الآن تسجيل الدخول',
          backgroundColor: AppColors.success,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        if (!mounted) return;

        // العودة لصفحة تسجيل الدخول مع رقم الهاتف
        context.go('/login');
      } else if (authProvider.error != null) {
        await Fluttertoast.showToast(
          msg: authProvider.error!,
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
      }
    }
  }

  void _handleBack() {
    if (_currentStep == 0) {
      context.go('/login');
    } else {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Widget _buildStepHeader() {
    final steps = ['رقم الهاتف', 'كود التحقق', 'كلمة المرور الجديدة'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = _currentStep == index;
        final isCompleted = _currentStep > index;
        final circleColor = isActive
            ? AppColors.primary
            : isCompleted
                ? AppColors.success
                : AppColors.gray300;
        final textColor =
            isActive || isCompleted ? AppColors.gray900 : AppColors.gray500;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2.h,
                        margin: EdgeInsets.symmetric(horizontal: 6.w),
                        color: _currentStep > index
                            ? AppColors.primary
                            : AppColors.gray300,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                steps[index],
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPhoneStep(LanguageProvider languageProvider) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أدخل رقم الهاتف المرتبط بحسابك لبدء الاستعادة',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          SizedBox(height: 20.h),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              labelText: languageProvider.phone,
              hintText: '777123456',
              prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'رقم الهاتف مطلوب';
              }
              final digits = value.replaceAll(RegExp('[^0-9]'), '');
              if (digits.length != 9) {
                return 'أدخل رقم هاتف يمني مكون من 9 أرقام';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أدخل كود التحقق المُرسل (تحقق من Debug Console في وضع التطوير)',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          SizedBox(height: 20.h),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'كود التحقق',
              hintText: 'أدخل الكود من 6 أرقام',
              prefixIcon: Icon(Icons.verified_user, color: AppColors.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'كود التحقق مطلوب';
              }
              if (value.length < 4) {
                return 'أدخل كود تحقق صالحًا';
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),
          Text(
            'في حال لم يصلك الكود، تأكد من صحة الرقم وحاول مجددًا خلال دقائق.',
            style: AppTypography.caption.copyWith(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep(LanguageProvider languageProvider) {
    return Form(
      key: _newPasswordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أدخل كلمة المرور الجديدة التي ترغب في استخدامها',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          SizedBox(height: 20.h),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: languageProvider.password,
              hintText: 'أدخل كلمة مرور جديدة',
              prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'كلمة المرور مطلوبة';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),
          SizedBox(height: 20.h),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: languageProvider.confirmPassword,
              hintText: 'أعد إدخال كلمة المرور الجديدة',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'تأكيد كلمة المرور مطلوب';
              }
              if (value != _newPasswordController.text) {
                return 'كلمتا المرور غير متطابقتين';
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'ستتمكن من تسجيل الدخول فوراً بكلمة المرور الجديدة',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(LanguageProvider languageProvider) {
    switch (_currentStep) {
      case 0:
        return _buildPhoneStep(languageProvider);
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNewPasswordStep(languageProvider);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isLastStep = _currentStep == 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/login'),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.primary,
                      size: 24.w,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'استعادة الحساب',
                  style: AppTypography.body.copyWith(
                    color: AppColors.gray900,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'اتبع الخطوات التالية لإعادة تعيين كلمة المرور',
                  style: AppTypography.body.colored(AppColors.gray600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                _buildStepHeader(),
                SizedBox(height: 20.h),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentStep),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: _buildStepContent(languageProvider),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: authProvider.isLoading ? null : _handleBack,
                        child: Text(
                          _currentStep == 0 ? 'إلغاء' : 'السابق',
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        text: isLastStep ? 'إرسال واستكمال' : 'التالي',
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleNext(authProvider),
                        loading: authProvider.isLoading,
                        fullWidth: true,
                        size: AppButtonSize.large,
                      ),
                    ),
                  ],
                ),
                if (_currentStep == 1 && !_otpVerified)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: TextButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final phone = _phoneController.text.trim();
                              if (phone.isEmpty) return;
                              final restarted = await authProvider
                                  .startPasswordRecovery(phone);
                              if (!mounted) return;
                              if (restarted) {
                                await Fluttertoast.showToast(
                                  msg: 'تم إعادة إرسال الكود',
                                  backgroundColor: AppColors.success,
                                  textColor: Colors.white,
                                );
                              } else if (authProvider.error != null) {
                                await Fluttertoast.showToast(
                                  msg: authProvider.error!,
                                  backgroundColor: AppColors.error,
                                  textColor: Colors.white,
                                );
                              }
                            },
                      child: const Text('إعادة إرسال الكود'),
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
