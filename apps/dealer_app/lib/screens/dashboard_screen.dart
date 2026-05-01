import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:models/models.dart';
import '../providers/auth_provider.dart';

class DealerDashboard extends StatelessWidget {
  const DealerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Vendor Controls',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () => context.read<DealerAuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store profile banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: AppColors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.shopName ?? user.name,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.shopAddress ?? user.email,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.rating?.toStringAsFixed(1) ?? '5.0'} Rating',
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Real Stats from Firestore
              StreamBuilder<List<OrderModel>>(
                stream: OrderRepository().getOrdersByDealer(user.id),
                builder: (context, orderSnap) {
                  final orders = orderSnap.data ?? [];
                  final pendingCount = orders
                      .where((o) => o.status == OrderStatus.pending)
                      .length;
                  final totalSales = orders
                      .where((o) => o.status == OrderStatus.delivered)
                      .fold(0.0, (sum, o) => sum + o.total);

                  return StreamBuilder<List<ProductModel>>(
                    stream: ProductRepository()
                        .getProducts(dealerId: user.id, activeOnly: false),
                    builder: (context, prodSnap) {
                      final products = prodSnap.data ?? [];
                      final lowStock = products
                          .where((p) => p.stockQuantity < 10 && p.stockQuantity > 0)
                          .length;

                      return GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            title: 'Pending Orders',
                            value: pendingCount.toString(),
                            icon: Icons.hourglass_empty_rounded,
                            color: AppColors.warning,
                            onTap: () => context.push('/orders'),
                          ),
                          StatCard(
                            title: 'Low Stock Items',
                            value: lowStock.toString(),
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.error,
                            onTap: () => context.push('/inventory'),
                          ),
                          StatCard(
                            title: 'Total Sales',
                            value: '₹${(totalSales / 1000).toStringAsFixed(1)}K',
                            icon: Icons.insights_rounded,
                            color: AppColors.success,
                          ),
                          StatCard(
                            title: 'Products Listed',
                            value: products.length.toString(),
                            icon: Icons.inventory_rounded,
                            color: AppColors.info,
                            onTap: () => context.push('/inventory'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _ActionBtn(
                          icon: Icons.add_box_rounded,
                          label: 'Add Product',
                          onTap: () => context.push('/add-product'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _ActionBtn(
                          icon: Icons.inventory_rounded,
                          label: 'Inventory',
                          onTap: () => context.push('/inventory'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _ActionBtn(
                          icon: Icons.receipt_long_rounded,
                          label: 'Orders',
                          onTap: () => context.push('/orders'))),
                ],
              ),
              const SizedBox(height: 32),
              // Recent Orders Preview
              const Text('Recent Orders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              StreamBuilder<List<OrderModel>>(
                stream: OrderRepository().getOrdersByDealer(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }
                  final orders =
                      (snapshot.data ?? []).take(3).toList();
                  if (orders.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      subtitle: 'Your recent orders will appear here',
                    );
                  }
                  return Column(
                    children: orders.map((o) => _RecentOrderTile(
                          order: o,
                          onTap: () => context.push('/order/${o.id}'),
                        )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 12),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _RecentOrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style:
                        const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    '${order.itemCount} items • ${AppHelpers.formatDate(order.createdAt)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                OrderStatusBadge(status: order.statusString, isSmall: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
