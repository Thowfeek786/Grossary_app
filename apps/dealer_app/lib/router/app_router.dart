import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/delivery_settings_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dealer_payout_screen.dart';
import '../screens/total_sales_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/main_shell.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(DealerAuthProvider auth) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;
        final isSplash = state.matchedLocation == '/splash';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

        if (isSplash || isOnboarding || isUnknown) return null;
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const DealerSplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const DealerOnboardingScreen(),
        ),
        GoRoute(
          path: '/delivery-settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const DealerDeliverySettingsScreen(),
        ),
        GoRoute(
          path: '/dealer-payouts',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const DealerPayoutScreen(),
        ),
        GoRoute(
          path: '/total-sales',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const TotalSalesScreen(),
        ),
        GoRoute(
          path: '/help-support',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const DealerHelpSupportScreen(),
        ),
        GoRoute(
          path: '/login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const DealerSignupScreen(),
        ),
        GoRoute(
          path: '/add-product',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => AddProductScreen(product: state.extra as ProductModel?),
        ),
        GoRoute(
          path: '/order/:orderId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['orderId']!),
        ),

        // Shell route for persistent bottom nav
        ShellRoute(
          builder: (context, state, child) => DealerMainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DealerDashboard(),
            ),
            GoRoute(
              path: '/inventory',
              builder: (_, __) => const InventoryScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (_, __) => const DealerOrdersScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
