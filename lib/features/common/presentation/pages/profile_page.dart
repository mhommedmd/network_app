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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditingProfile = false;
  bool _isEditingPassword = false;

  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _networkNameController;
  late TextEditingController _emailController;
  late TextEditingController _secondPhoneController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _networkNameController =
        TextEditingController(text: user?.networkName ?? user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _secondPhoneController =
        TextEditingController(text: user?.secondPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _networkNameController.dispose();
    _emailController.dispose();
    _secondPhoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث الـ TextControllers عند تحديث البيانات من AuthProvider
    if (!_isEditingProfile) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      print('🔄 تحديث TextControllers:');
      print('  - الاسم: ${user.name}');
      print('  - اسم الشبكة: ${user.networkName}');
      print('  - البريد: ${user.email}');
      print('  - الهاتف الثاني: ${user.secondPhone}');

      _nameController.text = user.name;
      _networkNameController.text = user.networkName ?? user.name;
      _emailController.text = user.email;
      _secondPhoneController.text = user.secondPhone ?? '';

      print('✅ تم تحديث TextControllers');
    } else {
      print('❌ لا يوجد مستخدم لتحديث TextControllers');
    }
  }

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
            color: AppColors.gray900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // صورة البروفايل
                _buildProfileImageSection(user),
                SizedBox(height: 24.h),

                // معلومات الحساب
                _buildAccountInfoSection(user),
                SizedBox(height: 16.h),

                // الأمان
                _buildSecuritySection(),
                SizedBox(height: 16.h),

                // الإعدادات
                _buildSettingsSection(languageProvider),
                SizedBox(height: 24.h),

                // زر تسجيل الخروج
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
                      if (!mounted) return;
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(User? user) {
    return AppCard(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (user?.avatar != null && user!.avatar!.startsWith('http'))
                        ? NetworkImage(user.avatar!) as ImageProvider
                        : null,
                child: _selectedImage == null &&
                        (user?.avatar == null ||
                            !user!.avatar!.startsWith('http'))
                    ? Text(
                        user?.avatar ??
                            user?.name.substring(0, 1).toUpperCase() ??
                            'م',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            user?.name ?? 'مستخدم',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              user?.type == UserType.networkOwner ? 'مالك شبكة' : 'نقطة بيع',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(User? user) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'معلومات الحساب',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              if (!_isEditingProfile)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingProfile = true),
                  icon: Icon(Icons.edit, size: 16.w),
                  label: const Text('تعديل'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // الاسم
                _buildInfoField(
                  label: 'الاسم الكامل',
                  controller: _nameController,
                  enabled: _isEditingProfile,
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),

                // اسم الشبكة (لمالكي الشبكات فقط)
                if (user?.type == UserType.networkOwner) ...[
                  _buildInfoField(
                    label: 'اسم الشبكة',
                    controller: _networkNameController,
                    enabled: _isEditingProfile,
                    icon: Icons.wifi,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'اسم الشبكة مطلوب';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                ],

                // رقم الهاتف (غير قابل للتعديل)
                _buildInfoField(
                  label: 'رقم الهاتف',
                  initialValue: user?.phone ?? '',
                  enabled: false,
                  icon: Icons.phone,
                  helperText: 'لا يمكن تغيير رقم الهاتف الأساسي',
                ),
                SizedBox(height: 12.h),

                // البريد الإلكتروني
                _buildInfoField(
                  label: 'البريد الإلكتروني',
                  controller: _emailController,
                  enabled: _isEditingProfile,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!value.contains('@')) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),

                // رقم هاتف إضافي
                _buildInfoField(
                  label: 'رقم هاتف إضافي (اختياري)',
                  controller: _secondPhoneController,
                  enabled: _isEditingProfile,
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  hintText: '7xxxxxxxx',
                ),
              ],
            ),
          ),
          if (_isEditingProfile) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'إلغاء',
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      setState(() {
                        _isEditingProfile = false;
                        _nameController.text = user?.name ?? '';
                        _networkNameController.text =
                            user?.networkName ?? user?.name ?? '';
                        _emailController.text = user?.email ?? '';
                        _secondPhoneController.text = user?.secondPhone ?? '';
                      });
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    text: 'حفظ التغييرات',
                    onPressed: _saveProfileChanges,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأمان',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              if (!_isEditingPassword)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingPassword = true),
                  icon: Icon(Icons.lock_outline, size: 16.w),
                  label: const Text('تغيير كلمة المرور'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          if (_isEditingPassword) ...[
            SizedBox(height: 16.h),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  // كلمة المرور الحالية
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscureCurrentPassword =
                              !_obscureCurrentPassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'كلمة المرور الحالية مطلوبة';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),

                  // كلمة المرور الجديدة
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

                  // تأكيد كلمة المرور
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'إلغاء',
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            setState(() {
                              _isEditingPassword = false;
                              _currentPasswordController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AppButton(
                          text: 'تغيير كلمة المرور',
                          onPressed: _changePassword,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            Text(
              'آخر تغيير لكلمة المرور: لم يتم التغيير',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.gray600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection(LanguageProvider languageProvider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 16.h),
          _buildSettingOption(
            icon: Icons.language,
            title: 'اللغة',
            subtitle: languageProvider.isArabic ? 'العربية' : 'English',
            onTap: languageProvider.toggleLanguage,
          ),
          const Divider(color: AppColors.gray200),
          _buildSettingOption(
            icon: Icons.notifications,
            title: 'الإشعارات',
            subtitle: 'مفعل',
            onTap: () {
              CustomToast.info(
                context,
                'هذه الميزة قيد التطوير',
                title: 'قريباً',
              );
            },
          ),
          const Divider(color: AppColors.gray200),
          _buildSettingOption(
            icon: Icons.help,
            title: 'المساعدة والدعم',
            subtitle: '',
            onTap: () {
              CustomToast.info(
                context,
                'سيتم إضافة مركز المساعدة قريباً',
                title: 'قريباً',
              );
            },
          ),
          const Divider(color: AppColors.gray200),
          _buildSettingOption(
            icon: Icons.info,
            title: 'حول التطبيق',
            subtitle: 'الإصدار 1.0.0',
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

  Widget _buildInfoField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required bool enabled,
    required IconData icon,
    String? hintText,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20.w,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.gray900,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.gray600,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.w,
        color: AppColors.gray400,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    final newName = _nameController.text.trim();
    final newNetworkName = user?.type == UserType.networkOwner
        ? _networkNameController.text.trim()
        : null;
    final newEmail = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    final newSecondPhone = _secondPhoneController.text.trim().isEmpty
        ? null
        : _secondPhoneController.text.trim();

    print('🔄 محاولة حفظ التغييرات:');
    print('  - الاسم الجديد: $newName');
    print('  - اسم الشبكة الجديد: $newNetworkName');
    print('  - البريد الجديد: $newEmail');
    print('  - الهاتف الثاني الجديد: $newSecondPhone');

    // عرض مؤشر التحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // حفظ التغييرات في Firebase
    final success = await authProvider.updateUserProfile(
      name: newName,
      networkName: newNetworkName,
      email: newEmail,
      secondPhone: newSecondPhone,
    );

    print('✅ نتيجة الحفظ: ${success ? "نجح" : "فشل"}');
    if (!success && authProvider.error != null) {
      print('❌ الخطأ: ${authProvider.error}');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (success) {
      setState(() {
        _isEditingProfile = false;
      });

      // تحديث الـ TextControllers لتطابق البيانات الجديدة
      _updateControllers();

      // عرض البيانات المحدثة للتأكد
      final updatedUser = authProvider.user;
      print('📊 البيانات بعد الحفظ:');
      print('  - الاسم: ${updatedUser?.name}');
      print('  - اسم الشبكة: ${updatedUser?.networkName}');
      print('  - البريد: ${updatedUser?.email}');
      print('  - الهاتف الثاني: ${updatedUser?.secondPhone}');

      CustomToast.success(
        context,
        'تم حفظ جميع التعديلات على الملف الشخصي',
        title: 'تم الحفظ',
      );
    } else {
      CustomToast.error(
        context,
        authProvider.error ?? 'فشل حفظ التغييرات',
        title: 'فشل الحفظ',
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // عرض مؤشر التحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // تغيير كلمة المرور في Firebase Auth
    final success = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (success) {
      setState(() => _isEditingPassword = false);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      CustomToast.success(
        context,
        'تم تغيير كلمة المرور بنجاح',
        title: 'تم التحديث',
      );
    } else {
      CustomToast.error(
        context,
        authProvider.error ?? 'فشل تغيير كلمة المرور',
        title: 'فشل التغيير',
      );
    }
  }
}
