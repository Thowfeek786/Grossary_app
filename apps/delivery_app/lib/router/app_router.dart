import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/active_deliveries_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/main_shell.dart';
import '../screens/bank_details_screen.dart';
import '../screens/earnings_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/withdraw_funds_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter? _router;

  static GoRouter router(DeliveryAuthProvider auth) {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: auth,
      initialLocation: '/dashboard',
      redirect: (context, state) {
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

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
          path: '/signup',
          builder: (_, __) => const SignupScreen(),
        ),
        
        // Full-screen routes (outside ShellRoute to hide bottom nav)
        GoRoute(
          path: '/order-detail/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/bank-details',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const BankDetailsScreen(),
        ),
        GoRoute(
          path: '/earnings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const EarningHistoryScreen(),
        ),
        GoRoute(
          path: '/support',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: '/withdraw',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const WithdrawFundsScreen(),
        ),

        // Shell route for persistent bottom nav
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DeliveryDashboard(),
            ),
            GoRoute(
              path: '/active-deliveries',
              builder: (_, __) => const ActiveDeliveriesScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (_, __) => const HistoryScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
    return _router!;
  }
}
