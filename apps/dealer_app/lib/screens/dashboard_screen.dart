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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

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
            onPressed: () => context.read<DealerAuthProvider>().logout(),
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
                                  value: _isStoreOpen,
                                  activeThumbColor: const Color(0xFF34D399),
                                  onChanged: (val) => setState(() => _isStoreOpen = val),
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
                    // Real Stats Grid from Firestore
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
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
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
                                  onTap: () => context.go('/inventory'),
                                ),
                                _StatCard(
                                  title: 'Total Sales',
                                  value: '₹${(totalSales / 1000).toStringAsFixed(1)}K',
                                  icon: Icons.insights_rounded,
                                  color: const Color(0xFF10B981),
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

                    const SizedBox(height: 28),

                    // Quick Actions Section Header
                    const Text('Vendor Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.add_box_rounded,
                            label: 'Add Product',
                            color: const Color(0xFF059669),
                            onTap: () => context.push('/add-product'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.inventory_rounded,
                            label: 'Inventory',
                            color: const Color(0xFF3B82F6),
                            onTap: () => context.go('/inventory'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.receipt_long_rounded,
                            label: 'Orders',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => context.go('/orders'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Recent Orders Preview Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Store Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        TextButton(
                          onPressed: () => context.go('/orders'),
                          child: const Text('View All', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<List<OrderModel>>(
                      stream: OrderRepository().getOrdersByDealer(user.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                        }
                        final orders = (snapshot.data ?? []).take(4).toList();
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A))),
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_rounded, color: Color(0xFF059669), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$orderCode',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${order.itemCount} items • ${AppHelpers.formatDate(order.createdAt)}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    OrderStatusBadge(status: order.statusString, isSmall: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
