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

class AppRouter {
  static GoRouter? _router;

  static GoRouter router(AuthProvider auth) {
    _router ??= GoRouter(
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;
        final isSplash = state.matchedLocation == '/splash';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isTerms = state.matchedLocation == '/terms';
        final isAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register') ||
            state.matchedLocation.startsWith('/forgot-password') ||
            isTerms;

        if (isSplash || isOnboarding || isUnknown || isTerms) return null;
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute && !isTerms) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, _) => const UserOnboardingScreen()),
        GoRoute(path: '/terms', builder: (_, _) => const TermsConditionsScreen()),
        // Auth routes
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),

        // Main shell with bottom nav (Top-Level Tabs only)
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomeScreen(),
            ),
            GoRoute(
              path: '/categories',
              builder: (_, _) => const CategoriesScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (_, _) => const OrdersScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),

        // Standalone Full-Screen Routes (No Shell / No Bottom Nav)
        GoRoute(
          path: '/home/category/:id',
          builder: (_, state) => CategoryProductsScreen(
            categoryId: state.pathParameters['id']!,
            categoryName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
        GoRoute(path: '/home/search', builder: (_, _) => const SearchScreen()),
        GoRoute(path: '/profile/wallet', builder: (_, _) => const WalletScreen()),
        GoRoute(path: '/profile/favorites', builder: (_, _) => const FavoritesScreen()),
        GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
        GoRoute(path: '/profile/addresses', builder: (_, _) => const AddressListScreen()),
        GoRoute(path: '/profile/add-address', builder: (_, _) => const AddAddressScreen()),
        GoRoute(path: '/profile/notifications', builder: (_, _) => const NotificationsScreen()),
        GoRoute(path: '/profile/help', builder: (_, _) => const HelpSupportScreen()),
        GoRoute(path: '/profile/support-chat', builder: (_, _) => const SupportChatScreen()),
        GoRoute(path: '/profile/about', builder: (_, _) => const AboutUsScreen()),

        GoRoute(
          path: '/home/product/:id',
          builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'reviews',
              builder: (_, state) => ProductReviewsScreen(product: state.extra as ProductModel),
            ),
          ],
        ),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(
          path: '/order-success/:id',
          builder: (_, state) =>
              OrderSuccessScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/orders/review',
          builder: (_, state) => ReviewScreen(item: state.extra as CartItemModel),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ],
    );
    return _router!;
  }
}
