import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/admin_drawer.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AdminDrawer(user: user, auth: auth),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero Header ───
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            leading: IconButton(
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                ),
                onPressed: () => context.push('/management/settings'),
              ),
              IconButton(
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => context.push('/management/analytics'),
              ),
              IconButton(
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
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
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Welcome back,',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      color: Colors.white.withValues(alpha: 0.6), size: 12),
                                  const SizedBox(width: 5),
                                  Text(_formatDate(DateTime.now()),
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.5), blurRadius: 4)],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text('System Online',
                                      style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
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

          // ─── Stats Overview ───
          SliverToBoxAdapter(child: _buildStatsSection()),

          // ─── Quick Actions ───
          SliverToBoxAdapter(child: _buildQuickActions()),

          // ─── Management Modules ───
          SliverToBoxAdapter(child: _buildModulesSection()),

          // ─── Recent Orders Feed ───
          SliverToBoxAdapter(child: _buildRecentOrders()),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
          _sectionTitle('Platform Overview', const Color(0xFF6366F1), trailing: _liveBadge()),
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
          _sectionTitle('Quick Actions', const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickChip(Icons.add_box_rounded, 'Add Product', const Color(0xFF6366F1),
                    () => context.push('/management/products')),
                _QuickChip(Icons.campaign_rounded, 'Broadcast', const Color(0xFFEC4899),
                    () => context.push('/management/notifications')),
                _QuickChip(Icons.bar_chart_rounded, 'Analytics', const Color(0xFF14B8A6),
                    () => context.push('/management/analytics')),
                _QuickChip(Icons.confirmation_num_rounded, 'Coupons', const Color(0xFFEF4444),
                    () => context.push('/management/coupons')),
                _QuickChip(Icons.storefront_rounded, 'Dealers', const Color(0xFF10B981),
                    () => context.push('/management/dealers')),
                _QuickChip(Icons.local_fire_department_rounded, 'Flash Sale', const Color(0xFFF97316),
                    () => context.push('/management/flash-sale')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    final moduleGroups = [
      _ModGroup('Store Management', Icons.storefront_rounded, const Color(0xFF6366F1), [
        _Mod('Products', 'Add, edit or remove products', Icons.inventory_2_rounded, const Color(0xFF6366F1), '/management/products'),
        _Mod('Categories', 'Organize product categories', Icons.category_rounded, const Color(0xFF8B5CF6), '/management/categories'),
        _Mod('Banners', 'Control homepage banners', Icons.celebration_rounded, const Color(0xFFF59E0B), '/management/banners'),
        _Mod('Flash Sale', 'Configure live deal timer', Icons.local_fire_department_rounded, const Color(0xFFF97316), '/management/flash-sale'),
      ]),
      _ModGroup('Order & Fulfillment', Icons.local_shipping_rounded, const Color(0xFF3B82F6), [
        _Mod('Orders', 'Track and update statuses', Icons.receipt_long_rounded, const Color(0xFF3B82F6), '/management/orders'),
        _Mod('Dealers', 'Approve and manage dealers', Icons.storefront_rounded, const Color(0xFF10B981), '/management/dealers'),
        _Mod('Partner Payouts', 'Approve partner withdrawals', Icons.payments_rounded, const Color(0xFF059669), '/management/payout-requests'),
        _Mod('Delivery Rates', 'Configure delivery fees', Icons.local_shipping_outlined, const Color(0xFF78716C), '/management/delivery-settings'),
      ]),
      _ModGroup('Users & Finance', Icons.account_balance_rounded, const Color(0xFF10B981), [
        _Mod('Users & Roles', 'Manage users and permissions', Icons.manage_accounts_rounded, const Color(0xFF06B6D4), '/management/users'),
        _Mod('Coupons', 'Create & manage discount codes', Icons.confirmation_num_rounded, const Color(0xFFEF4444), '/management/coupons'),
        _Mod('Wallets', 'View balances & add credits', Icons.account_balance_wallet_rounded, const Color(0xFF84CC16), '/management/wallets'),
        _Mod('Payments', 'Transaction history & gateways', Icons.payments_rounded, const Color(0xFF0284C7), '/management/payments'),
        _Mod('Refunds', 'Process customer refunds', Icons.money_off_rounded, const Color(0xFFEAB308), '/management/refunds'),
      ]),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Management', const Color(0xFF0F172A)),
          const SizedBox(height: 12),
          ...moduleGroups.map((group) => _ModGroupWidget(group: group)),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Recent Activity',
            const Color(0xFFEF4444),
            trailing: GestureDetector(
              onTap: () => context.push('/management/orders'),
              child: const Text('View All',
                  style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<OrderModel>>(
            stream: _orderRepo.getAllOrders(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2),
                  ),
                );
              }
              final orders = snap.data!;
              orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final recent = orders.take(5).toList();

              if (recent.isEmpty) {
                return Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text('No recent orders', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: recent.asMap().entries.map((entry) {
                    final i = entry.key;
                    final o = entry.value;
                    final statusColor = _statusColor(o.status);
                    return Column(
                      children: [
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            onTap: () => context.push('/management/orders/${o.id}'),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_statusIcon(o.status), color: statusColor, size: 18),
                            ),
                            title: Text(
                              o.userName.isNotEmpty ? o.userName : '#${o.id.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Text(
                              '₹${o.total.toStringAsFixed(0)} · ${_timeAgo(o.createdAt)}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                o.status.name.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                        if (i < recent.length - 1)
                          const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
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
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
        const SizedBox(width: 4),
        const Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return const Color(0xFFF59E0B);
      case OrderStatus.accepted: return const Color(0xFF3B82F6);
      case OrderStatus.processing: return const Color(0xFF6366F1);
      case OrderStatus.shipped: return const Color(0xFF8B5CF6);
      case OrderStatus.outForDelivery: return const Color(0xFF0284C7);
      case OrderStatus.delivered: return const Color(0xFF10B981);
      case OrderStatus.cancelled: return const Color(0xFFEF4444);
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return Icons.schedule_rounded;
      case OrderStatus.accepted: return Icons.check_circle_outline_rounded;
      case OrderStatus.processing: return Icons.inventory_rounded;
      case OrderStatus.shipped: return Icons.local_shipping_rounded;
      case OrderStatus.outForDelivery: return Icons.two_wheeler_rounded;
      case OrderStatus.delivered: return Icons.done_all_rounded;
      case OrderStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            if (onTap != null) const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
          ]),
          const SizedBox(height: 14),
          isLoading
              ? Container(height: 20, width: 60, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)))
              : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: gradient[0].withValues(alpha: 0.7))),
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
          width: 78, padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    );
  }
}

// ─── Module Group Data ───
class _Mod {
  final String title, subtitle, route; final IconData icon; final Color color;
  const _Mod(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _ModGroup {
  final String title; final IconData icon; final Color color; final List<_Mod> modules;
  const _ModGroup(this.title, this.icon, this.color, this.modules);
}

class _ModGroupWidget extends StatefulWidget {
  final _ModGroup group;
  const _ModGroupWidget({required this.group});

  @override
  State<_ModGroupWidget> createState() => _ModGroupWidgetState();
}

class _ModGroupWidgetState extends State<_ModGroupWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: g.color.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Group header
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: g.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(g.icon, color: g.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(g.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: g.color)),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: g.color, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Module items
          AnimatedCrossFade(
            firstChild: Column(
              children: g.modules.asMap().entries.map((entry) {
                final m = entry.value;
                return Column(
                  children: [
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(m.icon, color: m.color, size: 18),
                        ),
                        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                        subtitle: Text(m.subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
                        onTap: () => context.push(m.route),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
