import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:models/models.dart';
import '../providers/auth_provider.dart';

class DealerDashboard extends StatefulWidget {
  const DealerDashboard({super.key});

  @override
  State<DealerDashboard> createState() => _DealerDashboardState();
}

class _DealerDashboardState extends State<DealerDashboard> {
  bool _isStoreOpen = true;

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your vendor account?',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      context.read<DealerAuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Vendor Controls',
        showBackButton: false,
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => NotificationBottomSheet.show(context, stream: NotificationRepository().getUserNotifications(user.id, userRole: 'dealer')),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Dark Emerald Store Profile Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34D399).withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.store_rounded, color: Color(0xFF0B3C26), size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.shopName ?? user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.shopAddress ?? user.email,
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live Store Toggle Switch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isStoreOpen ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isStoreOpen ? const Color(0xFF6EE7B7) : Colors.white30),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _isStoreOpen ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  color: _isStoreOpen ? const Color(0xFF34D399) : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 20,
                                width: 32,
                                child: Switch(
                                  value: user.isOnline,
                                  activeThumbColor: const Color(0xFF34D399),
                                  onChanged: (val) {
                                    setState(() => _isStoreOpen = val);
                                    UserRepository().updateUser(user.copyWith(isOnline: val));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─────────────────────────────────────────────
                    // 1. Core Store Performance Metrics (General Grocery)
                    // ─────────────────────────────────────────────
                    StreamBuilder<List<OrderModel>>(
                      stream: OrderRepository().getOrdersByDealer(user.id),
                      builder: (context, orderSnap) {
                        final orders = orderSnap.data ?? [];
                        final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
                        final totalSales = orders.where((o) => o.status == OrderStatus.delivered).fold(0.0, (sum, o) => sum + o.total);

                        return StreamBuilder<List<ProductModel>>(
                          stream: ProductRepository().getProducts(dealerId: user.id, activeOnly: false),
                          builder: (context, prodSnap) {
                            final products = prodSnap.data ?? [];
                            final lowStock = products.where((p) => p.stockQuantity < 10 && p.stockQuantity > 0).length;

                            return GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _StatCard(
                                  title: 'Pending Orders',
                                  value: pendingCount.toString(),
                                  icon: Icons.hourglass_empty_rounded,
                                  color: const Color(0xFFF59E0B),
                                  onTap: () => context.go('/orders'),
                                ),
                                _StatCard(
                                  title: 'Low Stock Items',
                                  value: lowStock.toString(),
                                  icon: Icons.warning_amber_rounded,
                                  color: const Color(0xFFEF4444),
                                  onTap: () => context.push('/forecast'),
                                ),
                                _StatCard(
                                  title: 'Total Store Sales',
                                  value: '₹${(totalSales / 1000).toStringAsFixed(1)}K',
                                  icon: Icons.insights_rounded,
                                  color: const Color(0xFF10B981),
                                  onTap: () => context.push('/total-sales'),
                                ),
                                _StatCard(
                                  title: 'Products Listed',
                                  value: products.length.toString(),
                                  icon: Icons.inventory_rounded,
                                  color: const Color(0xFF3B82F6),
                                  onTap: () => context.go('/inventory'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ─────────────────────────────────────────────
                    // 2. Vendor Quick Actions
                    // ─────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vendor Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        InkWell(
                          onTap: () => context.push('/forecast'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_graph_rounded, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text('AI Forecaster', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w900, fontSize: 11.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<StoreSettingsModel>(
                      stream: SettingsRepository().getGlobalSettings(),
                      builder: (context, settingsSnap) {
                        final settings = settingsSnap.data ?? const StoreSettingsModel(id: 'global');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (settings.isPosEnabled) ...[
                                  Expanded(
                                    child: _ActionBtn(
                                      icon: Icons.point_of_sale_rounded,
                                      label: 'Store POS',
                                      color: const Color(0xFFEA580C),
                                      onTap: () => context.push('/pos'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: _ActionBtn(
                                    icon: Icons.auto_graph_rounded,
                                    label: 'AI Reorder',
                                    color: const Color(0xFFD97706),
                                    onTap: () => context.push('/forecast'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ActionBtn(
                                    icon: Icons.add_box_rounded,
                                    label: 'Add Item',
                                    color: const Color(0xFF059669),
                                    onTap: () => context.push('/add-product'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ActionBtn(
                                    icon: Icons.inventory_rounded,
                                    label: 'Inventory',
                                    color: const Color(0xFF3B82F6),
                                    onTap: () => context.go('/inventory'),
                                  ),
                                ),
                              ],
                            ),

                            if (settings.isWaterCanEnabled) ...[
                              const SizedBox(height: 24),

                              // Dedicated Water Can Operations Hub
                              StreamBuilder<Map<String, dynamic>>(
                                stream: WaterCanRepository().getDealerCanSummary(user.id),
                                builder: (context, canSnap) {
                                  final canData = canSnap.data ?? {};
                                  final cansSold = canData['totalDelivered'] ?? 0;
                                  final cansCollected = canData['totalCollected'] ?? 0;
                                  final canBalance = canData['canBalance'] ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Water Can Operations Hub',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () => context.push('/can-returns'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Ledger',
                                                      style: TextStyle(
                                                        color: Color(0xFF0F766E),
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    SizedBox(width: 2),
                                                    Icon(Icons.chevron_right_rounded, color: Color(0xFF0F766E), size: 14),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              _WaterCanStatPill(
                                                label: 'Cans Sold',
                                                value: '$cansSold',
                                              ),
                                              const SizedBox(width: 8),
                                              _WaterCanStatPill(
                                                label: 'With Customers',
                                                value: '$canBalance',
                                              ),
                                              const SizedBox(width: 8),
                                              _WaterCanStatPill(
                                                label: 'Collected',
                                                value: '$cansCollected',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => context.push('/subscribers'),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.08),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.people_alt_rounded, color: Color(0xFF0F766E), size: 15),
                                                      SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          'Subscribers & Run',
                                                          style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w900, fontSize: 11.5),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => context.push('/can-returns'),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.18),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 15),
                                                      SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          'Can Returns',
                                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        TextButton(
                          onPressed: () => context.go('/orders'),
                          child: const Text('View All', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<OrderModel>>(
                      stream: OrderRepository().getOrdersByDealer(user.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                        }
                        final orders = (snapshot.data ?? []).take(5).toList();
                        if (orders.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 8),
                                  Text('No orders yet', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  Text('Incoming store orders will appear here', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: orders.map((o) => _RecentOrderCard(order: o, onTap: () => context.push('/order/${o.id}'))).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _RecentOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final orderCode = order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final itemTitle = firstItem != null
        ? (firstItem.isWaterCan
            ? (firstItem.canExchange ? '20L Can (Refill)' : '20L Can (New)')
            : firstItem.productName)
        : '${order.itemCount} items';
    final qtyText = firstItem != null ? '${firstItem.quantity} Qty' : '${order.itemCount} Qty';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$orderCode',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppHelpers.formatDate(order.createdAt),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        qtyText,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      OrderStatusBadge(status: order.statusString, isSmall: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterCanStatPill extends StatelessWidget {
  final String label;
  final String value;

  const _WaterCanStatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE6FFFA),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
