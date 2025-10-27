import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../common/presentation/pages/chat_page.dart';
import '../../../common/presentation/pages/profile_page.dart';
import '../../../network_owner/data/models/vendor_model.dart';
import '../../../network_owner/presentation/pages/accounts_page.dart';
import '../../../network_owner/presentation/pages/add_package_page.dart';
import '../../../network_owner/presentation/pages/cash_payment_page.dart';
import '../../../network_owner/presentation/pages/edit_package_page.dart';
import '../../../network_owner/presentation/pages/import_cards_page.dart';
import '../../../network_owner/presentation/pages/merchant_transactions_page.dart';
import '../../../network_owner/presentation/pages/network_owner_home_page.dart';
import '../../../network_owner/presentation/pages/network_page.dart';
import '../../../network_owner/presentation/pages/order_details_page.dart';
import '../../../pos_vendor/presentation/pages/cash_payment_page.dart';
import '../../../pos_vendor/presentation/pages/network_details_page.dart';
import '../../../pos_vendor/presentation/pages/networks_page.dart';
import '../../../pos_vendor/presentation/pages/pos_vendor_home_page.dart';
import '../../../pos_vendor/presentation/pages/request_cards_page.dart';
import '../../../pos_vendor/presentation/pages/sale_process_page.dart';
import '../../../pos_vendor/presentation/pages/send_order_page.dart';

enum PageType {
  main,
  addPackage,
  editPackage,
  orderDetails,
  importCards,
  merchantTransactions,
  cashPaymentOwner,
  cashPaymentVendor,
  saleProcess,
  networkDetails,
  sendOrder,
  requestCards,
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  AppTab activeTab = AppTab.home;
  PageType currentPage = PageType.main;

  // State for navigation
  Map<String, dynamic>? newPackage;
  Map<String, dynamic>? editingPackage;
  Map<String, dynamic>? updatedPackage;
  int? selectedOrderId;
  String? selectedVendorId;
  int? selectedPackageId;
  int? selectedNetworkId;
  String? selectedMerchantId;
  int networkTabIndex = 0;
  final List<String> _packageNames = [
    'باقــة أساسية',
    'باقــة مميزة',
    'باقــة بريميوم',
  ];

  void _updateAppState({
    AppTab? tab,
    PageType? page,
    Map<String, dynamic>? newPkg,
    Map<String, dynamic>? editPkg,
    Map<String, dynamic>? updatePkg,
    int? orderId,
    String? vendorId,
    int? packageId,
    int? networkId,
    String? merchantId,
    int? networkTabIndexValue,
  }) {
    setState(() {
      if (tab != null) activeTab = tab;
      if (page != null) currentPage = page;
      if (newPkg != null) newPackage = newPkg;
      if (editPkg != null) editingPackage = editPkg;
      if (updatePkg != null) updatedPackage = updatePkg;
      if (orderId != null) selectedOrderId = orderId;
      if (vendorId != null) selectedVendorId = vendorId;
      if (packageId != null) selectedPackageId = packageId;
      if (networkId != null) selectedNetworkId = networkId;
      if (merchantId != null) selectedMerchantId = merchantId;
      if (networkTabIndexValue != null) {
        final clamped = networkTabIndexValue < 0
            ? 0
            : networkTabIndexValue > 1
                ? 1
                : networkTabIndexValue;
        networkTabIndex = clamped;
      }
    });
  }

  void _resetAppState() {
    setState(() {
      currentPage = PageType.main;
      newPackage = null;
      editingPackage = null;
      updatedPackage = null;
      selectedOrderId = null;
      selectedVendorId = null;
      selectedPackageId = null;
      selectedNetworkId = null;
      selectedMerchantId = null;
      networkTabIndex = 0;
    });
  }

  // Package handlers
  void _handleAddPackage() {
    _updateAppState(page: PageType.addPackage);
  }

  void _handleEditPackage(Map<String, dynamic> packageData) {
    _updateAppState(
      editPkg: packageData,
      page: PageType.editPackage,
    );
  }

  // Convert Map from simple pages to Package model expected by EditPackagePage
  Package _mapToPackage(Map<String, dynamic> data) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return Package(
      id: data['id'], // يمكن أن يكون String أو int
      name: (data['name'] ?? '') as String,
      mikrotikName:
          (data['mikrotikName'] ?? data['mikrotik_name'] ?? '') as String,
      sellingPrice: toDouble(data['sellingPrice'] ?? data['price']),
      purchasePrice: toDouble(data['purchasePrice']),
      validityDays: toInt(data['validityDays']),
      usageHours: toInt(data['usageHours']),
      dataSizeGB: toInt(data['dataSizeGB']),
      dataSizeMB: toInt(data['dataSizeMB']),
      color: (data['color'] ?? 'blue') as String,
      stock: toInt(data['stock']),
    );
  }

  // Wrap EditPackagePage onSave (Package) -> existing handler (Map)
  void _handleUpdatePackageFromPage(Package updated) {
    final updatedMap = <String, dynamic>{
      'id': updated.id,
      'name': updated.name,
      'mikrotikName': updated.mikrotikName,
      'sellingPrice': updated.sellingPrice,
      'price': updated.sellingPrice,
      'purchasePrice': updated.purchasePrice,
      'validityDays': updated.validityDays,
      'usageHours': updated.usageHours,
      'dataSizeGB': updated.dataSizeGB,
      'dataSizeMB': updated.dataSizeMB,
      'color': updated.color,
      'stock': updated.stock,
    };
    _handleUpdatePackage(updatedMap);
  }

  void _handleSavePackage(Map<String, dynamic> packageData) {
    final candidateName =
        (packageData['packageName'] ?? packageData['name'])?.toString().trim();
    if (candidateName != null && candidateName.isNotEmpty) {
      setState(() {
        if (!_packageNames.contains(candidateName)) {
          _packageNames.add(candidateName);
        }
      });
    }
    _updateAppState(
      newPkg: packageData,
      page: PageType.main,
      tab: AppTab.network,
    );
    // Toast already shown in add_package_page
  }

  void _handleUpdatePackage(Map<String, dynamic> updatedPackageData) {
    final candidateName =
        (updatedPackageData['packageName'] ?? updatedPackageData['name'])
            ?.toString()
            .trim();
    if (candidateName != null && candidateName.isNotEmpty) {
      setState(() {
        if (!_packageNames.contains(candidateName)) {
          _packageNames.add(candidateName);
        }
      });
    }
    _updateAppState(
      updatePkg: updatedPackageData,
      page: PageType.main,
      tab: AppTab.network,
    );
    _updateAppState();
    // Toast already shown in edit_package_page
  }

  void _handleImportCards() {
    _updateAppState(page: PageType.importCards);
  }

  void _handleImportComplete(Map<String, dynamic> cardsData) {
    _updateAppState(
      page: PageType.main,
      tab: AppTab.network,
    );
  }

  // Order handlers
  void _handleViewOrderDetails(int orderId) {
    _updateAppState(
      orderId: orderId,
      page: PageType.orderDetails,
      networkTabIndexValue: 1,
    );
  }

  void _handleApproveOrder(int orderId) {
    // Toast already shown in network_page
  }

  void _handleRejectOrder(int orderId) {
    // Toast already shown in network_page
  }

  // Sale handlers
  void _handleStartSale(int packageId) {
    _updateAppState(
      packageId: packageId,
      page: PageType.saleProcess,
    );
  }

  void _handleRequestCards() {
    // كان يفتح صفحة طلب كروت (قيد التطوير). الآن نوجه مباشرة إلى صفحة إرسال الطلب الجديدة
    _updateAppState(page: PageType.sendOrder);
  }

  // Network handlers
  void _handleNetworkSelect(int networkId) {
    _updateAppState(
      networkId: networkId,
      page: PageType.networkDetails,
    );
  }

  void _handleSendOrder(int networkId) {
    _updateAppState(
      networkId: networkId,
      page: PageType.sendOrder,
    );
  }

  // Chat handlers
  void _handleOpenChatFromOrder(String vendorId) {
    _updateAppState(
      vendorId: vendorId,
      tab: AppTab.chat,
      page: PageType.main,
    );
  }

  void _handleOpenChatFromNetwork(int networkId) {
    _updateAppState(
      vendorId: networkId.toString(),
      tab: AppTab.chat,
      page: PageType.main,
    );
  }

  // Merchant handlers
  void _handleAddMerchant() {
    _updateAppState(tab: AppTab.accounts);
    // User will see the accounts page with search button
  }

  void _handleViewMerchantTransactions(String merchantId) {
    _updateAppState(
      merchantId: merchantId,
      page: PageType.merchantTransactions,
    );
  }

  // Navigation handlers
  void _handleBackToMain() {
    _resetAppState();
  }

  void _handleCashPaymentSubmit(
      VendorModel vendor, double amount, String note) {
    // Toast already shown in cash_payment_page
    // العودة للصفحة الرئيسية
    _handleBackToMain();
  }

  void _handleCashPaymentDecision(String requestId, {required bool accepted}) {
    // Toast already shown in respective page
  }

  void _handleBackToOrdersTab() {
    setState(() {
      selectedOrderId = null;
      currentPage = PageType.main;
      activeTab = AppTab.network;
      networkTabIndex = 1;
    });
  }

  void _handleBackToNetworks() {
    setState(() {
      selectedNetworkId = null;
    });
    _updateAppState(
      page: PageType.main,
      tab: AppTab.networks,
    );
  }

  void _handleRecordCashPayment() {
    _updateAppState(page: PageType.cashPaymentOwner);
  }

  void _handleVendorCashPayments() {
    _updateAppState(page: PageType.cashPaymentVendor);
  }

  void _handleTabChange(AppTab tab) {
    _updateAppState(tab: tab);
  }

  // Page rendering for network owners
  Widget? _renderNetworkOwnerPages() {
    return switch (currentPage) {
      PageType.addPackage => AddPackagePage(
          onBack: _handleBackToMain,
          onSave: _handleSavePackage,
        ),
      PageType.editPackage => editingPackage == null
          ? null
          : EditPackagePage(
              packageData: _mapToPackage(editingPackage!),
              onBack: _handleBackToMain,
              onSave: _handleUpdatePackageFromPage,
            ),
      PageType.importCards => ImportCardsPage(
          onBack: _handleBackToMain,
          onImportComplete: _handleImportComplete,
          packageNames: _packageNames,
        ),
      PageType.orderDetails => selectedOrderId == null
          ? null
          : OrderDetailsPage(
              orderId: selectedOrderId!,
              onBack: _handleBackToOrdersTab,
              onApprove: _handleApproveOrder,
              onReject: _handleRejectOrder,
              onOpenChat: _handleOpenChatFromOrder,
            ),
      PageType.merchantTransactions => selectedMerchantId == null
          ? null
          : MerchantTransactionsPage(
              vendorId: selectedMerchantId!,
              onBack: _handleBackToMain,
            ),
      PageType.cashPaymentOwner => NetworkCashPaymentPage(
          onBack: _handleBackToMain,
          onSubmit: _handleCashPaymentSubmit,
        ),
      // The remaining page types don't render owner overlays here
      PageType.main ||
      PageType.saleProcess ||
      PageType.networkDetails ||
      PageType.sendOrder ||
      PageType.requestCards ||
      PageType.cashPaymentVendor =>
        null,
    };
  }

  // Page rendering for POS vendors
  Widget? _renderPosVendorPages() {
    return switch (currentPage) {
      PageType.saleProcess => SaleProcessPage(
          onBack: _handleBackToMain,
        ),
      PageType.networkDetails => selectedNetworkId == null
          ? null
          : NetworkDetailsPage(
              networkId: selectedNetworkId!,
              onBack: _handleBackToNetworks,
              onSendOrder: _handleSendOrder,
              onOpenChat: _handleOpenChatFromNetwork,
            ),
      PageType.sendOrder => selectedNetworkId == null
          // لا يمكن فتح صفحة إرسال الطلب بدون شبكة محددة
          ? null
          : SendOrderPage(
              networkId: selectedNetworkId!.toString(),
              networkName: 'الشبكة المحددة', // يمكن تحسين هذا لاحقاً
            ),
      PageType.requestCards => const RequestCardsPage(),
      PageType.cashPaymentVendor => PosVendorCashPaymentsPage(
          onBack: _handleBackToMain,
          onDecision: _handleCashPaymentDecision,
        ),
      // Remaining page types not rendered in vendor overlay context
      PageType.main ||
      PageType.addPackage ||
      PageType.editPackage ||
      PageType.importCards ||
      PageType.orderDetails ||
      PageType.merchantTransactions ||
      PageType.cashPaymentOwner =>
        null,
    };
  }

  // Main content rendering
  Widget _renderMainContent() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user?.type == UserType.networkOwner) {
      return switch (activeTab) {
        AppTab.home => NetworkOwnerHomePage(
            onViewOrderDetails: _handleViewOrderDetails,
            onAddPackage: _handleAddPackage,
            onImportCards: _handleImportCards,
            onAddMerchant: _handleAddMerchant,
            onRecordCashPayment: _handleRecordCashPayment,
          ),
        AppTab.network => NetworkPage(
            onAddPackage: _handleAddPackage,
            onEditPackage: _handleEditPackage,
            onImportCards: _handleImportCards,
            onViewOrderDetails: _handleViewOrderDetails,
            onApproveOrder: _handleApproveOrder,
            onRejectOrder: _handleRejectOrder,
            newPackage: newPackage,
            updatedPackage: updatedPackage,
            initialTabIndex: networkTabIndex,
          ),
        AppTab.accounts => AccountsPage(
            onViewMerchantTransactions: _handleViewMerchantTransactions,
          ),
        AppTab.chat => ChatPage(chatId: selectedVendorId),
        AppTab.profile => const ProfilePage(),
        // AppTab.networks not used for networkOwner role
        AppTab.networks => NetworkOwnerHomePage(
            onViewOrderDetails: _handleViewOrderDetails,
            onAddPackage: _handleAddPackage,
            onImportCards: _handleImportCards,
            onAddMerchant: _handleAddMerchant,
          ),
      };
    } else {
      return switch (activeTab) {
        AppTab.home => PosVendorHomePage(
            onStartSale: _handleStartSale,
            onRequestCards: _handleRequestCards,
            onRecordCashPayment: _handleVendorCashPayments,
          ),
        AppTab.networks => NetworksPage(
            onNetworkSelect: _handleNetworkSelect,
          ),
        AppTab.chat => const ChatPage(),
        AppTab.profile => const ProfilePage(),
        // Tabs not used for vendor fall back to home
        AppTab.network || AppTab.accounts => PosVendorHomePage(
            onStartSale: _handleStartSale,
            onRequestCards: _handleRequestCards,
            onRecordCashPayment: _handleVendorCashPayments,
          ),
      };
    }
  }

  Widget _renderContent() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Render specific pages for each user type
    if (currentPage != PageType.main) {
      if (authProvider.user?.type == UserType.networkOwner) {
        final networkOwnerPage = _renderNetworkOwnerPages();
        if (networkOwnerPage != null) return networkOwnerPage;
      } else if (authProvider.user?.type == UserType.posVendor) {
        final posVendorPage = _renderPosVendorPages();
        if (posVendorPage != null) return posVendorPage;
      }
    }

    // Render main content
    return _renderMainContent();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }

        final shouldShowBottomNav = currentPage == PageType.main;

        // منع الرجوع لصفحة تسجيل الدخول عند الضغط على زر العودة
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            // إذا كان في صفحة فرعية، ارجع للصفحة الرئيسية
            if (currentPage != PageType.main) {
              _handleBackToMain();
            }
            // إذا كان في الصفحة الرئيسية، لا تفعل شيء (لا ترجع لصفحة تسجيل الدخول)
          },
          child: Scaffold(
            body: _renderContent(),
            bottomNavigationBar: shouldShowBottomNav
                ? AppBottomNavigation(
                    activeTab: activeTab,
                    onTabChange: _handleTabChange,
                  )
                : null,
          ),
        );
      },
    );
  }
}
