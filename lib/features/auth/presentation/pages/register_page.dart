import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../../../shared/widgets/user_type_selector.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _stepOneKey = GlobalKey<FormState>();
  final _stepTwoKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _entityNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserType _selectedUserType = UserType.posVendor;
  int _currentStep = 0;
  String? _selectedGovernorate;

  static const List<String> _governorates = [
    'صنعاء',
    'عدن',
    'تعز',
    'الحديدة',
    'إب',
    'ذمار',
    'حضرموت',
    'المهرة',
    'شبوة',
    'لحج',
    'أبين',
    'البيضاء',
    'مأرب',
    'الجوف',
    'عمران',
    'صعدة',
    'ريمة',
    'حجة',
    'المحويت',
    'سقطرى',
    'الضالع',
    'تعز (الريف)',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entityNameController.dispose();
    _ownerNameController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  bool get _isNetworkOwner => _selectedUserType == UserType.networkOwner;

  String get _entityNameLabel =>
      _isNetworkOwner ? 'اسم الشبكة' : 'اسم نقطة البيع';

  String get _ownerNameLabel =>
      _isNetworkOwner ? 'اسم مالك الشبكة' : 'اسم مالك نقطة البيع';

  Future<void> _handleNext(AuthProvider authProvider) async {
    if (authProvider.isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      if (_stepOneKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
      }
      return;
    }
    if (_currentStep == 1) {
      await _submit(authProvider);
    }
  }

  void _handleBack(AuthProvider authProvider) {
    if (_currentStep == 0) {
      context.go('/login');
    } else {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submit(AuthProvider authProvider) async {
    final stepTwoValid = _stepTwoKey.currentState?.validate() ?? false;
    if (!stepTwoValid) return;

    final phone = _phoneController.text.trim();
    final ownerName = _ownerNameController.text.trim();

    final success = await authProvider.register(
      name: ownerName,
      phone: phone,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      userType: _selectedUserType,
    );

    if (!mounted) return;

    if (success) {
      try {
        final userId = authProvider.user?.id;
        if (userId != null) {
          final profileData = <String, dynamic>{
            'accountType': _selectedUserType.name,
            'phone': phone,
            'entityName': _entityNameController.text.trim(),
            'ownerName': ownerName,
            'governorate': _selectedGovernorate,
            'district': _districtController.text.trim(),
            'city': _cityController.text.trim(),
            'completedAt': DateTime.now().toIso8601String(),
          };
          final street = _streetController.text.trim();
          if (!_isNetworkOwner && street.isNotEmpty) {
            profileData['street'] = street;
          }
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(profileData, SetOptions(merge: true));
        }
      } on FirebaseException catch (e) {
        debugPrint('فشل في حفظ بيانات التسجيل الإضافية: ${e.message}');
      }

      if (!mounted) return;

      await Fluttertoast.showToast(
        msg: 'تم إنشاء الحساب بنجاح',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

      if (!mounted) return;
      context.go('/');
    } else {
      await Fluttertoast.showToast(
        msg: authProvider.error ?? 'فشل في إنشاء الحساب',
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildStepHeader() {
    final steps = ['نوع الحساب', 'بيانات الحساب'];
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

  Widget _buildStepContent(
    LanguageProvider languageProvider,
    AuthProvider authProvider,
  ) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _stepOneKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر نوع الحساب وبيانات الدخول الأساسية',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              SizedBox(height: 16.h),
              UserTypeSelector(
                value: _selectedUserType,
                onChanged: (value) => setState(() {
                  _selectedUserType = value;
                }),
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
              SizedBox(height: 20.h),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: languageProvider.password,
                  hintText: 'أدخل كلمة المرور',
                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.gray500,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
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
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: languageProvider.confirmPassword,
                  hintText: 'أعد إدخال كلمة المرور',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.gray500,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'تأكيد كلمة المرور مطلوب';
                  }
                  if (value != _passwordController.text) {
                    return 'كلمة المرور غير متطابقة';
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _stepTwoKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أكمل بيانات ${_isNetworkOwner ? 'الشبكة' : 'نقطة البيع'}',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _entityNameController,
                decoration: InputDecoration(
                  labelText: _entityNameLabel,
                  hintText: 'أدخل الاسم الكامل',
                  prefixIcon:
                      const Icon(Icons.business, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الحقل مطلوب';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _ownerNameController,
                decoration: InputDecoration(
                  labelText: _ownerNameLabel,
                  hintText: 'أدخل الاسم الثلاثي',
                  prefixIcon:
                      const Icon(Icons.person, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الحقل مطلوب';
                  }
                  if (value.trim().length < 4) {
                    return 'أدخل اسمًا صحيحًا';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedGovernorate,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  prefixIcon: Icon(Icons.map, color: AppColors.primary),
                ),
                items: _governorates
                    .map(
                      (gov) => DropdownMenuItem(
                        value: gov,
                        child: Text(gov),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedGovernorate = value;
                }),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار المحافظة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'اسم المديرية',
                  hintText: 'مثال: معين',
                  prefixIcon:
                      Icon(Icons.location_city, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'المديرية مطلوبة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنطقة / المدينة',
                  hintText: 'مثال: الحصبة',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'المنطقة مطلوبة';
                  }
                  return null;
                },
              ),
              if (!_isNetworkOwner) ...[
                SizedBox(height: 20.h),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الحي / الشارع',
                    hintText: 'مثال: شارع الستين',
                    prefixIcon: Icon(Icons.route, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions(AuthProvider authProvider) {
    final isLastStep = _currentStep == 1;
    final primaryText = isLastStep ? 'إنهاء التسجيل' : 'التالي';
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed:
                authProvider.isLoading ? null : () => _handleBack(authProvider),
            child: Text(_currentStep == 0 ? 'عودة لتسجيل الدخول' : 'السابق'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton(
            text: primaryText,
            onPressed:
                authProvider.isLoading ? null : () => _handleNext(authProvider),
            loading: isLastStep && authProvider.isLoading,
            fullWidth: true,
            size: AppButtonSize.large,
          ),
        ),
      ],
    );
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Text(
                  'إنشاء حساب جديد',
                  style: AppTypography.body.copyWith(
                    color: AppColors.gray900,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'اتبع الخطوات لإعداد حساب ${_isNetworkOwner ? 'مالك الشبكة' : 'نقطة البيع'}',
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
                        child:
                            _buildStepContent(languageProvider, authProvider),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                _buildActions(authProvider),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
