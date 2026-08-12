import 'package:delivery_app/screens/terms_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../screens/vehicle_documents_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter? _router;

  static GoRouter router(DeliveryAuthProvider auth) {
    _router ??= GoRouter(
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
          builder: (_, _) => const DeliverySplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const DeliveryOnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, _) => const SignupScreen(),
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
          builder: (_, _) => const BankDetailsScreen(),
        ),
        GoRoute(
          path: '/earnings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const EarningHistoryScreen(),
        ),
        GoRoute(
          path: '/support',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: '/withdraw',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const WithdrawFundsScreen(),
        ),
        GoRoute(
          path: '/vehicle-documents',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const VehicleDocumentsScreen(),
        ),
        GoRoute(
          path: '/terms',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const TermsServiceScreen(),
        ),

        // Shell route for persistent bottom nav
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DeliveryDashboard(),
            ),
            GoRoute(
              path: '/active-deliveries',
              builder: (_, _) => const ActiveDeliveriesScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (_, _) => const HistoryScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
    return _router!;
  }
}
