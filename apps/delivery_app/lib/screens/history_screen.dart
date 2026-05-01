import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/delivery_provider.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final delivery = context.watch<DeliveryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Delivery History'),
      body: StreamBuilder<List<OrderModel>>(
        stream: delivery.getDeliveryHistory(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No Completed Deliveries',
              subtitle: 'Your delivered orders will appear here.',
            );
          }

          // Compute summary stats
          final totalEarnings = history.length * 45.0; // ₹45 per delivery estimate
          final totalDeliveries = history.length;

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryCard(
                      label: 'Total Deliveries',
                      value: totalDeliveries.toString(),
                      icon: Icons.local_shipping_rounded,
                    ),
                    Container(
                        width: 1, height: 50, color: Colors.white30),
                    _SummaryCard(
                      label: 'Est. Earned',
                      value: '₹${totalEarnings.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final o = history[i];
                    return _HistoryTile(order: o);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final OrderModel order;

  const _HistoryTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/order-detail/${order.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Delivered on ${AppHelpers.formatDate(order.deliveredAt ?? order.createdAt)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress.fullAddress,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 15),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+₹45',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    ),);
  }
}
