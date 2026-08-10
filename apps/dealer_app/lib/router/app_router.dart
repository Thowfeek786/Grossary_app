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
import '../screens/splash/splash_screen.dart';

class AppRouter {
  static GoRouter router(DealerAuthProvider auth) {
    return GoRouter(
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
          builder: (_, __) => const DealerSplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const DealerOnboardingScreen(),
        ),
        GoRoute(
          path: '/delivery-settings',
          builder: (_, __) => const DealerDeliverySettingsScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const DealerSignupScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DealerDashboard(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (_, __) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/add-product',
          builder: (context, state) => AddProductScreen(product: state.extra as ProductModel?),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const DealerOrdersScreen(),
        ),
        GoRoute(
          path: '/order/:orderId',
          builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['orderId']!),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    );
  }
}
