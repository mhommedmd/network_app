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
import '../../../../shared/widgets/app_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    if (!PhoneUtils.isValidYemeniPhone(value)) {
      return 'يرجى إدخال رقم هاتف يمني صحيح';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return; // Guard against using context if widget disposed

    if (success) {
      await Fluttertoast.showToast(
        msg: 'تم تسجيل الدخول بنجاح',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
      if (!mounted) return;
      context.go('/');
    } else {
      await Fluttertoast.showToast(
        msg: authProvider.error ?? 'فشل في تسجيل الدخول',
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // App Logo/Icon
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
                    Icons.wifi,
                    size: 40.w,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 32.h),

                // Welcome Text
                Text(
                  languageProvider.appName,
                  style: AppTypography.headline.copyWith(
                    color: AppColors.gray900,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  'شبكات... بيع الكروت صار أسهل، أسرع، وأذكى!',
                  style: AppTypography.body.colored(AppColors.gray600),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40.h),

                // Login Form
                AppCard(
                  variant: AppCardVariant.glass,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: languageProvider.phone,
                            hintText: '777123456',
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: AppColors.primary,
                            ),
                          ),
                          validator: _validatePhone,
                        ),

                        SizedBox(height: 20.h),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: languageProvider.password,
                            hintText: 'أدخل كلمة المرور',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: AppColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.gray500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: _validatePassword,
                        ),

                        SizedBox(height: 12.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    final phone = _phoneController.text.trim();
                                    context.push(
                                      '/forgot-password',
                                      extra: {
                                        if (phone.isNotEmpty) 'phone': phone,
                                      },
                                    );
                                  },
                            child: Text(
                              'هل نسيت كلمة السر؟',
                              style: AppTypography.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // Login Button
                        AppButton(
                          text: languageProvider.login,
                          onPressed: authProvider.isLoading ? null : _handleLogin,
                          loading: authProvider.isLoading,
                          fullWidth: true,
                          size: AppButtonSize.large,
                        ),

                        SizedBox(height: 16.h),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'لا تملك حساب؟ ',
                              style: AppTypography.body.colored(
                                AppColors.gray600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: Text(
                                languageProvider.register,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Language Toggle
                AppButton(
                  text: languageProvider.isArabic ? 'English' : 'العربية',
                  onPressed: languageProvider.toggleLanguage,
                  variant: AppButtonVariant.ghost,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Local selector removed in favor of shared UserTypeSelector.
