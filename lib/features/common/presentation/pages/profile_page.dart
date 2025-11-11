import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';

// استيراد User و UserType من auth_provider
export '../../../../core/providers/auth_provider.dart' show User, UserType;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // رفع الصورة مباشرة إلى Firebase
      await _uploadProfileImage();
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;
    var isSubmitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20.w,
            right: 20.w,
            top: 24.h,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'تغيير كلمة المرور',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      TextFormField(
                        controller: currentController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور الحالية',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setSheetState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'كلمة المرور الحالية مطلوبة' : null,
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: newController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور الجديدة',
                          prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'كلمة المرور الجديدة مطلوبة';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (value) => value == newController.text ? null : 'كلمة المرور غير متطابقة',
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'إلغاء',
                              variant: AppButtonVariant.outline,
                              onPressed: () => Navigator.of(sheetContext).pop(false),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AppButton(
                              text: 'تغيير',
                              loading: isSubmitting,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSubmitting = true);
                                final authProvider = context.read<AuthProvider>();
                                final success = await authProvider.changePassword(
                                  currentPassword: currentController.text,
                                  newPassword: newController.text,
                                );
                                if (!mounted) return;
                                setSheetState(() => isSubmitting = false);
                                if (success) {
                                  Navigator.of(sheetContext).pop(true);
                                } else {
                                  CustomToast.error(
                                    context,
                                    authProvider.error ?? 'فشل تغيير كلمة المرور',
                                    title: 'فشل التغيير',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (result ?? false) {
      if (!mounted) return;
      CustomToast.success(
        context,
        'تم تغيير كلمة المرور بنجاح',
        title: 'تم التحديث',
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    final authProvider = context.read<AuthProvider>();

    // عرض مؤشر التحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await authProvider.updateUserProfile(
      profileImage: _selectedImage,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (success) {
      CustomToast.success(
        context,
        'تم تحديث صورة الملف الشخصي',
        title: 'تم التحديث',
      );
    } else {
      CustomToast.error(
        context,
        authProvider.error ?? 'حدث خطأ غير متوقع',
        title: 'فشل التحديث',
      );
      // إعادة تعيين الصورة المحلية
      setState(() {
        _selectedImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: const Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(user),
              SizedBox(height: 20.h),
              _buildOptionsCard(languageProvider),
              SizedBox(height: 24.h),
              AppButton(
                text: languageProvider.logout,
                variant: AppButtonVariant.error,
                fullWidth: true,
                size: AppButtonSize.large,
                icon: Icon(Icons.logout, size: 20.w, color: Colors.white),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('تسجيل الخروج'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed ?? false) {
                    await authProvider.logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(User? user) {
    final displayName = user?.name ?? 'مستخدم';
    final secondaryLine = user?.type == UserType.posVendor ? (user?.ownerName ?? '') : (user?.name ?? '');
    final phone = user?.phone ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: ClipOval(
              child: SizedBox(
                width: 80.w,
                height: 80.w,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (user?.avatar != null && user!.avatar!.startsWith('http'))
                        ? Image.network(user.avatar!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            alignment: Alignment.center,
                            child: Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (secondaryLine.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    secondaryLine,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(LanguageProvider languageProvider) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final isArabic = languageProvider.isArabic;

    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.person_outline, color: AppColors.primary),
            ),
            title: const Text(
              'معلومات الحساب',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              user?.email ?? '',
              style: TextStyle(color: AppColors.gray600, fontSize: 12.sp),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountInfoPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.gray200),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.lock_outline, color: AppColors.primary),
            ),
            title: const Text(
              'تغيير كلمة المرور',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
            onTap: _showChangePasswordSheet,
          ),
          const Divider(height: 1, color: AppColors.gray200),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.language, color: AppColors.primary),
            ),
            title: const Text(
              'اللغة',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              isArabic ? 'العربية' : 'English',
              style: TextStyle(color: AppColors.gray600, fontSize: 12.sp),
            ),
            trailing: Switch(
              value: isArabic,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => languageProvider.toggleLanguage(),
            ),
          ),
          const Divider(height: 1, color: AppColors.gray200),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.help_outline, color: AppColors.primary),
            ),
            title: const Text(
              'المساعدة والدعم',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
            onTap: () {
              CustomToast.info(
                context,
                'سيتم إضافة مركز المساعدة قريباً',
                title: 'قريباً',
              );
            },
          ),
          const Divider(height: 1, color: AppColors.gray200),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.primary),
            ),
            title: const Text(
              'حول التطبيق',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'تطبيق إدارة كروت الإنترنت',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 جميع الحقوق محفوظة',
              );
            },
          ),
        ],
      ),
    );
  }
}

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late final AuthProvider _authProvider;
  User? get _user => _authProvider.user;

  late final TextEditingController _nameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _networkNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _secondPhoneController;
  late final TextEditingController _governorateController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    final user = _authProvider.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ownerNameController = TextEditingController(text: user?.ownerName ?? '');
    _networkNameController = TextEditingController(text: user?.networkName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _secondPhoneController = TextEditingController(text: user?.secondPhone ?? '');
    _governorateController = TextEditingController(text: user?.governorate ?? '');
    _districtController = TextEditingController(text: user?.district ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _networkNameController.dispose();
    _emailController.dispose();
    _secondPhoneController.dispose();
    _governorateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userType = _user?.type;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'معلومات الحساب',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: AppCard(
            padding: EdgeInsets.all(20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (userType == UserType.posVendor) ...[
                    _buildInfoField(
                      label: 'اسم المتجر',
                      controller: _nameController,
                      icon: Icons.store,
                      validator: (value) => value == null || value.trim().isEmpty ? 'اسم المتجر مطلوب' : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoField(
                      label: 'اسم مالك المتجر',
                      controller: _ownerNameController,
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.trim().isEmpty ? 'اسم المالك مطلوب' : null,
                    ),
                    SizedBox(height: 12.h),
                  ] else ...[
                    _buildInfoField(
                      label: 'اسم مالك الشبكة',
                      controller: _nameController,
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.trim().isEmpty ? 'اسم المالك مطلوب' : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoField(
                      label: 'اسم الشبكة',
                      controller: _networkNameController,
                      icon: Icons.wifi,
                      validator: (value) => value == null || value.trim().isEmpty ? 'اسم الشبكة مطلوب' : null,
                    ),
                    SizedBox(height: 12.h),
                  ],
                  TextFormField(
                    enabled: false,
                    initialValue: _user?.phone ?? '',
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      helperText: 'لا يمكن تغيير رقم الهاتف الأساسي',
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoField(
                          label: 'المحافظة',
                          controller: _governorateController,
                          icon: Icons.location_city,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildInfoField(
                          label: 'المديرية',
                          controller: _districtController,
                          icon: Icons.place,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoField(
                    label: 'المدينة',
                    controller: _cityController,
                    icon: Icons.location_on,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoField(
                    label: 'العنوان التفصيلي',
                    controller: _addressController,
                    icon: Icons.home_outlined,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoField(
                    label: 'البريد الإلكتروني',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && !value.contains('@')) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoField(
                    label: 'رقم هاتف إضافي (اختياري)',
                    controller: _secondPhoneController,
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 24.h),
                  AppButton(
                    text: 'حفظ التغييرات',
                    loading: _isSaving,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: validator,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await _authProvider.updateUserProfile(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
      networkName: _networkNameController.text.trim().isEmpty ? null : _networkNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      secondPhone: _secondPhoneController.text.trim().isEmpty ? null : _secondPhoneController.text.trim(),
      governorate: _governorateController.text.trim().isEmpty ? null : _governorateController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      CustomToast.success(
        context,
        'تم حفظ التعديلات بنجاح',
        title: 'تم الحفظ',
      );
      Navigator.of(context).pop();
    } else {
      CustomToast.error(
        context,
        _authProvider.error ?? 'فشل حفظ التغييرات',
        title: 'فشل الحفظ',
      );
    }
  }
}
