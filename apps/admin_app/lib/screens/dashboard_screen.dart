import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';
import '../providers/management_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final management = context.watch<AdminManagementProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}, context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin profile banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Master Admin',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(user.name,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(user.email,
                              style:
                                  const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Platform Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              // Real stats
              FutureBuilder<Map<String, String>>(
                future: management.getDashboardStats(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {
                    'Total Users': '...',
                    'Active Orders': '...',
                    'Total Revenue': '...',
                    'Products': '...',
                  };
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        title: 'Total Users',
                        value: stats['Total Users'] ?? '-',
                        icon: Icons.people_rounded,
                        onTap: () => context.push('/management/users'),
                      ),
                      StatCard(
                        title: "Today's Orders",
                        value: stats['Active Orders'] ?? '-',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.warning,
                        onTap: () => context.push('/management/orders'),
                      ),
                      StatCard(
                        title: 'Total Revenue',
                        value: stats['Total Revenue'] ?? '-',
                        icon: Icons.attach_money_rounded,
                        color: AppColors.success,
                      ),
                      StatCard(
                        title: 'Products',
                        value: stats['Products'] ?? '-',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.info,
                        onTap: () => context.push('/management/products'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Management Modules',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _ModuleTile(
                  title: 'Products Management',
                  subtitle: 'Add, edit, or remove products',
                  icon: Icons.inventory_2_rounded,
                  onTap: () => context.push('/management/products')),
              _ModuleTile(
                  title: 'Category Management',
                  subtitle: 'Organize product categories',
                  icon: Icons.category_rounded,
                  onTap: () => context.push('/management/categories')),
              _ModuleTile(
                  title: 'Order Management',
                  subtitle: 'Track and update order statuses',
                  icon: Icons.local_shipping_rounded,
                  onTap: () => context.push('/management/orders')),
              _ModuleTile(
                  title: 'Users & Roles',
                  subtitle: 'Manage users and permissions',
                  icon: Icons.manage_accounts_rounded,
                  onTap: () => context.push('/management/users')),
              _ModuleTile(
                  title: 'Banners & Promos',
                  subtitle: 'Control homepage banners',
                  icon: Icons.celebration_rounded,
                  onTap: () => context.push('/management/banners')),
              _ModuleTile(
                  title: 'Dealers & Vendors',
                  subtitle: 'Approve and manage dealers',
                  icon: Icons.storefront_rounded,
                  onTap: () => context.push('/management/dealers')),
              _ModuleTile(
                  title: 'Broadcast Notifications',
                  subtitle: 'Send push alerts to apps',
                  icon: Icons.campaign_rounded,
                  onTap: () => context.push('/management/notifications')),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to trigger rebuild for refresh
  void setState(VoidCallback fn, BuildContext context) {}
}

class _ModuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
