import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/vendor_model.dart';
import '../../data/services/firebase_vendor_service.dart';

/// صفحة البحث عن المتاجر المتاحة للإضافة
class VendorSearchPage extends StatefulWidget {
  const VendorSearchPage({super.key});

  @override
  State<VendorSearchPage> createState() => _VendorSearchPageState();
}

class _VendorSearchPageState extends State<VendorSearchPage> {
  final _searchController = TextEditingController();
  String? _selectedGovernorate;
  String? _selectedDistrict;
  List<String> _governorates = [];
  List<String> _districts = [];
  List<VendorModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGovernorates() async {
    setState(() => _isLoading = true);
    try {
      final governorates =
          await FirebaseVendorService.getAvailableGovernorates();
      setState(() {
        _governorates = governorates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMessage = ErrorHandler.extractErrorMessage(e);
        CustomToast.error(
          context,
          errorMessage,
          title: 'فشل تحميل البيانات',
        );
      }
    }
  }

  Future<void> _loadDistricts(String governorate) async {
    try {
      final districts =
          await FirebaseVendorService.getDistrictsByGovernorate(governorate);
      setState(() {
        _districts = districts;
        // إعادة تعيين المديرية إذا لم تكن موجودة في القائمة الجديدة
        if (_selectedDistrict != null &&
            !_districts.contains(_selectedDistrict)) {
          _selectedDistrict = null;
        }
      });
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandler.extractErrorMessage(e);
        CustomToast.error(
          context,
          errorMessage,
          title: 'خطأ في تحميل المديريات',
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final authProvider = context.read<AuthProvider>();
    final networkId = authProvider.user?.id;

    if (networkId == null) return;

    setState(() => _isSearching = true);

    try {
      final results = await FirebaseVendorService.searchAvailableVendors(
        networkId: networkId,
        searchQuery: _searchController.text.trim(),
        governorate: _selectedGovernorate,
        district: _selectedDistrict,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        final errorMessage = ErrorHandler.extractErrorMessage(e);
        CustomToast.error(
          context,
          errorMessage,
          title: 'فشل البحث',
        );
      }
    }
  }

  Future<void> _addVendor(VendorModel vendor) async {
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

    // عرض مؤشر التحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // إنشاء نسخة من المتجر مع معرف الشبكة الحالي
    final newVendor = VendorModel(
      id: vendor.id, // استخدام user ID من users collection
      name: vendor.name,
      ownerName: vendor.ownerName,
      phone: vendor.phone,
      governorate: vendor.governorate,
      district: vendor.district,
      address: vendor.address,
      networkId: networkId,
      balance: 0, // رصيد ابتدائي
      stock: 0, // مخزون ابتدائي
      isActive: true,
      createdAt: DateTime.now(),
      notes: vendor.notes,
    );

    try {
      print('🔄 محاولة إضافة المتجر: ${vendor.name}');
      print('   - Network ID: $networkId');
      print('   - User ID من users collection: ${vendor.id}');
      print('   - Vendor Data: ${newVendor.toJson()}');

      // استخدام FirebaseVendorService مباشرة
      await FirebaseVendorService.addVendor(newVendor);

      print('✅ تمت إضافة المتجر بنجاح');

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل

      CustomToast.success(
        context,
        'يمكنك الآن إدارة هذا المتجر من صفحة المتاجر',
        title: 'تمت إضافة "${vendor.name}"',
      );

      // إزالة المتجر من نتائج البحث
      setState(() {
        _searchResults.removeWhere((v) => v.id == vendor.id);
      });
    } catch (e) {
      print('❌ فشل إضافة المتجر: $e');

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل

      final errorMessage = ErrorHandler.extractErrorMessage(e);
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل إضافة المتجر',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'البحث عن متاجر',
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // منطقة البحث
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // حقل البحث
                    TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: 'اسم المتجر أو المالك أو رقم الهاتف',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.gray50,
                      ),
                      onChanged: (_) => _performSearch(),
                    ),
                    SizedBox(height: 12.h),

                    // اختيار المحافظة
                    DropdownButtonFormField<String?>(
                      value: _selectedGovernorate,
                      decoration: InputDecoration(
                        labelText: 'المحافظة',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.gray50,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('كل المحافظات'),
                        ),
                        ..._governorates.map(
                          (gov) => DropdownMenuItem<String?>(
                            value: gov,
                            child: Text(gov),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGovernorate = value;
                          _selectedDistrict = null;
                          _districts = [];
                        });
                        if (value != null) {
                          _loadDistricts(value);
                        }
                        _performSearch();
                      },
                    ),
                    SizedBox(height: 12.h),

                    // اختيار المديرية
                    DropdownButtonFormField<String?>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'المديرية',
                        prefixIcon: const Icon(Icons.place),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.gray50,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('كل المديريات'),
                        ),
                        ..._districts.map(
                          (district) => DropdownMenuItem<String?>(
                            value: district,
                            child: Text(district),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value;
                        });
                        _performSearch();
                      },
                    ),
                  ],
                ),
              ),

              // نتائج البحث
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _performSearch();
                  },
                  color: AppColors.primary,
                  child: _buildSearchResults(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading || _isSearching) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => const SkeletonCardWithIcon(),
      );
    }

    if (_searchResults.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64.w,
                    color: AppColors.gray400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'لا توجد نتائج',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'جرب البحث بمعايير مختلفة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final vendor = _searchResults[index];
        return _VendorSearchCard(
          vendor: vendor,
          onAdd: () => _addVendor(vendor),
        );
      },
    );
  }
}

class _VendorSearchCard extends StatelessWidget {
  const _VendorSearchCard({
    required this.vendor,
    required this.onAdd,
  });

  final VendorModel vendor;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // الصورة الرمزية
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                vendor.avatar,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // معلومات المتجر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.person, size: 14.w, color: AppColors.gray500),
                    SizedBox(width: 4.w),
                    Text(
                      vendor.ownerName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14.w, color: AppColors.gray500),
                    SizedBox(width: 4.w),
                    Text(
                      vendor.phone,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.place, size: 14.w, color: AppColors.gray500),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        vendor.location,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.gray700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // زر الإضافة
          AppButton(
            text: 'إضافة',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            icon: Icon(Icons.add, size: 18.w, color: Colors.white),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
