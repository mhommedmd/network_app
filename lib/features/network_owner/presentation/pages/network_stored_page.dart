import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/card_model.dart';
import '../../data/providers/card_provider.dart';
import '../../data/services/firebase_card_cleanup_service.dart';

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
  String? _packageToDelete; // الباقة المراد حذف كروتها

  @override
  void initState() {
    super.initState();
    _loadCards();

    // جدولة التنظيف التلقائي للكروت القديمة (يعمل في الخلفية)
    FirebaseCardCleanupService.scheduleAutomaticCleanup();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      // تحميل الكروت حسب القسم المختار
      CardStatus? statusToLoad;
      switch (_selectedView) {
        case 'available':
          statusToLoad = CardStatus.available;
          break;
        case 'transferred':
          statusToLoad = CardStatus.transferred;
          break;
        case 'sold':
          statusToLoad = CardStatus.sold;
          break;
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

  List<CardModel> _getFilteredCards(List<CardModel> cards) {
    // الكروت بالفعل مفلترة حسب القسم المختار من loadCards
    var filtered = cards;

    // فرز حسب الباقة
    filtered.sort((a, b) {
      final packageCompare = a.packageName.compareTo(b.packageName);
      if (packageCompare != 0) {
        return _sortByPackageAscending ? packageCompare : -packageCompare;
      }
      // إذا كانت نفس الباقة، رتب حسب رقم الكرت
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

  Future<void> _confirmDeleteAllPackageCards() async {
    if (_packageToDelete == null) {
      CustomToast.warning(
        context,
        'اختر الباقة من القائمة المنسدلة أولاً',
        title: 'لم يتم اختيار باقة',
      );
      return;
    }

    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final cardsToDelete = cardProvider.cards
        .where((card) => card.packageName == _packageToDelete)
        .toList();

    if (cardsToDelete.isEmpty) {
      CustomToast.warning(
        context,
        'المخزون فارغ من هذه الباقة',
        title: 'لا توجد كروت "$_packageToDelete"',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'سيتم حذف ${cardsToDelete.length} كرت من الباقة "$_packageToDelete".\n\nهل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // عرض مؤشر تحميل
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // حذف جميع الكروت
      int deletedCount = 0;
      for (final card in cardsToDelete) {
        final success = await cardProvider.deleteCard(card.id);
        if (success) deletedCount++;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل

      if (deletedCount == cardsToDelete.length) {
        CustomToast.success(
          context,
          'تم حذف جميع كروت الباقة من المخزون',
          title: 'تم حذف $deletedCount كرت',
        );
        setState(() => _packageToDelete = null);
        _loadCards();
      } else {
        CustomToast.warning(
          context,
          'تم حذف $deletedCount كرت بنجاح، وفشل حذف ${cardsToDelete.length - deletedCount} كرت',
          title: 'حذف جزئي',
        );
        _loadCards();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<CardProvider>(context);
    final stats = cardProvider.stats;
    final allCards = cardProvider.cards;
    final filteredCards = _getFilteredCards(allCards);
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
          cardProvider, stats, filteredCards, packageNames, allCards),
    );
  }

  Widget _buildInventoryContent(
    CardProvider cardProvider,
    Map<String, dynamic>? stats,
    List<CardModel> filteredCards,
    List<String> packageNames,
    List<CardModel> allCards,
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
                      (index) => Expanded(
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
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.gray200),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SkeletonLine(width: 30, height: 12),
                              SizedBox(width: 20.w),
                              const SkeletonLine(width: 80, height: 12),
                              SizedBox(width: 20.w),
                              const SkeletonLine(width: 100, height: 12),
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
              // إحصائيات
              if (stats != null) _buildStats(stats, allCards),
              SizedBox(height: 16.h),
              // اختيار نوع العرض
              _buildViewSelector(),
              SizedBox(height: 16.h),
              // خيار حذف جميع كروت باقة (فقط للكروت المتاحة)
              if (_selectedView == 'available')
                _buildBulkDeleteSection(packageNames),
              if (_selectedView == 'available') SizedBox(height: 16.h),
              // جدول الكروت
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadCards();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 500));
                  },
                  color: AppColors.primary,
                  child: filteredCards.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(),
                          ),
                        )
                      : _buildCardsList(filteredCards),
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
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewButton(
              label: 'الكروت المتاحة',
              icon: Icons.inventory_2,
              isSelected: _selectedView == 'available',
              onTap: () {
                setState(() {
                  _selectedView = 'available';
                  _currentPage = 0;
                });
                _loadCards();
              },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _ViewButton(
              label: 'المنقولة للمتاجر',
              icon: Icons.send,
              isSelected: _selectedView == 'transferred',
              onTap: () {
                setState(() {
                  _selectedView = 'transferred';
                  _currentPage = 0;
                });
                _loadCards();
              },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _ViewButton(
              label: 'المباعة',
              icon: Icons.sell,
              isSelected: _selectedView == 'sold',
              onTap: () {
                setState(() {
                  _selectedView = 'sold';
                  _currentPage = 0;
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
    // حساب عدد الكروت لكل باقة
    final packageCounts = <String, int>{};
    for (final card in allCards) {
      packageCounts.update(
        card.packageName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // ترتيب الباقات أبجدياً
    final sortedPackages = packageCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📊 إحصائيات المخزون',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12.w),
              _StatChip(
                label: 'الإجمالي',
                value: '${stats['totalCards'] ?? 0}',
                color: AppColors.primary,
              ),
            ],
          ),
          if (sortedPackages.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: sortedPackages.map((entry) {
                return _StatChip(
                  label: entry.key,
                  value: '${entry.value}',
                  color: AppColors.blue500,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkDeleteSection(List<String> packageNames) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _packageToDelete,
              decoration: InputDecoration(
                labelText: 'حذف جميع كروت الباقة',
                prefixIcon: Icon(Icons.delete_sweep,
                    color: AppColors.error, size: 20.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
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
                      setState(() => _packageToDelete = value);
                    },
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton.icon(
            onPressed:
                _packageToDelete == null ? null : _confirmDeleteAllPackageCards,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: Icon(Icons.delete_forever, size: 20.w),
            label: Text(
              'حذف الكل',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(List<CardModel> cards) {
    // حساب الترقيم (Pagination)
    final totalPages = (cards.length / _rowsPerPage).ceil();
    final maxPageIndex = totalPages == 0 ? 0 : totalPages - 1;
    final safeCurrentPage =
        cards.isEmpty ? 0 : _currentPage.clamp(0, maxPageIndex);

    final startIndex = cards.isEmpty ? 0 : safeCurrentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, cards.length);
    final pageCards =
        cards.isEmpty ? <CardModel>[] : cards.sublist(startIndex, endIndex);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            // جدول الكروت
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: pageCards.length > 10,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 48.h,
                      dataRowMinHeight: 40.h,
                      dataRowMaxHeight: 48.h,
                      columnSpacing: 20.w,
                      horizontalMargin: 16.w,
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.gray50),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.gray200),
                        ),
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            '#',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: InkWell(
                            onTap: _togglePackageSort,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'الباقة',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  _sortByPackageAscending
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: AppColors.primary,
                                  size: 20.w,
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'رقم الكرت',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'حذف',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                      ],
                      rows: pageCards.asMap().entries.map((entry) {
                        final index = entry.key;
                        final card = entry.value;
                        final globalIndex = startIndex + index + 1;
                        final isEven = index.isEven;

                        return DataRow(
                          color: WidgetStateProperty.all(
                            isEven ? Colors.white : AppColors.gray50,
                          ),
                          cells: [
                            DataCell(
                              Text(
                                '$globalIndex',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray800,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                card.packageName,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.gray800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                card.cardNumber,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: AppColors.gray900,
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppColors.error,
                                  iconSize: 20.w,
                                  tooltip: 'حذف الكرت',
                                  onPressed: () => _confirmDeleteCard(card),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            // شريط الترقيم (Pagination)
            _buildPaginationBar(
              currentPage: safeCurrentPage + 1,
              totalPages: totalPages == 0 ? 1 : totalPages,
              totalCards: cards.length,
              startIndex: startIndex + 1,
              endIndex: endIndex,
              onFirst:
                  safeCurrentPage > 0 ? () => _goToPage(0, maxPageIndex) : null,
              onPrevious: safeCurrentPage > 0
                  ? () => _goToPage(safeCurrentPage - 1, maxPageIndex)
                  : null,
              onNext: safeCurrentPage < maxPageIndex
                  ? () => _goToPage(safeCurrentPage + 1, maxPageIndex)
                  : null,
              onLast: safeCurrentPage < maxPageIndex
                  ? () => _goToPage(maxPageIndex, maxPageIndex)
                  : null,
            ),
          ],
        ),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: AppColors.gray50,
        border: Border(
          top: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12.w,
        runSpacing: 8.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عرض $startIndex-$endIndex من $totalCards',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: _rowsPerPageOptions.map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        '$value / صفحة',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.gray800,
                        ),
                      ),
                    );
                  }).toList(),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                iconSize: 20.w,
                onPressed: onFirst,
                color: onFirst != null ? AppColors.primary : AppColors.gray400,
                tooltip: 'الصفحة الأولى',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: 20.w,
                onPressed: onPrevious,
                color:
                    onPrevious != null ? AppColors.primary : AppColors.gray400,
                tooltip: 'السابق',
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'صفحة $currentPage من $totalPages',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                iconSize: 20.w,
                onPressed: onNext,
                color: onNext != null ? AppColors.primary : AppColors.gray400,
                tooltip: 'التالي',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                iconSize: 20.w,
                onPressed: onLast,
                color: onLast != null ? AppColors.primary : AppColors.gray400,
                tooltip: 'الصفحة الأخيرة',
              ),
            ],
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
        break;
      case 'transferred':
        icon = Icons.send_outlined;
        message = 'لا توجد كروت منقولة\nالكروت المنقولة للمتاجر ستظهر هنا';
        break;
      case 'sold':
        icon = Icons.sell_outlined;
        message = 'لا توجد كروت مباعة\nالكروت المباعة من قبل المتاجر ستظهر هنا';
        break;
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
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20.w,
              color: isSelected ? Colors.white : AppColors.gray600,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
