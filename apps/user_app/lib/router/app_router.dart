import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/product_detail_screen.dart';
import '../screens/home/category_products_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_success_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/address_list_screen.dart';
import '../screens/profile/add_address_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/help_support_screen.dart';
import '../screens/profile/about_us_screen.dart';
import '../screens/profile/wallet_screen.dart';
import '../screens/profile/support_chat_screen.dart';
import '../screens/orders/review_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/home/categories_screen.dart';
import '../screens/home/product_reviews_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/profile/terms_conditions_screen.dart';
import '../screens/profile/favorites_screen.dart';
import '../screens/water/water_can_screen.dart';
import '../screens/profile/my_cans_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider auth) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;
        final isSplash = state.matchedLocation == '/splash';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isTerms = state.matchedLocation == '/terms';
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password' ||
            isTerms;

        if (isSplash || isOnboarding || isUnknown || isTerms) return null;
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute && !isTerms) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildFadeTransitionPage(
            const SplashScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/onboarding',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const UserOnboardingScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/terms',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const TermsConditionsScreen(),
            state,
          ),
        ),
        // Auth routes
        GoRoute(
          path: '/login',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const LoginScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/register',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const RegisterScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const ForgotPasswordScreen(),
            state,
          ),
        ),

        // Full-screen standalone routes
        GoRoute(
          path: '/home/category/:id',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            CategoryProductsScreen(
              categoryId: state.pathParameters['id']!,
              categoryName: state.uri.queryParameters['name'] ?? '',
            ),
            state,
          ),
        ),
        GoRoute(
          path: '/home/search',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const SearchScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/home/product/:id',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            ProductDetailScreen(productId: state.pathParameters['id']!),
            state,
          ),
        ),
        GoRoute(
          path: '/product-reviews',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            ProductReviewsScreen(product: state.extra as ProductModel),
            state,
          ),
        ),
        GoRoute(
          path: '/checkout',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const CheckoutScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/order-success/:id',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            OrderSuccessScreen(orderId: state.pathParameters['id']!),
            state,
          ),
        ),
        GoRoute(
          path: '/orders/review',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            ReviewScreen(item: state.extra as CartItemModel),
            state,
          ),
        ),
        GoRoute(
          path: '/orders/:id',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            OrderDetailScreen(orderId: state.pathParameters['id']!),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/wallet',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const WalletScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/favorites',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const FavoritesScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/edit',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const EditProfileScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/addresses',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const AddressListScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/add-address',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const AddAddressScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/notifications',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const NotificationsScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/help',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const HelpSupportScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/support-chat',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const SupportChatScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/about',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const AboutUsScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const ProfileScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/water-cans',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const WaterCanScreen(),
            state,
          ),
        ),
        GoRoute(
          path: '/profile/my-cans',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (_, state) => _buildSlideTransitionPage(
            const MyCansScreen(),
            state,
          ),
        ),

        // Shell route for persistent bottom nav tabs
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => _buildTabTransitionPage(
                const HomeScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/categories',
              pageBuilder: (context, state) => _buildTabTransitionPage(
                const CategoriesScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/cart',
              pageBuilder: (context, state) => _buildTabTransitionPage(
                const CartScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/orders',
              pageBuilder: (context, state) => _buildTabTransitionPage(
                const OrdersScreen(),
                state,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Page<dynamic> _buildSlideTransitionPage(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Page<dynamic> _buildFadeTransitionPage(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  static Page<dynamic> _buildTabTransitionPage(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
