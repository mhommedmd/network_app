import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/card_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/providers/card_provider.dart';
import '../../data/services/firebase_card_cleanup_service.dart';
import '../../data/services/firebase_vendor_service.dart';

/// صفحة عرض مخزون الكروت من Firebase
class NetworkStoredPage extends StatefulWidget {
  const NetworkStoredPage({super.key});

  @override
  State<NetworkStoredPage> createState() => _NetworkStoredPageState();
}

class _NetworkStoredPageState extends State<NetworkStoredPage> {
  // القسم المعروض: available, transferred, sold
  String _selectedView = 'available';
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  int _rowsPerPage = 50; // عدد الكروت في كل صفحة
  final List<int> _rowsPerPageOptions = [25, 50, 100, 200];
  bool _sortByPackageAscending = true; // للفرز حسب الباقة
  bool _sortByVendorAscending = true;
  String? _packageToDelete; // الباقة المراد حذف كروتها
  String? _packageFilter;
  DateTime? _dateFilter;
  final Map<String, String> _vendorNames = {};
  StreamSubscription<List<VendorModel>>? _vendorSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCards();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
        _currentPage = 0;
      });
    });

    // جدولة التنظيف التلقائي للكروت القديمة (يعمل في الخلفية)
    FirebaseCardCleanupService.scheduleAutomaticCleanup();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _vendorSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page, int maxPage) {
    setState(() {
      _currentPage = page.clamp(0, maxPage);
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _confirmDeleteCard(CardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الكرت رقم "${card.cardNumber}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!mounted) return;
      final cardProvider = Provider.of<CardProvider>(context, listen: false);
      final success = await cardProvider.deleteCard(card.id);

      if (!mounted) return;

      if (success) {
        CustomToast.success(
          context,
          'تم حذف الكرت من المخزون',
          title: 'تم حذف "${card.cardNumber}"',
        );
        // إعادة تحميل الكروت
        _loadCards();
      } else {
        final errorMessage = ErrorHandler.extractErrorMessage(
          cardProvider.error ?? 'فشل في حذف الكرت',
        );
        CustomToast.error(
          context,
          errorMessage,
          title: 'فشل الحذف',
        );
      }
    }
  }

  void _loadCards() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final networkId = authProvider.user?.id ?? '';

    // تصفير الصفحة الحالية عند إعادة التحميل
    if (_currentPage != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = 0);
      });
    }

    if (networkId.isNotEmpty) {
      _vendorSubscription?.cancel();
      _vendorSubscription = FirebaseVendorService.getVendorsByNetwork(networkId).listen(
        (vendors) {
          if (!mounted) return;
          setState(() {
            _vendorNames
              ..clear()
              ..addEntries(
                vendors.map(
                  (vendor) => MapEntry(vendor.realUserId, vendor.name),
                ),
              );
          });
        },
      );

      // تحميل الكروت حسب القسم المختار
      CardStatus? statusToLoad;
      switch (_selectedView) {
        case 'available':
          statusToLoad = CardStatus.available;
        case 'transferred':
          statusToLoad = CardStatus.transferred;
        case 'sold':
          statusToLoad = CardStatus.sold;
      }

      if (statusToLoad != null) {
        cardProvider.loadCardsByStatus(networkId, statusToLoad);
      } else {
        cardProvider.loadCards(networkId);
      }
      cardProvider.loadStats(networkId);
    }
  }

  List<String> _getUniquePackageNames(List<CardModel> cards) {
    final names = cards.map((c) => c.packageName).toSet().toList();
    names.sort();
    return names;
  }

  List<CardModel> _getFilteredCards(
    List<CardModel> cards,
    Map<String, String> vendorNames,
  ) {
    final filtered = cards.where((card) {
      if (_packageFilter != null && card.packageName != _packageFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !card.cardNumber.contains(_searchQuery)) {
        return false;
      }
      if (_dateFilter != null && !_isSameDate(_resolveCardDate(card), _dateFilter!)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_selectedView == 'transferred' || _selectedView == 'sold') {
        final vendorA = vendorNames[a.transferredTo] ?? '';
        final vendorB = vendorNames[b.transferredTo] ?? '';
        final vendorCmp = vendorA.compareTo(vendorB);
        if (vendorCmp != 0) {
          return _sortByVendorAscending ? vendorCmp : -vendorCmp;
        }
      }

      final packageCompare = a.packageName.compareTo(b.packageName);
      if (packageCompare != 0) {
        return _sortByPackageAscending ? packageCompare : -packageCompare;
      }

      return a.cardNumber.compareTo(b.cardNumber);
    });

    return filtered;
  }

  void _togglePackageSort() {
    setState(() {
      _sortByPackageAscending = !_sortByPackageAscending;
      _currentPage = 0; // العودة للصفحة الأولى
    });
  }

  void _toggleVendorSort() {
    setState(() {
      _sortByVendorAscending = !_sortByVendorAscending;
      _currentPage = 0;
    });
  }

  Future<void> _confirmDeleteAllPackageCards() async {
    if (_packageToDelete == null) {
      CustomToast.warning(
        context,
        'اختر الباقة من القائمة المنسدلة أولاً',
        title: 'لم يتم اختيار باقة',
      );
      return;
    }

    if (_dateFilter == null) {
      CustomToast.warning(
        context,
        'اختر تاريخ الإضافة أولاً',
        title: 'لم يتم اختيار تاريخ',
      );
      return;
    }

    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final cardsToDelete = cardProvider.cards.where((card) {
      if (card.packageName != _packageToDelete) return false;
      final cardDate = _resolveCardDate(card);
      return _isSameDate(cardDate, _dateFilter!);
    }).toList();

    if (cardsToDelete.isEmpty) {
      CustomToast.warning(
        context,
        'لا توجد كروت بهذا التاريخ المحدد',
        title: 'لا توجد كروت بتاريخ محدد',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.w),
            SizedBox(width: 8.w),
            const Text('تأكيد الحذف الجماعي'),
          ],
        ),
        content: Text(
          _dateFilter == null
              ? 'سيتم حذف ${cardsToDelete.length} كرت من الباقة "$_packageToDelete".\n\nهذا الإجراء لا يمكن التراجع عنه!'
              : 'سيتم حذف ${cardsToDelete.length} كرت من الباقة "$_packageToDelete" بتاريخ ${DateFormat('dd/MM/yyyy', 'ar').format(_dateFilter!)}.\n\nهذا الإجراء لا يمكن التراجع عنه!',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'جارٍ حذف ${cardsToDelete.length} كرت...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      final success = await cardProvider.deleteCards(cardsToDelete.map((card) => card.id).toList());

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        CustomToast.success(
          context,
          _dateFilter == null
              ? 'تم حذف ${cardsToDelete.length} كرت من الباقة المختارة'
              : 'تم حذف ${cardsToDelete.length} كرت بتاريخ ${DateFormat('dd/MM/yyyy', 'ar').format(_dateFilter!)}',
          title: 'تم الحذف',
        );
        setState(() {
          _packageToDelete = null;
          _dateFilter = null;
        });
      } else {
        CustomToast.error(
          context,
          cardProvider.error ?? 'فشل حذف الكروت',
          title: 'تعذر الحذف',
        );
      }
      _loadCards();
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _resolveCardDate(CardModel card) {
    switch (_selectedView) {
      case 'available':
        return card.createdAt;
      case 'transferred':
        return card.transferredAt ?? card.createdAt;
      case 'sold':
        return card.soldAt ?? card.updatedAt;
      default:
        return card.createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<CardProvider>(context);
    final stats = cardProvider.stats;
    final allCards = cardProvider.cards;
    final filteredCards = _getFilteredCards(allCards, _vendorNames);
    final packageNames = _getUniquePackageNames(allCards);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المخزون',
          style: AppTypography.subheadline.copyWith(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildInventoryContent(
        cardProvider,
        stats,
        filteredCards,
        packageNames,
        allCards,
        _vendorNames,
      ),
    );
  }

  Widget _buildInventoryContent(
    CardProvider cardProvider,
    Map<String, dynamic>? stats,
    List<CardModel> filteredCards,
    List<String> packageNames,
    List<CardModel> allCards,
    Map<String, String> vendorNames,
  ) {
    if (cardProvider.isLoading) {
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Skeleton for stats
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLine(width: 150, height: 16),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: List.generate(
                          4,
                          (index) => SkeletonBox(
                            width: 80.w,
                            height: 30,
                            borderRadius: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Skeleton for view selector
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: List.generate(
                      3,
                      (index) => const Expanded(
                        child: SkeletonBox(
                          height: 60,
                          borderRadius: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Skeleton for cards list
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: List.generate(
                        8,
                        (index) => Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.gray200),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SkeletonLine(width: 30),
                              SizedBox(width: 20.w),
                              const SkeletonLine(width: 80),
                              SizedBox(width: 20.w),
                              const SkeletonLine(width: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cardProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              cardProvider.error!,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadCards,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildViewSelector(),
              SizedBox(height: 10.h),
              if (stats != null) ...[
                _buildStats(stats, allCards),
                SizedBox(height: 12.h),
              ],
              if (_selectedView == 'available') ...[
                _buildBulkDeleteSection(packageNames, allCards),
                SizedBox(height: 12.h),
              ],
              TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'بحث برقم الكرت',
                  hintText: 'أدخل رقم الكرت...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: _buildTableSection(
                  filteredCards: filteredCards,
                  vendorNames: vendorNames,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewButton(
              label: 'المتاحة',
              isSelected: _selectedView == 'available',
              onTap: () {
                setState(() {
                  _selectedView = 'available';
                  _currentPage = 0;
                  _packageFilter = null;
                  _packageToDelete = null;
                  _dateFilter = null;
                });
                _loadCards();
              },
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _ViewButton(
              label: 'المنقولة',
              isSelected: _selectedView == 'transferred',
              onTap: () {
                setState(() {
                  _selectedView = 'transferred';
                  _currentPage = 0;
                  _packageFilter = null;
                  _packageToDelete = null;
                  _dateFilter = null;
                });
                _loadCards();
              },
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _ViewButton(
              label: 'المباعة',
              isSelected: _selectedView == 'sold',
              onTap: () {
                setState(() {
                  _selectedView = 'sold';
                  _currentPage = 0;
                  _packageFilter = null;
                  _packageToDelete = null;
                  _dateFilter = null;
                });
                _loadCards();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> stats, List<CardModel> allCards) {
    // حساب عدد الكروت لكل باقة في التبويب الحالي
    final packageCounts = <String, int>{};
    for (final card in allCards) {
      packageCounts.update(
        card.packageName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // ترتيب الباقات أبجدياً
    final sortedPackages = packageCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // تحديد عنوان الإجمالي بناءً على التبويب المفتوح
    String totalLabel;
    Color totalColor;
    switch (_selectedView) {
      case 'available':
        totalLabel = 'الإجمالي';
        totalColor = AppColors.primary;
      case 'transferred':
        totalLabel = 'المنقولة';
        totalColor = AppColors.blue500;
      case 'sold':
        totalLabel = 'المباعة';
        totalColor = AppColors.success;
      default:
        totalLabel = 'الإجمالي';
        totalColor = AppColors.primary;
    }

    final chips = <Widget>[
      _StatChip(
        label: totalLabel,
        value: '${allCards.length}',
        color: totalColor,
        isSelected: _packageFilter == null,
        onTap: () {
          setState(() {
            _packageFilter = null;
            _packageToDelete = null;
            _dateFilter = null;
            _currentPage = 0;
          });
        },
      ),
      ...sortedPackages.map(
        (entry) => _StatChip(
          label: entry.key,
          value: '${entry.value}',
          color: AppColors.blue500,
          isSelected: _packageFilter == entry.key,
          onTap: () {
            setState(() {
              if (_packageFilter == entry.key) {
                _packageFilter = null;
                _packageToDelete = null;
              } else {
                _packageFilter = entry.key;
                _packageToDelete = entry.key;
              }
              _dateFilter = null;
              _currentPage = 0;
            });
          },
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'الاحصائيات',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildBulkDeleteSection(List<String> packageNames, List<CardModel> allCards) {
    final dateOptions = (_packageToDelete == null) ? <DateTime>[] : _getPackageDates(_packageToDelete!, allCards);
    DateTime? selectedDate;
    if (_dateFilter != null) {
      for (final date in dateOptions) {
        if (_isSameDate(date, _dateFilter!)) {
          selectedDate = date;
          break;
        }
      }
    }
    if (selectedDate == null && _dateFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _dateFilter = null;
          });
        }
      });
    }
    final isDeleteEnabled = _packageToDelete != null && selectedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _packageToDelete,
                decoration: InputDecoration(
                  labelText: 'الباقة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                ),
                items: packageNames
                    .map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: packageNames.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _packageToDelete = value;
                          _packageFilter = value;
                          _dateFilter = null;
                          _currentPage = 0;
                        });
                      },
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: DropdownButtonFormField<DateTime>(
                initialValue: selectedDate,
                decoration: InputDecoration(
                  labelText: 'التاريخ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                ),
                hint: const Text('اختر التاريخ'),
                items: dateOptions
                    .map(
                      (date) => DropdownMenuItem<DateTime>(
                        value: date,
                        child: Text(DateFormat('dd/MM/yyyy', 'ar').format(date)),
                      ),
                    )
                    .toList(),
                onChanged: dateOptions.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _dateFilter = value;
                          _currentPage = 0;
                        });
                      },
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              height: 44.h,
              child: ElevatedButton(
                onPressed: isDeleteEnabled ? _confirmDeleteAllPackageCards : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text('حذف'),
              ),
            ),
          ],
        ),
        if (dateOptions.isEmpty && _packageToDelete != null)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'لا توجد تواريخ لهذه الباقة.',
              style: TextStyle(fontSize: 11.sp, color: AppColors.gray500),
            ),
          ),
      ],
    );
  }

  List<DateTime> _getPackageDates(String packageName, List<CardModel> cards) {
    final dates = <DateTime>{};
    for (final card in cards) {
      if (card.packageName != packageName) continue;
      final referenceDate = _resolveCardDate(card);
      dates.add(DateTime(referenceDate.year, referenceDate.month, referenceDate.day));
    }
    final ordered = dates.toList()..sort((a, b) => b.compareTo(a));
    return ordered;
  }

  Widget _buildTableSection({
    required List<CardModel> filteredCards,
    required Map<String, String> vendorNames,
  }) {
    final isAvailable = _selectedView == 'available';
    final isTransferred = _selectedView == 'transferred';
    final isSold = _selectedView == 'sold';
    final showVendor = isTransferred || isSold;
    final showDate = isAvailable;
    final showDelete = isAvailable;

    final totalPages = (filteredCards.length / _rowsPerPage).ceil();
    final maxPageIndex = totalPages == 0 ? 0 : totalPages - 1;
    final safeCurrentPage = filteredCards.isEmpty ? 0 : _currentPage.clamp(0, maxPageIndex);
    final startIndex = filteredCards.isEmpty ? 0 : safeCurrentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filteredCards.length);
    final pageCards = filteredCards.isEmpty ? <CardModel>[] : filteredCards.sublist(startIndex, endIndex);

    final header = _buildTableHeader(
      showVendor: showVendor,
      showDate: showDate,
      showDelete: showDelete,
    );

    Widget listView;
    if (pageCards.isEmpty) {
      listView = ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          _buildEmptyState(),
        ],
      );
    } else {
      listView = ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: pageCards.length,
        itemBuilder: (context, index) {
          final card = pageCards[index];
          final globalIndex = startIndex + index + 1;
          return _buildTableRow(
            card: card,
            globalIndex: globalIndex,
            isEven: index.isEven,
            showVendor: showVendor,
            showDate: showDate,
            showDelete: showDelete,
            vendorNames: vendorNames,
          );
        },
      );
    }

    return Column(
      children: [
        header,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadCards();
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primary,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: pageCards.length > 15,
              child: listView,
            ),
          ),
        ),
        _buildPaginationBar(
          currentPage: filteredCards.isEmpty ? 0 : safeCurrentPage + 1,
          totalPages: totalPages == 0 ? 1 : totalPages,
          totalCards: filteredCards.length,
          startIndex: filteredCards.isEmpty ? 0 : startIndex + 1,
          endIndex: filteredCards.isEmpty ? 0 : endIndex,
          onFirst: safeCurrentPage > 0 ? () => _goToPage(0, maxPageIndex) : null,
          onPrevious: safeCurrentPage > 0 ? () => _goToPage(safeCurrentPage - 1, maxPageIndex) : null,
          onNext: safeCurrentPage < maxPageIndex ? () => _goToPage(safeCurrentPage + 1, maxPageIndex) : null,
          onLast: safeCurrentPage < maxPageIndex ? () => _goToPage(maxPageIndex, maxPageIndex) : null,
        ),
      ],
    );
  }

  Widget _buildTableHeader({
    required bool showVendor,
    required bool showDate,
    required bool showDelete,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: AppColors.gray50,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          _buildHeaderCell('#', flex: 1),
          if (showVendor)
            _buildHeaderCell(
              'المتجر',
              flex: 3,
              isSortable: true,
              ascending: _sortByVendorAscending,
              onTap: _toggleVendorSort,
            ),
          _buildHeaderCell(
            'الباقة',
            flex: 3,
            isSortable: true,
            ascending: _sortByPackageAscending,
            onTap: _togglePackageSort,
          ),
          _buildHeaderCell('رقم الكرت', flex: 3),
          if (showDate) _buildHeaderCell('التاريخ', flex: 2),
          if (showDelete)
            SizedBox(
              width: 40.w,
              child: Center(
                child: Text(
                  'حذف',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.gray600, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required CardModel card,
    required int globalIndex,
    required bool isEven,
    required bool showVendor,
    required bool showDate,
    required bool showDelete,
    required Map<String, String> vendorNames,
  }) {
    final vendorName = (card.transferredTo != null && card.transferredTo!.isNotEmpty)
        ? vendorNames[card.transferredTo] ?? 'غير معروف'
        : 'غير معروف';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.gray50,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          _buildDataCell('$globalIndex', flex: 1, fontWeight: FontWeight.w600),
          if (showVendor) _buildDataCell(vendorName, flex: 3),
          _buildDataCell(card.packageName, flex: 3),
          _buildDataCell(card.cardNumber, flex: 3, monospace: true, fontWeight: FontWeight.w600),
          if (showDate)
            _buildDataCell(
              DateFormat('dd/MM/yyyy', 'ar').format(card.createdAt),
              flex: 2,
            ),
          if (showDelete)
            SizedBox(
              width: 52.w,
              child: TextButton(
                onPressed: () => _confirmDeleteCard(card),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.error,
                ),
                child: Text(
                  'حذف',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label, {
    required int flex,
    bool isSortable = false,
    bool ascending = true,
    VoidCallback? onTap,
  }) {
    Widget content = Text(
      label,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: isSortable ? AppColors.primary : AppColors.gray700,
      ),
    );

    if (isSortable && onTap != null) {
      content = InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            Icon(
              ascending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 18.w,
              color: AppColors.primary,
            ),
          ],
        ),
      );
    }

    return Expanded(
      flex: flex,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: content,
      ),
    );
  }

  Widget _buildDataCell(
    String value, {
    required int flex,
    FontWeight fontWeight = FontWeight.w500,
    bool monospace = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: fontWeight,
          color: AppColors.gray800,
          fontFamily: monospace ? 'monospace' : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalPages,
    required int totalCards,
    required int startIndex,
    required int endIndex,
    required VoidCallback? onFirst,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
    required VoidCallback? onLast,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'عرض $startIndex-$endIndex من $totalCards',
                style: TextStyle(fontSize: 11.sp, color: AppColors.gray600),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  items: _rowsPerPageOptions
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value صف', style: TextStyle(fontSize: 11.sp)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _rowsPerPage = value;
                        _currentPage = 0;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: onFirst,
                  color: onFirst != null ? AppColors.primary : AppColors.gray400,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrevious,
                  color: onPrevious != null ? AppColors.primary : AppColors.gray400,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '$currentPage / $totalPages',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNext,
                  color: onNext != null ? AppColors.primary : AppColors.gray400,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: onLast,
                  color: onLast != null ? AppColors.primary : AppColors.gray400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedView) {
      case 'available':
        icon = Icons.inventory_2_outlined;
        message = 'لا توجد كروت متاحة\nقم باستيراد الكروت أولاً';
      case 'transferred':
        icon = Icons.send_outlined;
        message = 'لا توجد كروت منقولة\nالكروت المنقولة للمتاجر ستظهر هنا';
      case 'sold':
        icon = Icons.sell_outlined;
        message = 'لا توجد كروت مباعة\nالكروت المباعة من قبل المتاجر ستظهر هنا';
      default:
        icon = Icons.inventory_2_outlined;
        message = 'لا توجد كروت';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.w, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected ? AppColors.primary : Colors.transparent;
    final textColor = isSelected ? Colors.white : AppColors.gray600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.isSelected = false,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.12);
    final borderColor = isSelected ? color : color.withValues(alpha: 0.4);
    final textColor = isSelected ? color : color.withValues(alpha: 0.85);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderColor),
        ),
        child: content,
      ),
    );
  }
}
