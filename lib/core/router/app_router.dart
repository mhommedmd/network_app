import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Feature pages (auth, home)
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/main_layout.dart';
import '../../features/pos_vendor/data/models/network_connection_model.dart';
import '../../features/pos_vendor/presentation/pages/sale_process_page.dart';
import '../../features/pos_vendor/presentation/pages/send_order_page.dart';
// Core / providers
import '../providers/auth_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;

      // قائمة الصفحات المسموح بها بدون تسجيل دخول
      final publicRoutes = ['/login', '/register', '/forgot-password'];

      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && !publicRoutes.contains(state.matchedLocation)) {
        return '/login';
      }

      // If authenticated and trying to access auth routes
      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/forgot-password')) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) {
          final initialPhone = state.extra is Map
              ? (state.extra! as Map)['phone'] as String?
              : null;
          return ForgotPasswordPage(initialPhone: initialPhone);
        },
      ),

      // Main Layout Route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/sale-process',
        name: 'sale-process',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is Map) {
            // للبيع السريع من الباقة مباشرة
            final preselectedNetwork =
                extra['preselectedNetwork'] as NetworkConnectionModel?;
            final preselectedPackageId =
                extra['preselectedPackageId'] as String?;

            if (preselectedNetwork != null) {
              return SaleProcessPage(
                preselectedNetwork: preselectedNetwork,
                preselectedPackageId: preselectedPackageId,
              );
            }

            // الطريقة القديمة (للتوافق)
            final initialNetwork = extra['network'] as String?;
            final initialPackage = extra['package'] as String?;

            return SaleProcessPage(
              initialNetwork: initialNetwork,
              initialPackageName: initialPackage,
            );
          }

          return const SaleProcessPage();
        },
      ),
      GoRoute(
        path: '/send-order',
        name: 'send-order',
        builder: (context, state) {
          // Support both GoRouter extras and Navigator arguments
          String? networkId;
          String? networkName;
          final extra = state.extra;
          if (extra is Map) {
            networkId = extra['networkId'] as String?;
            networkName = extra['networkName'] as String?;
          }
          return SendOrderPage(
            networkId: networkId,
            networkName: networkName,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}
