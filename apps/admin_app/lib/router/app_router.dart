import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/management/products_management_screen.dart';
import '../screens/management/category_management_screen.dart';
import '../screens/management/order_management_screen.dart';
import '../screens/management/user_management_screen.dart';
import '../screens/management/add_user_screen.dart';
import '../screens/management/banner_management_screen.dart';
import '../screens/management/dealer_management_screen.dart';
import '../screens/management/notification_management_screen.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  static GoRouter router(AdminAuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/dashboard',
      redirect: (context, state) {
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;
        final isAuthRoute = state.matchedLocation == '/login';

        if (isUnknown) return null;
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/management/products',
          builder: (_, __) => const ProductsManagementScreen(),
        ),
        GoRoute(
          path: '/management/categories',
          builder: (_, __) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: '/management/orders',
          builder: (_, __) => const OrderManagementScreen(),
        ),
        GoRoute(
          path: '/management/users',
          builder: (_, __) => const UserManagementScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, __) => const AddUserScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/management/banners',
          builder: (_, __) => const BannerManagementScreen(),
        ),
        GoRoute(
          path: '/management/dealers',
          builder: (_, __) => const DealerManagementScreen(),
        ),
        GoRoute(
          path: '/management/notifications',
          builder: (_, __) => const NotificationManagementScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const AdminProfileScreen(),
        ),
      ],
    );
  }
}
