import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/inventory_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_tab_bar.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../data/models/card_model.dart';
import '../../data/models/package_model.dart';
import '../../data/providers/card_provider.dart';
import '../../data/providers/package_provider.dart';
import '../../data/services/firebase_card_service.dart';

class ImportCardsPage extends StatefulWidget {
  const ImportCardsPage({
    required this.onBack,
    required this.onImportComplete,
    this.packageNames = const [],
    super.key,
  });

  final VoidCallback onBack;
  final JsonMapCallback onImportComplete;
  final List<String> packageNames;

  @override
  State<ImportCardsPage> createState() => _ImportCardsPageState();
}

class _ImportCardsPageState extends State<ImportCardsPage> {
  static const int _maxCardsPerImport = 1000;
  static const int _cardsPerColumn = 10;
  static const List<String> _supportedExtensions = <String>[
    'csv',
    'CSV',
    'txt',
    'TXT',
    'xlsx',
    'XLSX',
    'xls',
    'XLS',
    'pdf',
    'PDF',
    'excel',
    'EXCEL',
  ];

  PlatformFile? _selectedFile;
  String? _selectedPackageId;
  String? _generationPackageId;
  List<String> _importedCards = <String>[];
  bool _isGeneratingCards = false;
  final InventoryRepository _inventoryRepo = InventoryRepository.instance;
  List<PackageModel> _availablePackages = [];

  final TextEditingController _cardDigitsController = TextEditingController(text: '9');
  final TextEditingController _cardsCountController = TextEditingController();
  final TextEditingController _generationDigitsController = TextEditingController(text: '9');
  final TextEditingController _cardsPreviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardsCountController.addListener(_handleCountChanged);
    _cardDigitsController.addListener(_handleDigitsChanged);
    _cardsPreviewController.addListener(_handlePreviewChanged);
    _loadPackages();
  }

  void _loadPackages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider = Provider.of<PackageProvider>(context, listen: false);
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isNotEmpty) {
      packageProvider.loadPackages(networkId);
      cardProvider.loadCardsByStatus(networkId, CardStatus.available);
    }
  }

  PackageModel? _getSelectedPackage() {
    if (_selectedPackageId == null) return null;
    return _availablePackages.firstWhere(
      (pkg) => pkg.id == _selectedPackageId,
      orElse: () => _availablePackages.first,
    );
  }

  @override
  void didUpdateWidget(covariant ImportCardsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث قائمة الباقات إذا تغيرت
  }

  @override
  void dispose() {
    _cardsCountController.removeListener(_handleCountChanged);
    _cardDigitsController.removeListener(_handleDigitsChanged);
    _cardsPreviewController.removeListener(_handlePreviewChanged);
    _cardDigitsController.dispose();
    _cardsCountController.dispose();
    _generationDigitsController.dispose();
    _cardsPreviewController.dispose();
    super.dispose();
  }

  void _handleCountChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleDigitsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handlePreviewChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleFileSelect() async {
    if (_selectedPackageId == null) {
      _showError('يرجى اختيار الباقة قبل استعراض الملف');
      return;
    }
    if (_availablePackages.isEmpty) {
      _showError('لا توجد باقات متاحة. يرجى إضافة باقة أولاً');
      return;
    }
    final digits = int.tryParse(_cardDigitsController.text);
    if (digits == null || digits <= 0) {
      _showError('يرجى إدخال عدد أرقام الكرت قبل استعراض الملف');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _supportedExtensions,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    List<String> parsedCards;
    try {
      parsedCards = await _extractCardsFromFile(file, digits);
    } on Exception catch (_) {
      _showError('حدث خطأ أثناء قراءة الملف، يرجى المحاولة مرة أخرى');
      return;
    }

    if (parsedCards.isEmpty) {
      _showError('لم يتم العثور على أكواد تطابق عدد الأرقام المحدد');
      return;
    }

    // 1. فحص التكرار داخل الملف نفسه
    final duplicates = _findDuplicates(parsedCards);
    if (duplicates.isNotEmpty) {
      final displayDuplicates = duplicates.take(5).join(', ');
      final moreCount = duplicates.length > 5 ? ' و${duplicates.length - 5} أخرى' : '';
      _showError(
        'تم العثور على ${duplicates.length} كود مكرر داخل الملف:\n$displayDuplicates$moreCount',
      );
      return;
    }

    // 2. فحص التعارض مع Firebase (الكروت المتاحة والمنقولة)
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final firebaseConflicts = await _findConflictsWithFirebase(parsedCards);

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (firebaseConflicts.isNotEmpty) {
      final displayConflicts = firebaseConflicts.take(5).join(', ');
      final moreCount = firebaseConflicts.length > 5 ? ' و${firebaseConflicts.length - 5} أخرى' : '';
      _showError(
        'تم العثور على ${firebaseConflicts.length} كود موجود مسبقاً في المخزون (متاح أو منقول):\n$displayConflicts$moreCount\n\n⚠️ لا يمكن استيراد كروت موجودة مسبقاً',
      );
      return;
    }

    // 3. فحص التعارض مع المخزون المحلي (إضافي)
    final inventoryConflicts = _findConflictsWithInventory(parsedCards);
    if (inventoryConflicts.isNotEmpty) {
      final displayConflicts = inventoryConflicts.take(5).join(', ');
      final moreCount = inventoryConflicts.length > 5 ? ' و${inventoryConflicts.length - 5} أخرى' : '';
      _showError(
        'بعض الأكواد موجودة في المخزون المحلي:\n$displayConflicts$moreCount',
      );
      return;
    }

    if (parsedCards.length > _maxCardsPerImport) {
      _showError(
        'يمكنك استيراد $_maxCardsPerImport كرت كحد أقصى في العملية الواحدة. '
        'عدد الأكواد في الملف (${parsedCards.length}) يتجاوز الحد المسموح.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedFile = file;
      _importedCards = parsedCards;
      _cardsPreviewController.text = _formatCardsForEditor(parsedCards);
    });

    if (!mounted) return;
    CustomToast.success(
      context,
      'جاهز للحفظ في Firebase',
      title: 'تم تحميل ${parsedCards.length} كرت',
    );
  }

  List<String> _parseCards(String raw, int digits) {
    if (digits <= 0) {
      return <String>[];
    }
    // Merge all alphanumeric characters into one stream before chunking by length.
    final sanitized = raw.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
    if (sanitized.isEmpty) {
      return <String>[];
    }
    final cards = <String>[];
    for (var idx = 0; idx + digits <= sanitized.length; idx += digits) {
      cards.add(sanitized.substring(idx, idx + digits));
    }
    return cards;
  }

  Future<List<String>> _extractCardsFromFile(
    PlatformFile file,
    int digits,
  ) async {
    final extension = (file.extension ?? '').toLowerCase();
    final bytes = await _resolveFileBytes(file);
    if (bytes == null || bytes.isEmpty) {
      return <String>[];
    }

    switch (extension) {
      case 'csv':
      case 'txt':
        return _parseCards(_decodeString(bytes), digits);
      case 'xlsx':
      case 'xls':
      case 'excel':
        return _parseExcelBytes(bytes, digits);
      case 'pdf':
        return _parsePdfBytes(bytes, digits);
      default:
        return _parseCards(_decodeString(bytes), digits);
    }
  }

  Future<Uint8List?> _resolveFileBytes(PlatformFile file) async {
    return file.readBytes();
  }

  String _decodeString(Uint8List bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<List<String>> _parseExcelBytes(Uint8List bytes, int digits) async {
    try {
      final workbook = excel.Excel.decodeBytes(bytes);
      final buffer = StringBuffer();

      for (final sheetName in workbook.tables.keys) {
        final sheet = workbook.tables[sheetName];
        if (sheet == null) continue;

        for (final row in sheet.rows) {
          for (final cell in row) {
            final value = cell?.value?.toString().trim();
            if (value != null && value.isNotEmpty) {
              buffer.writeln(value);
            }
          }
        }
      }

      final content = buffer.toString().trim();
      return content.isEmpty ? <String>[] : _parseCards(content, digits);
    } on Exception catch (_) {
      return <String>[];
    }
  }

  Future<List<String>> _parsePdfBytes(Uint8List bytes, int digits) async {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText().trim();
      return text.isEmpty ? <String>[] : _parseCards(text, digits);
    } on Exception catch (_) {
      return <String>[];
    } finally {
      document?.dispose();
    }
  }

  Future<void> _handleImportCards() async {
    if (_selectedPackageId == null || _availablePackages.isEmpty) {
      _showError('يرجى اختيار الباقة قبل إضافة الكروت');
      return;
    }

    final selectedPackage = _getSelectedPackage();
    if (selectedPackage == null) {
      _showError('الباقة المحددة غير موجودة');
      return;
    }

    final digits = int.tryParse(_cardDigitsController.text);
    if (digits == null || digits <= 0) {
      _showError('عدد أرقام الكرت غير صالح');
      return;
    }

    final editedCards = _collectCardsFromEditor(digits);
    if (editedCards == null || editedCards.isEmpty) {
      return;
    }

    // 1. فحص التكرار داخل القائمة المحررة
    final duplicates = _findDuplicates(editedCards);
    if (duplicates.isNotEmpty) {
      final displayDuplicates = duplicates.take(5).join(', ');
      final moreCount = duplicates.length > 5 ? ' و${duplicates.length - 5} أخرى' : '';
      _showError(
        'تم العثور على ${duplicates.length} كود مكرر داخل القائمة:\n$displayDuplicates$moreCount',
      );
      return;
    }

    // 2. فحص التعارض مع Firebase (الكروت المتاحة والمنقولة)
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
              'جارٍ فحص التعارضات مع المخزون...',
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

    final firebaseConflicts = await _findConflictsWithFirebase(editedCards);

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (firebaseConflicts.isNotEmpty) {
      final displayConflicts = firebaseConflicts.take(5).join(', ');
      final moreCount = firebaseConflicts.length > 5 ? ' و${firebaseConflicts.length - 5} أخرى' : '';
      _showError(
        'تم العثور على ${firebaseConflicts.length} كود موجود مسبقاً في المخزون (متاح أو منقول):\n$displayConflicts$moreCount\n\n⚠️ لا يمكن استيراد كروت موجودة مسبقاً',
      );
      return;
    }

    // 3. فحص التعارض مع المخزون المحلي (إضافي)
    final inventoryConflicts = _findConflictsWithInventory(editedCards);
    if (inventoryConflicts.isNotEmpty) {
      final displayConflicts = inventoryConflicts.take(5).join(', ');
      final moreCount = inventoryConflicts.length > 5 ? ' و${inventoryConflicts.length - 5} أخرى' : '';
      _showError(
        'بعض الأكواد موجودة في المخزون المحلي:\n$displayConflicts$moreCount',
      );
      return;
    }

    _importedCards = editedCards;

    // حفظ في المخزون المحلي (للتوافق مع الإصدار السابق)
    final storedCodes = _importedCards
        .map(
          (code) => StoredCode(
            packageCode: selectedPackage.id,
            packageName: selectedPackage.name,
            codeNumber: code,
          ),
        )
        .toList();
    _inventoryRepo.importCodes(storedCodes);

    // عرض مؤشر التحميل
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // حفظ الكروت في Firebase
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final packageProvider = Provider.of<PackageProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      _showError('يجب تسجيل الدخول أولاً');
      return;
    }

    // إنشاء قائمة من CardModel لكل كرت
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: selectedPackage.validityDays));

    final cardModels = _importedCards.map((cardNumber) {
      // توليد PIN عشوائي (يمكنك تخصيصه حسب الحاجة)
      final pin = _generateRandomPin();

      return CardModel(
        id: '', // سيتم توليده تلقائياً من Firestore
        cardNumber: cardNumber,
        pin: pin,
        packageId: selectedPackage.id, // استخدام معرف الباقة الحقيقي
        packageName: selectedPackage.name,
        price: selectedPackage.sellingPrice, // استخدام السعر من الباقة
        expiryDate: expiryDate, // استخدام صلاحية الباقة
        status: CardStatus.available,
        networkId: currentUser.id,
        createdBy: currentUser.id,
        createdAt: now,
        updatedAt: now,
        notes: 'تم الاستيراد من ${_selectedFile?.name ?? "ملف"}',
      );
    }).toList();

    // حفظ الكروت في Firebase
    final success = await cardProvider.importCards(cardModels);

    // تحديث مخزون الباقة (زيادة الكروت المتاحة)
    if (success) {
      final newStock = selectedPackage.stock + _importedCards.length;
      await packageProvider.updateStock(selectedPackage.id, newStock);
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    if (success) {
      final payload = <String, dynamic>{
        'packageName': selectedPackage.name,
        'packageId': selectedPackage.id,
        'cards': _importedCards,
        'cardDigits': digits,
        'fileName': _selectedFile?.name,
        'importedAt': DateTime.now().toIso8601String(),
      };

      final addedCount = _importedCards.length;
      _cardsPreviewController.text = _formatCardsForEditor(_importedCards);

      CustomToast.success(
        context,
        'تم اضافة $addedCount كرت الى المخزون بنجاح',
        title: 'عملية ناجحة',
      );

      widget.onImportComplete(payload);
    } else {
      _showError(cardProvider.error ?? 'فشل في حفظ الكروت في المخزون');
    }
  }

  // توليد PIN عشوائي (4 أرقام)
  String _generateRandomPin() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  Future<void> _handleGenerateCards() async {
    if (_generationPackageId == null || _availablePackages.isEmpty) {
      _showError('يرجى اختيار الباقة أولاً');
      return;
    }

    final selectedPackage = _availablePackages.firstWhere(
      (pkg) => pkg.id == _generationPackageId,
      orElse: () => _availablePackages.first,
    );

    final digits = int.tryParse(_generationDigitsController.text);
    if (digits == null || digits <= 0 || digits > 32) {
      _showError('عدد أرقام الكرت يجب أن يكون بين 1 و 32');
      return;
    }
    final count = int.tryParse(_cardsCountController.text);
    if (count == null || count <= 0 || count > _maxCardsPerImport) {
      _showError(
        'يمكن توليد من 1 إلى $_maxCardsPerImport كرت في العملية الواحدة',
      );
      return;
    }

    setState(() {
      _isGeneratingCards = true;
    });

    try {
      final generatedCards = await _generateCardsViaApi(
        packageName: selectedPackage.name,
        digits: digits,
        count: count,
      );

      if (!mounted) return;
      if (generatedCards.isEmpty) {
        CustomToast.info(
          context,
          'سيتم تنفيذ العملية عند ربط الـ API',
          title: 'تم حفظ طلب توليد $count كرت',
        );
      } else {
        CustomToast.success(
          context,
          'تم حفظ الكروت في المخزون',
          title: 'تم استلام ${generatedCards.length} كرت',
        );
      }

      if (generatedCards.isNotEmpty) {
        final payload = <String, dynamic>{
          'packageName': selectedPackage.name,
          'packageId': selectedPackage.id,
          'cards': generatedCards,
          'cardDigits': digits,
          'generatedAt': DateTime.now().toIso8601String(),
        };
        widget.onImportComplete(payload);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCards = false;
        });
      }
    }
  }

  Future<List<String>> _generateCardsViaApi({
    required String packageName,
    required int digits,
    required int count,
  }) async {
    // TODO(backend): استبدل هذا الاسترجاع الوهمي بربط فعلي مع واجهة ميكروتيك
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return <String>[];
  }

  void _showError(String message) {
    final errorMessage = ErrorHandler.extractErrorMessage(message);
    CustomToast.error(
      context,
      errorMessage,
      title: 'خطأ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          surfaceTintColor: const Color(0xFFF5F5F5),
          elevation: 0,
          title: Text(
            'استيراد الكروت',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C2B33),
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1C2B33)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: const Color(0xFF1C2B33),
            onPressed: widget.onBack,
            tooltip: 'رجوع',
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildImportNotice(),
                  SizedBox(height: 12.h),
                  _buildTabBarCard(),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFileImportTab(),
                        _buildDirectGenerationTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarCard() {
    return AppPrimaryTabBar(
      style: AppTabBarStyle.filledSegment,
      isDense: true,
      enableBlur: false,
      outlineColor: AppColors.gray200,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      tabs: const [
        AppPrimaryTab(label: 'استيراد الكروت'),
        AppPrimaryTab(label: 'توليد الكروت'),
      ],
    );
  }

  Widget _buildFileImportTab() {
    final digits = _currentDigits;
    final previewCount = _calculateEditorCardCount(digits);
    final editorHasContent = _cardsPreviewController.text.trim().isNotEmpty;
    final shouldShowPreview = editorHasContent && previewCount > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AppCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackageDropdown(
              selectedValue: _selectedPackageId,
              onChanged: (value) => setState(() {
                _selectedPackageId = value;
              }),
            ),
            SizedBox(height: 16.h),
            _buildDigitsField(
              controller: _cardDigitsController,
              label: 'عدد أرقام الكرت',
            ),
            SizedBox(height: 16.h),
            _buildFileSection(),
            if (shouldShowPreview) ...[
              SizedBox(height: 16.h),
              _buildImportSummary(),
              SizedBox(height: 12.h),
              _buildCardsEditor(),
            ],
            SizedBox(height: 20.h),
            AppButton(
              text: 'إضافة الكروت ($previewCount)',
              onPressed: (_selectedPackageId != null && previewCount > 0) ? _handleImportCards : null,
              icon: Icon(
                Icons.cloud_upload,
                size: 20.w,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملف الكروت',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        SizedBox(height: 8.h),
        if (_selectedFile != null) _buildFileDetailsCard(),
        AppButton(
          text: _selectedFile == null ? 'استعراض الملف' : 'تغيير الملف',
          onPressed: _canPickFile ? _handleFileSelect : null,
          icon: Icon(
            Icons.upload_file,
            size: 20.w,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFileDetailsCard() {
    final file = _selectedFile;
    if (file == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatFileSize(file.size),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSummary() {
    final digits = _currentDigits;
    final previewCount = _calculateEditorCardCount(digits);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'الكروت المستوردة',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '$previewCount كرت',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsEditor() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: TextFormField(
        controller: _cardsPreviewController,
        maxLines: 16,
        minLines: 12,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'سيتم عرض الأكواد هنا بشكل قابل للتعديل',
        ),
        style: TextStyle(
          fontSize: 13.sp,
          height: 1.5,
          fontFamily: 'monospace',
          color: AppColors.gray800,
        ),
      ),
    );
  }

  Widget _buildDirectGenerationTab() {
    final hasPreview = _cardsCountController.text.isNotEmpty && _generationPackageId != null;
    final digits = int.tryParse(_generationDigitsController.text);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AppCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackageDropdown(
              selectedValue: _generationPackageId,
              onChanged: (value) => setState(() {
                _generationPackageId = value;
              }),
            ),
            SizedBox(height: 16.h),
            _buildDigitsField(
              controller: _generationDigitsController,
              label: 'عدد أرقام الكرت',
            ),
            SizedBox(height: 16.h),
            _buildCardsCountField(),
            if (hasPreview && digits != null) ...[
              SizedBox(height: 20.h),
              _buildGenerationPreview(digits),
            ],
            SizedBox(height: 20.h),
            AppButton(
              text: 'توليد الكروت (${_cardsCountController.text.isEmpty ? '0' : _cardsCountController.text})',
              onPressed: (_generationPackageId != null &&
                      _cardsCountController.text.isNotEmpty &&
                      digits != null &&
                      digits > 0 &&
                      !_isGeneratingCards)
                  ? _handleGenerateCards
                  : null,
              icon: Icon(
                Icons.bolt,
                size: 20.w,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageDropdown({
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    final packageProvider = Provider.of<PackageProvider>(context);
    final cardProvider = Provider.of<CardProvider>(context);
    _availablePackages = packageProvider.packages;
    final hasPackages = _availablePackages.isNotEmpty;
    final initialValue = hasPackages ? selectedValue : null;

    final availableCounts = <String, int>{};
    for (final card in cardProvider.cards) {
      if (card.status != CardStatus.available) continue;
      availableCounts.update(card.packageId, (value) => value + 1, ifAbsent: () => 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الباقة',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        SizedBox(height: 8.h),
        if (!hasPackages)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 24.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'لا توجد باقات! يجب إضافة باقة أولاً قبل استيراد الكروت',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(initialValue),
            initialValue: initialValue,
            decoration: InputDecoration(
              hintText: 'اختر الباقة',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            items: _availablePackages
                .map(
                  (pkg) => DropdownMenuItem(
                    value: pkg.id,
                    child: Text('${pkg.name} (${availableCounts[pkg.id] ?? 0} كرت متاح)'),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
      ],
    );
  }

  Widget _buildDigitsField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'مثال: 9',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsCountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'عدد الكروت المطلوب',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _cardsCountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'مثال: 100',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerationPreview(int digits) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.blue200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18.w,
                color: AppColors.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                'معاينة التوليد',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'الباقة المختارة: ${_generationPackageId != null ? _availablePackages.firstWhere((p) => p.id == _generationPackageId, orElse: () => _availablePackages.first).name : '-'}',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            'عدد الكروت: ${_cardsCountController.text}',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            'طول الكود: $digits رقم',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes بايت';
    }
    final kb = sizeInBytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} كيلوبايت';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} ميجابايت';
  }

  Widget _buildImportNotice() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'تنبيه: يمكنك استيراد أو توليد $_maxCardsPerImport كرت كحد أقصى في العملية الواحدة.',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _currentDigits => int.tryParse(_cardDigitsController.text) ?? 0;

  bool get _canPickFile => _selectedPackageId != null && _currentDigits > 0 && _availablePackages.isNotEmpty;

  String _formatCardsForEditor(List<String> cards) {
    if (cards.isEmpty) {
      return '';
    }
    final columns = <List<String>>[];
    for (var i = 0; i < cards.length; i += _cardsPerColumn) {
      final end = i + _cardsPerColumn < cards.length ? i + _cardsPerColumn : cards.length;
      columns.add(cards.sublist(i, end));
    }

    final maxRows = columns.fold<int>(0, (max, column) {
      return column.length > max ? column.length : max;
    });

    final buffer = StringBuffer();
    for (var row = 0; row < maxRows; row++) {
      final pieces = <String>[];
      for (final column in columns) {
        if (row >= column.length) {
          continue;
        }
        pieces.add(column[row]);
      }
      if (pieces.isNotEmpty) {
        buffer.writeln(pieces.join(' '));
      }
    }

    return buffer.toString().trimRight();
  }

  List<String>? _collectCardsFromEditor(int digits) {
    if (digits <= 0) {
      _showError('عدد أرقام الكرت غير صالح');
      return null;
    }

    final lines = _cardsPreviewController.text.split(RegExp('[\r\n]+'));
    final collected = <String>[];
    final seen = <String>{};

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final tokens = _tokenizeEditorLine(trimmed);
      for (final token in tokens) {
        if (token.isEmpty) continue;

        final sanitized = token.replaceAll(RegExp('[^a-zA-Z0-9]'), '');

        // التحقق من طول الكود
        if (sanitized.length != digits) {
          _showError('الكود "$token" يجب أن يحتوي على $digits محارف');
          return null;
        }

        // التحقق من التكرار
        if (!seen.add(sanitized)) {
          _showError('الكود "$sanitized" مكرر داخل القائمة');
          return null;
        }

        collected.add(sanitized);

        // التحقق من الحد الأقصى
        if (collected.length > _maxCardsPerImport) {
          _showError('الحد الأقصى $_maxCardsPerImport كرت في العملية الواحدة');
          return null;
        }
      }
    }

    if (collected.isEmpty) {
      _showError('لا توجد أكواد صالحة في القائمة');
      return null;
    }

    return collected;
  }

  int _calculateEditorCardCount(int digits) {
    if (digits <= 0) return 0;

    return _cardsPreviewController.text
        .split(RegExp('[\r\n]+'))
        .where((line) => line.trim().isNotEmpty)
        .expand((line) => _tokenizeEditorLine(line.trim()))
        .where((token) => token.isNotEmpty)
        .map((token) => token.replaceAll(RegExp('[^a-zA-Z0-9]'), ''))
        .where((sanitized) => sanitized.length == digits)
        .length;
  }

  List<String> _tokenizeEditorLine(String line) {
    return line.split(' ').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  }

  Set<String> _findDuplicates(List<String> codes) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final code in codes) {
      if (!seen.add(code)) {
        duplicates.add(code);
      }
    }
    return duplicates;
  }

  Set<String> _findConflictsWithInventory(List<String> codes) {
    final existing = _inventoryRepo.ownerCodes.map((c) => c.codeNumber).toSet()
      ..addAll(_inventoryRepo.posCodes.map((c) => c.codeNumber));
    final conflicts = <String>{};
    for (final code in codes) {
      if (existing.contains(code)) {
        conflicts.add(code);
      }
    }
    return conflicts;
  }

  /// فحص الكروت المكررة في Firebase (المتاحة والمنقولة)
  Future<Set<String>> _findConflictsWithFirebase(List<String> codes) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final networkId = authProvider.user?.id ?? '';

    if (networkId.isEmpty) {
      return <String>{};
    }

    try {
      final conflicts = <String>{};

      // جلب جميع الكروت المتاحة والمنقولة من Firebase
      final availableCards = await FirebaseCardService.getCardsByStatusOnce(
        networkId,
        CardStatus.available,
      );
      final transferredCards = await FirebaseCardService.getCardsByStatusOnce(
        networkId,
        CardStatus.transferred,
      );

      // إنشاء مجموعة من أرقام الكروت الموجودة
      final existingCardNumbers = <String>{
        ...availableCards.map((c) => c.cardNumber),
        ...transferredCards.map((c) => c.cardNumber),
      };

      // فحص التعارضات
      for (final code in codes) {
        if (existingCardNumbers.contains(code)) {
          conflicts.add(code);
        }
      }

      return conflicts;
    } on Exception {
      // في حالة الخطأ، نستمر دون فحص Firebase (لتجنب منع الاستيراد)
      return <String>{};
    }
  }
}

// Extension method لتبسيط عملية القراءة
extension _PlatformFileExtension on PlatformFile {
  Future<Uint8List?> readBytes() async {
    if (bytes != null && bytes!.isNotEmpty) {
      return bytes!;
    }
    if (path == null) return null;
    try {
      return await File(path!).readAsBytes();
    } on Exception catch (_) {
      return null;
    }
  }
}
