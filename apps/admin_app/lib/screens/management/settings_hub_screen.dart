import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_drawer.dart';

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_rounded, size: 20, color: Colors.white),
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Platform Control Center',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const Text('Settings & Configuration',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('Settings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Store Operations
                _SectionHeader(title: 'Store Operations', icon: Icons.storefront_rounded, color: const Color(0xFF6366F1)),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.local_shipping_rounded,
                  title: 'Delivery Rates & Surge Fee',
                  subtitle: 'Configure base fees, surge engine, free thresholds',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/management/delivery-settings'),
                ),
                _SettingsTile(
                  icon: Icons.radar_rounded,
                  title: 'Store Zones & Geofencing',
                  subtitle: 'Manage dark store GPS pins & coverage boundaries',
                  color: const Color(0xFF059669),
                  onTap: () => context.push('/management/store-geofence'),
                ),
                _SettingsTile(
                  icon: Icons.water_drop_rounded,
                  title: 'Water Subscriptions Hub',
                  subtitle: 'Platform-wide subscriber directories, MRR & runs',
                  color: const Color(0xFF0D9488),
                  onTap: () => context.push('/management/water-subscribers'),
                ),
                _SettingsTile(
                  icon: Icons.celebration_rounded,
                  title: 'Homepage Banners',
                  subtitle: 'Manage promotional carousel banners',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.push('/management/banners'),
                ),
                _SettingsTile(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Flash Sale Timer',
                  subtitle: 'Configure live deal countdown & products',
                  color: const Color(0xFFEF4444),
                  onTap: () => context.push('/management/flash-sale'),
                ),

                const SizedBox(height: 24),

                // Finance & Payments
                _SectionHeader(title: 'Finance & Payments', icon: Icons.account_balance_rounded, color: const Color(0xFF10B981)),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.confirmation_num_rounded,
                  title: 'Coupons & Discounts',
                  subtitle: 'Create and manage promo codes',
                  color: const Color(0xFFEF4444),
                  onTap: () => context.push('/management/coupons'),
                ),
                _SettingsTile(
                  icon: Icons.payments_rounded,
                  title: 'Payment Transactions',
                  subtitle: 'Transaction history & gateway config',
                  color: const Color(0xFF0284C7),
                  onTap: () => context.push('/management/payments'),
                ),
                _SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'User Wallets',
                  subtitle: 'View balances & add credits',
                  color: const Color(0xFF84CC16),
                  onTap: () => context.push('/management/wallets'),
                ),
                _SettingsTile(
                  icon: Icons.money_off_rounded,
                  title: 'Refund Requests',
                  subtitle: 'Process and approve customer refunds',
                  color: const Color(0xFFEAB308),
                  onTap: () => context.push('/management/refunds'),
                ),
                _SettingsTile(
                  icon: Icons.payments_rounded,
                  title: 'Partner Payouts',
                  subtitle: 'Approve manual partner withdrawals',
                  color: const Color(0xFF059669),
                  onTap: () => context.push('/management/payout-requests'),
                ),

                const SizedBox(height: 24),

                // Communication
                _SectionHeader(title: 'Communication', icon: Icons.campaign_rounded, color: const Color(0xFFEC4899)),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.chat_rounded,
                  title: 'Customer Queries & Chat',
                  subtitle: 'Live support & user query management',
                  color: const Color(0xFF6366F1),
                  onTap: () => context.push('/management/chats'),
                ),
                _SettingsTile(
                  icon: Icons.campaign_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Send broadcast alerts to all apps',
                  color: const Color(0xFFEC4899),
                  onTap: () => context.push('/management/notifications'),
                ),
                _SettingsTile(
                  icon: Icons.rate_review_rounded,
                  title: 'Product Reviews',
                  subtitle: 'Moderate and manage customer reviews',
                  color: const Color(0xFFF97316),
                  onTap: () => context.push('/management/reviews'),
                ),

                const SizedBox(height: 24),

                // Platform
                _SectionHeader(title: 'Platform Configuration', icon: Icons.settings_rounded, color: const Color(0xFF64748B)),
                const SizedBox(height: 10),
                _SettingsTile(
                  icon: Icons.toggle_on_rounded,
                  title: 'Feature Flags & Module Controls',
                  subtitle: 'Live kill-switches for rewards, voice search, POS & water cans',
                  color: const Color(0xFF6366F1),
                  onTap: () => context.push('/management/feature-flags'),
                ),
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'Platform Settings',
                  subtitle: 'Global contacts, bank details, ToS & privacy',
                  color: const Color(0xFF64748B),
                  onTap: () => context.push('/management/platform-settings'),
                ),
                _SettingsTile(
                  icon: Icons.water_drop_rounded,
                  title: 'Water Can & Deposit Management',
                  subtitle: 'Configure can deposits, exchange rates & audit ledger',
                  color: const Color(0xFF059669),
                  onTap: () => context.push('/management/water-cans'),
                ),
                _SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Analytics & Insights',
                  subtitle: 'Revenue charts, trends & top products',
                  color: const Color(0xFF14B8A6),
                  onTap: () => context.push('/management/analytics'),
                ),
                _SettingsTile(
                  icon: Icons.person_rounded,
                  title: 'Admin Profile',
                  subtitle: 'Your profile, password & account settings',
                  color: const Color(0xFF6366F1),
                  onTap: () => context.push('/profile'),
                ),

                const SizedBox(height: 20),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, auth),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Text('GroceryGo Admin v1.0',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AdminAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        content: const Text('Are you sure you want to sign out of the admin panel?',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
          subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }
}
