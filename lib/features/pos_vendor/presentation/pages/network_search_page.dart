import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/network_connection_model.dart';
import '../../data/services/firebase_network_service.dart';

/// صفحة البحث عن الشبكات المتاحة للإضافة
class NetworkSearchPage extends StatefulWidget {
  const NetworkSearchPage({super.key});

  @override
  State<NetworkSearchPage> createState() => _NetworkSearchPageState();
}

class _NetworkSearchPageState extends State<NetworkSearchPage> {
  final _searchController = TextEditingController();
  String? _selectedGovernorate;
  String? _selectedDistrict;
  List<String> _governorates = [];
  List<String> _districts = [];
  List<NetworkConnectionModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // دالة للبحث مع debouncing لتحسين الأداء
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _loadGovernorates() async {
    setState(() => _isLoading = true);
    try {
      final governorates =
          await FirebaseNetworkService.getNetworkGovernorates();
      setState(() {
        _governorates = governorates;
        _isLoading = false;
      });
    } on Exception catch (e) {
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
          await FirebaseNetworkService.getNetworkDistricts(governorate);
      setState(() {
        _districts = districts;
        if (_selectedDistrict != null &&
            !_districts.contains(_selectedDistrict)) {
          _selectedDistrict = null;
        }
      });
    } on Exception catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandler.extractErrorMessage(e);
        CustomToast.error(
          context,
          errorMessage,
          title: 'فشل تحميل المديريات',
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id;

    if (vendorId == null) return;

    setState(() => _isSearching = true);

    try {
      final results = await FirebaseNetworkService.searchAvailableNetworks(
        vendorId: vendorId,
        searchQuery: _searchController.text.trim(),
        governorate: _selectedGovernorate,
        district: _selectedDistrict,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } on Exception catch (e) {
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

  Future<void> _addNetwork(NetworkConnectionModel network) async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id;

    if (vendorId == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final newConnection = NetworkConnectionModel(
      id: '',
      vendorId: vendorId,
      networkId: network.networkId,
      networkName: network.networkName,
      networkOwner: network.networkOwner,
      governorate: network.governorate,
      district: network.district,
      isActive: true,
      connectedAt: DateTime.now(),
      balance: 0,
      totalOrders: 0,
    );

    try {
      await FirebaseNetworkService.addNetworkConnection(newConnection);

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل

      CustomToast.success(
        context,
        'يمكنك الآن طلب كروت من هذه الشبكة',
        title: 'تمت إضافة "${network.networkName}"',
      );

      setState(() {
        _searchResults.removeWhere((n) => n.networkId == network.networkId);
      });
    } on Exception catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      final errorMessage = ErrorHandler.extractErrorMessage(e);
      CustomToast.error(
        context,
        errorMessage,
        title: 'فشل إضافة الشبكة',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'البحث عن شبكات',
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
        child: Column(
          children: [
            // منطقة البحث
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // حقل البحث مع debouncing للأداء
                  TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'اسم الشبكة أو المالك',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      filled: true,
                      fillColor: AppColors.gray50,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  SizedBox(height: 12.h),

                  // اختيار المحافظة
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedGovernorate,
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
                    initialValue: _selectedDistrict,
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
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading || _isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final network = _searchResults[index];
        return _NetworkSearchCard(
          network: network,
          onAdd: () => _addNetwork(network),
        );
      },
    );
  }
}

class _NetworkSearchCard extends StatelessWidget {
  const _NetworkSearchCard({
    required this.network,
    required this.onAdd,
  });

  final NetworkConnectionModel network;
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
                network.networkName.isNotEmpty
                    ? network.networkName[0].toUpperCase()
                    : 'ش',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // معلومات الشبكة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  network.networkName,
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
                      network.networkOwner,
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
                        '${network.governorate}، ${network.district}',
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
            size: AppButtonSize.small,
            icon: Icon(Icons.add, size: 18.w, color: Colors.white),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
