import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import '../providers/auth_provider.dart';

class AdminDrawer extends StatelessWidget {
  final UserModel? user;
  final AdminAuthProvider? auth;
  const AdminDrawer({super.key, this.user, this.auth});

  @override
  Widget build(BuildContext context) {
    final authProvider = auth ?? Provider.of<AdminAuthProvider>(context);
    final currentUser = user ?? authProvider.user;

    String currentRoute = '';
    try {
      currentRoute = GoRouterState.of(context).matchedLocation;
    } catch (_) {}

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          if (currentUser != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentUser.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(currentUser.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: const Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ]),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _sectionHeader('OVERVIEW'),
                _DI(Icons.dashboard_rounded, 'Dashboard', '/', currentRoute, () { Navigator.pop(context); context.go('/dashboard'); }),
                _DI(Icons.bar_chart_rounded, 'Analytics & Reports', '/management/analytics', currentRoute, () { Navigator.pop(context); context.push('/management/analytics'); }),

                _sectionHeader('STORE & PRODUCTS'),
                _DI(Icons.inventory_2_rounded, 'Products', '/management/products', currentRoute, () { Navigator.pop(context); context.push('/management/products'); }),
                _DI(Icons.category_rounded, 'Categories', '/management/categories', currentRoute, () { Navigator.pop(context); context.push('/management/categories'); }),
                _DI(Icons.store_rounded, 'Dealers & Vendors', '/management/dealers', currentRoute, () { Navigator.pop(context); context.push('/management/dealers'); }),
                _DI(Icons.image_rounded, 'Banners', '/management/banners', currentRoute, () { Navigator.pop(context); context.push('/management/banners'); }),
                _DI(Icons.local_offer_rounded, 'Coupons', '/management/coupons', currentRoute, () { Navigator.pop(context); context.push('/management/coupons'); }),
                _DI(Icons.flash_on_rounded, 'Flash Sales', '/management/flash-sales', currentRoute, () { Navigator.pop(context); context.push('/management/flash-sales'); }),

                _sectionHeader('ORDERS & CUSTOMERS'),
                _DI(Icons.chat_rounded, 'Customer Support Chat', '/management/chats', currentRoute, () { Navigator.pop(context); context.push('/management/chats'); }),
                _DI(Icons.receipt_long_rounded, 'Orders', '/management/orders', currentRoute, () { Navigator.pop(context); context.push('/management/orders'); }),
                _DI(Icons.people_rounded, 'Users & Roles', '/management/users', currentRoute, () { Navigator.pop(context); context.push('/management/users'); }),
                _DI(Icons.rate_review_rounded, 'Reviews', '/management/reviews', currentRoute, () { Navigator.pop(context); context.push('/management/reviews'); }),
                _DI(Icons.payments_rounded, 'Payout Requests', '/management/payout-requests', currentRoute, () { Navigator.pop(context); context.push('/management/payout-requests'); }),

                _sectionHeader('FINANCE & LOGISTICS'),
                _DI(Icons.monetization_on_rounded, 'Partner & Dealer Earnings', '/management/partner-earnings', currentRoute, () { Navigator.pop(context); context.push('/management/partner-earnings'); }),
                _DI(Icons.money_off_rounded, 'Refunds', '/management/refunds', currentRoute, () { Navigator.pop(context); context.push('/management/refunds'); }),
                _DI(Icons.account_balance_wallet_rounded, 'Wallets', '/management/wallets', currentRoute, () { Navigator.pop(context); context.push('/management/wallets'); }),
                _DI(Icons.account_balance_rounded, 'Payments', '/management/payments', currentRoute, () { Navigator.pop(context); context.push('/management/payments'); }),
                _DI(Icons.local_shipping_rounded, 'Delivery Rates', '/management/delivery-settings', currentRoute, () { Navigator.pop(context); context.push('/management/delivery-settings'); }),

                _sectionHeader('SYSTEM & SETTINGS'),
                _DI(Icons.campaign_rounded, 'Notifications', '/management/notifications', currentRoute, () { Navigator.pop(context); context.push('/management/notifications'); }),
                _DI(Icons.settings_rounded, 'Settings Hub', '/management/settings', currentRoute, () { Navigator.pop(context); context.push('/management/settings'); }),
                _DI(Icons.tune_rounded, 'Platform Settings', '/management/platform-settings', currentRoute, () { Navigator.pop(context); context.push('/management/platform-settings'); }),
                _DI(Icons.person_rounded, 'My Profile', '/profile', currentRoute, () { Navigator.pop(context); context.push('/profile'); }),

                const Divider(height: 24, indent: 16, endIndent: 16),
                _DI(Icons.logout_rounded, 'Sign Out', '/logout', currentRoute, () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () { Navigator.pop(ctx); authProvider.logout(); },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white), child: const Text('Sign Out')),
                    ],
                  ));
                }, color: const Color(0xFFEF4444)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('GroceryGo Admin v1.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
      ),
    );
  }
}

class _DI extends StatelessWidget {
  final IconData icon;
  final String title;
  final String routePath;
  final String currentRoute;
  final VoidCallback onTap;
  final Color? color;

  const _DI(this.icon, this.title, this.routePath, this.currentRoute, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final isActive = routePath == '/'
        ? (currentRoute == '/' || currentRoute == '/dashboard' || currentRoute.isEmpty)
        : currentRoute.startsWith(routePath);

    final activeColor = color ?? const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  width: 4,
                  height: 18,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : (color ?? const Color(0xFF64748B)),
              ),
            ],
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: isActive ? activeColor : (color ?? const Color(0xFF0F172A)),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }
}
