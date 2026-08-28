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
import '../screens/management/partner_earnings_screen.dart';
import '../screens/management/water_can_management_screen.dart';
import '../screens/management/water_can_ledger_screen.dart';
import '../screens/management/store_geofence_screen.dart';
import '../screens/management/feature_flags_screen.dart';
import '../screens/management/water_subscribers_hub_screen.dart';
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
          path: '/management/orders',
          builder: (_, __) => const OrderManagementScreen(),
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
          builder: (_, __) => const UserManagementScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, __) => const AddUserScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/management/settings',
          builder: (_, __) => const SettingsHubScreen(),
        ),
        GoRoute(
          path: '/management/delivery-settings',
          builder: (_, __) => const AdminDeliverySettingsScreen(),
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
          path: '/management/analytics',
          builder: (_, __) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/management/coupons',
          builder: (_, __) => const CouponManagementScreen(),
        ),
        GoRoute(
          path: '/management/reviews',
          builder: (_, __) => const ReviewManagementScreen(),
        ),
        GoRoute(
          path: '/management/refunds',
          builder: (_, __) => const RefundManagementScreen(),
        ),
        GoRoute(
          path: '/management/wallets',
          builder: (_, __) => const WalletManagementScreen(),
        ),
        GoRoute(
          path: '/management/payments',
          builder: (_, __) => const PaymentManagementScreen(),
        ),
        GoRoute(
          path: '/management/platform-settings',
          builder: (_, __) => const PlatformSettingsScreen(),
        ),
        GoRoute(
          path: '/management/flash-sales',
          builder: (_, __) => const FlashSaleManagementScreen(),
        ),
        GoRoute(
          path: '/management/flash-sale',
          builder: (_, __) => const FlashSaleManagementScreen(),
        ),
        GoRoute(
          path: '/management/payout-requests',
          builder: (_, __) => const PayoutRequestsScreen(),
        ),
        GoRoute(
          path: '/management/chats',
          builder: (_, __) => const ChatManagementScreen(),
        ),
        GoRoute(
          path: '/management/partner-earnings',
          builder: (_, __) => const PartnerEarningsScreen(),
        ),
        GoRoute(
          path: '/management/water-cans',
          builder: (_, __) => const WaterCanManagementScreen(),
        ),
        GoRoute(
          path: '/management/water-cans/ledger',
          builder: (_, __) => const WaterCanLedgerScreen(),
        ),
        GoRoute(
          path: '/management/store-geofence',
          builder: (_, __) => const StoreGeofenceScreen(),
        ),
        GoRoute(
          path: '/management/feature-flags',
          builder: (_, __) => const FeatureFlagsScreen(),
        ),
        GoRoute(
          path: '/management/water-subscribers',
          builder: (_, __) => const WaterSubscribersHubScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const AdminProfileScreen(),
        ),
      ],
    );
  }
}
