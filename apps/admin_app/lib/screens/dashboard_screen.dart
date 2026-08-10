import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';
import '../providers/management_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _userRepo = UserRepository();
  final _orderRepo = OrderRepository();
  final _productRepo = ProductRepository();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _AdminDrawer(user: user, auth: auth),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Sticky Header ───
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: const Color(0xFF1B5E20),
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => context.push('/management/analytics'),
              ),
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => context.push('/profile'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
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
                        Text('Welcome back,',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                        Text(user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: Colors.white.withOpacity(0.7), size: 12),
                              const SizedBox(width: 5),
                              Text(_formatDate(DateTime.now()),
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 12),
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  color: AppColors.success, shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('Online',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('GroceryGo Admin',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),

          // ─── Stats ───
          SliverToBoxAdapter(child: _buildStatsSection()),

          // ─── Quick Actions ───
          SliverToBoxAdapter(child: _buildQuickActions()),

          // ─── Modules ───
          SliverToBoxAdapter(child: _buildModulesSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Platform Overview', AppColors.primary, trailing: _liveBadge()),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  SizedBox(width: w, child: _usersCard()),
                  SizedBox(width: w, child: _ordersCard()),
                  SizedBox(width: w, child: _revenueCard()),
                  SizedBox(width: w, child: _productsCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _usersCard() {
    return StreamBuilder<List<UserModel>>(
      stream: _userRepo.getAllUsers(),
      builder: (context, snap) {
        final loading = !snap.hasData;
        final all = snap.data ?? [];
        final customers = all.where((u) => u.role == UserRole.customer).length;
        final dealers = all.where((u) => u.role == UserRole.dealer).length;
        return _StatCard(
          title: 'Total Users', value: loading ? '...' : all.length.toString(),
          subtitle: loading ? '' : '$customers buyers · $dealers vendors',
          icon: Icons.people_rounded,
          gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
          isLoading: loading,
          onTap: () => context.push('/management/users'),
        );
      },
    );
  }

  Widget _ordersCard() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final loading = !snap.hasData;
        final orders = snap.data ?? [];
        final now = DateTime.now();
        final today = orders.where((o) {
          final c = o.createdAt;
          return c.year == now.year && c.month == now.month && c.day == now.day;
        }).length;
        final pending = orders.where((o) => o.status == OrderStatus.pending).length;
        return _StatCard(
          title: "Today's Orders", value: loading ? '...' : today.toString(),
          subtitle: loading ? '' : '$pending pending',
          icon: Icons.receipt_long_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          isLoading: loading,
          onTap: () => context.push('/management/orders'),
        );
      },
    );
  }

  Widget _revenueCard() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final loading = !snap.hasData;
        final orders = snap.data ?? [];
        final revenue = orders
            .where((o) => o.status == OrderStatus.delivered)
            .fold(0.0, (sum, o) => sum + o.total);
        final delivered = orders.where((o) => o.status == OrderStatus.delivered).length;
        return _StatCard(
          title: 'Total Revenue', value: loading ? '...' : '₹${_fmtRev(revenue)}',
          subtitle: loading ? '' : '$delivered delivered',
          icon: Icons.trending_up_rounded,
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
          isLoading: loading,
        );
      },
    );
  }

  Widget _productsCard() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productRepo.getProducts(activeOnly: false),
      builder: (context, snap) {
        final loading = !snap.hasData;
        final prods = snap.data ?? [];
        final active = prods.where((p) => p.isActive).length;
        return _StatCard(
          title: 'Products', value: loading ? '...' : prods.length.toString(),
          subtitle: loading ? '' : '$active active',
          icon: Icons.inventory_2_rounded,
          gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          isLoading: loading,
          onTap: () => context.push('/management/products'),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Quick Actions', AppColors.secondary),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickChip(Icons.add_box_rounded, 'Add Product', const Color(0xFF6366F1),
                    () => context.push('/management/products')),
                _QuickChip(Icons.campaign_rounded, 'Broadcast', const Color(0xFFF59E0B),
                    () => context.push('/management/notifications')),
                _QuickChip(Icons.bar_chart_rounded, 'Analytics', const Color(0xFF10B981),
                    () => context.push('/management/analytics')),
                _QuickChip(Icons.confirmation_num_rounded, 'Coupons', const Color(0xFFEF4444),
                    () => context.push('/management/coupons')),
                _QuickChip(Icons.local_shipping_rounded, 'Orders', const Color(0xFF3B82F6),
                    () => context.push('/management/orders')),
                _QuickChip(Icons.settings_rounded, 'Delivery', const Color(0xFF8B5CF6),
                    () => context.push('/management/delivery-settings')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    final modules = [
      _Mod('Products', 'Add, edit or remove products', Icons.inventory_2_rounded, const Color(0xFF6366F1), '/management/products'),
      _Mod('Categories', 'Organize product categories', Icons.category_rounded, const Color(0xFF8B5CF6), '/management/categories'),
      _Mod('Orders', 'Track and update statuses', Icons.local_shipping_rounded, const Color(0xFF3B82F6), '/management/orders'),
      _Mod('Users & Roles', 'Manage users and permissions', Icons.manage_accounts_rounded, const Color(0xFF06B6D4), '/management/users'),
      _Mod('Banners', 'Control homepage banners', Icons.celebration_rounded, const Color(0xFFF59E0B), '/management/banners'),
      _Mod('Flash Sale', 'Configure live deal timer & products', Icons.local_fire_department_rounded, const Color(0xFFF59E0B), '/management/flash-sale'),

      _Mod('Dealers', 'Approve and manage dealers', Icons.storefront_rounded, const Color(0xFF10B981), '/management/dealers'),
      _Mod('Coupons', 'Create & manage discount codes', Icons.confirmation_num_rounded, const Color(0xFFEF4444), '/management/coupons'),
      _Mod('Notifications', 'Send push alerts to apps', Icons.campaign_rounded, const Color(0xFFEC4899), '/management/notifications'),
      _Mod('Analytics', 'Revenue, charts & insights', Icons.bar_chart_rounded, const Color(0xFF14B8A6), '/management/analytics'),
      _Mod('Product Reviews', 'Moderate customer reviews', Icons.rate_review_rounded, const Color(0xFFF97316), '/management/reviews'),
      _Mod('Refund Requests', 'Process customer refunds', Icons.money_off_rounded, const Color(0xFFEAB308), '/management/refunds'),
      _Mod('User Wallets', 'View balances & add credits', Icons.account_balance_wallet_rounded, const Color(0xFF84CC16), '/management/wallets'),
      _Mod('Payments', 'Transaction history & gateways', Icons.payments_rounded, const Color(0xFF0284C7), '/management/payments'),
      _Mod('Platform Settings', 'Global settings & toggles', Icons.settings_rounded, const Color(0xFF64748B), '/management/platform-settings'),
      _Mod('Delivery Rates', 'Configure delivery fees', Icons.local_shipping_outlined, const Color(0xFF78716C), '/management/delivery-settings'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Management', AppColors.accent),
          const SizedBox(height: 10),
          ...modules.map((m) => _ModTile(data: m, onTap: () => context.push(m.route))),
        ],
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionTitle(String text, Color accent, {Widget? trailing}) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        const Text('LIVE', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  void _showLogoutDialog(BuildContext context, AdminAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20)),
          const SizedBox(width: 12),
          const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); auth.logout(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtRev(double r) {
    if (r >= 100000) return '${(r / 100000).toStringAsFixed(1)}L';
    if (r >= 1000) return '${(r / 1000).toStringAsFixed(1)}K';
    return r.toStringAsFixed(0);
  }
}

// ─── Sidebar Drawer ───
class _AdminDrawer extends StatelessWidget {
  final UserModel user;
  final AdminAuthProvider auth;
  const _AdminDrawer({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24))),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white30)),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26)),
              const SizedBox(height: 12),
              Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                child: const Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
              _DI(Icons.dashboard_rounded, 'Dashboard', () { Navigator.pop(context); }),
              _DI(Icons.bar_chart_rounded, 'Analytics', () { Navigator.pop(context); context.push('/management/analytics'); }),
              const Divider(height: 16, indent: 16, endIndent: 16),
              _DI(Icons.inventory_2_rounded, 'Products', () { Navigator.pop(context); context.push('/management/products'); }),
              _DI(Icons.category_rounded, 'Categories', () { Navigator.pop(context); context.push('/management/categories'); }),
              _DI(Icons.receipt_long_rounded, 'Orders', () { Navigator.pop(context); context.push('/management/orders'); }),
              _DI(Icons.people_rounded, 'Users', () { Navigator.pop(context); context.push('/management/users'); }),
              _DI(Icons.storefront_rounded, 'Dealers', () { Navigator.pop(context); context.push('/management/dealers'); }),
              _DI(Icons.confirmation_num_rounded, 'Coupons', () { Navigator.pop(context); context.push('/management/coupons'); }),
              _DI(Icons.rate_review_rounded, 'Reviews', () { Navigator.pop(context); context.push('/management/reviews'); }),
              _DI(Icons.money_off_rounded, 'Refunds', () { Navigator.pop(context); context.push('/management/refunds'); }),
              _DI(Icons.account_balance_wallet_rounded, 'Wallets', () { Navigator.pop(context); context.push('/management/wallets'); }),
              _DI(Icons.payments_rounded, 'Payments', () { Navigator.pop(context); context.push('/management/payments'); }),
              const Divider(height: 16, indent: 16, endIndent: 16),
              _DI(Icons.celebration_rounded, 'Banners', () { Navigator.pop(context); context.push('/management/banners'); }),
              _DI(Icons.campaign_rounded, 'Notifications', () { Navigator.pop(context); context.push('/management/notifications'); }),
              _DI(Icons.settings_rounded, 'Platform Settings', () { Navigator.pop(context); context.push('/management/platform-settings'); }),
              _DI(Icons.local_shipping_rounded, 'Delivery Rates', () { Navigator.pop(context); context.push('/management/delivery-settings'); }),
              const Divider(height: 16, indent: 16, endIndent: 16),
              _DI(Icons.person_rounded, 'Profile', () { Navigator.pop(context); context.push('/profile'); }),
              _DI(Icons.logout_rounded, 'Sign Out', () {
                Navigator.pop(context);
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () { Navigator.pop(ctx); auth.logout(); },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Sign Out')),
                  ],
                ));
              }, color: AppColors.error),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(14), child: Text('GroceryGo Admin v1.0', style: TextStyle(color: AppColors.grey400, fontSize: 10))),
        ],
      ),
    );
  }
}

class _DI extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap; final Color? color;
  const _DI(this.icon, this.title, this.onTap, {this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: color ?? AppColors.textPrimary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}

// ─── Stat Card ───
class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool isLoading;
  final VoidCallback? onTap;
  const _StatCard({required this.title, required this.value, required this.subtitle,
    required this.icon, required this.gradient, this.isLoading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: Colors.white, size: 16)),
            if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.grey400),
          ]),
          const SizedBox(height: 12),
          isLoading
              ? Container(height: 18, width: 50, decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(4)))
              : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.1)),
          const SizedBox(height: 3),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: gradient[0].withOpacity(0.7))),
          ],
        ]),
      ),
    );
  }
}

// ─── Quick Chip ───
class _QuickChip extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickChip(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 74, padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 5),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    );
  }
}

// ─── Module Tile ───
class _Mod {
  final String title, subtitle, route; final IconData icon; final Color color;
  const _Mod(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _ModTile extends StatelessWidget {
  final _Mod data; final VoidCallback onTap;
  const _ModTile({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: data.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(data.icon, color: data.color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(data.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ])),
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.grey500)),
          ]),
        ),
      ),
    );
  }
}
