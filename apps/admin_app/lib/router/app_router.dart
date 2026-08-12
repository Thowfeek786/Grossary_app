import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/management/products_management_screen.dart';
import '../screens/management/category_management_screen.dart';
import '../screens/management/order_management_screen.dart';
import '../screens/management/admin_order_detail_screen.dart';
import '../screens/management/user_management_screen.dart';
import '../screens/management/add_user_screen.dart';
import '../screens/management/banner_management_screen.dart';
import '../screens/management/dealer_management_screen.dart';
import '../screens/management/notification_management_screen.dart';
import '../screens/management/delivery_settings_screen.dart';
import '../screens/management/analytics_screen.dart';
import '../screens/management/coupon_management_screen.dart';
import '../screens/management/review_management_screen.dart';
import '../screens/management/refund_management_screen.dart';
import '../screens/management/wallet_management_screen.dart';
import '../screens/management/payment_management_screen.dart';
import '../screens/management/platform_settings_screen.dart';
import '../screens/management/flash_sale_management_screen.dart';
import '../screens/management/payout_requests_screen.dart';
import '../screens/management/settings_hub_screen.dart';
import '../screens/management/chat_management_screen.dart';
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
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/management/orders',
          builder: (_, _) => const OrderManagementScreen(),
          routes: [
            GoRoute(
              path: ':orderId',
              builder: (context, state) => AdminOrderDetailScreen(
                orderId: state.pathParameters['orderId'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/management/users',
          builder: (_, _) => const UserManagementScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => const AddUserScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/management/settings',
          builder: (_, _) => const SettingsHubScreen(),
        ),
        GoRoute(
          path: '/management/delivery-settings',
          builder: (_, _) => const AdminDeliverySettingsScreen(),
        ),
        GoRoute(
          path: '/management/products',
          builder: (_, _) => const ProductsManagementScreen(),
        ),
        GoRoute(
          path: '/management/categories',
          builder: (_, _) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: '/management/banners',
          builder: (_, _) => const BannerManagementScreen(),
        ),
        GoRoute(
          path: '/management/dealers',
          builder: (_, _) => const DealerManagementScreen(),
        ),
        GoRoute(
          path: '/management/notifications',
          builder: (_, _) => const NotificationManagementScreen(),
        ),
        GoRoute(
          path: '/management/analytics',
          builder: (_, _) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/management/coupons',
          builder: (_, _) => const CouponManagementScreen(),
        ),
        GoRoute(
          path: '/management/reviews',
          builder: (_, _) => const ReviewManagementScreen(),
        ),
        GoRoute(
          path: '/management/refunds',
          builder: (_, _) => const RefundManagementScreen(),
        ),
        GoRoute(
          path: '/management/wallets',
          builder: (_, _) => const WalletManagementScreen(),
        ),
        GoRoute(
          path: '/management/payments',
          builder: (_, _) => const PaymentManagementScreen(),
        ),
        GoRoute(
          path: '/management/platform-settings',
          builder: (_, _) => const PlatformSettingsScreen(),
        ),
        GoRoute(
          path: '/management/flash-sales',
          builder: (_, _) => const FlashSaleManagementScreen(),
        ),
        GoRoute(
          path: '/management/flash-sale',
          builder: (_, _) => const FlashSaleManagementScreen(),
        ),
        GoRoute(
          path: '/management/payout-requests',
          builder: (_, _) => const PayoutRequestsScreen(),
        ),
        GoRoute(
          path: '/management/chats',
          builder: (_, _) => const ChatManagementScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const AdminProfileScreen(),
        ),
      ],
    );
  }
}
