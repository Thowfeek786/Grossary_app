import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';

class ActiveDeliveriesScreen extends StatelessWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DeliveryAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    
    final delivery = context.watch<DeliveryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Active Deliveries',
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: delivery.getActiveDeliveries(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final orders = snapshot.data?.where((o) => o.status != OrderStatus.delivered).toList() ?? [];
          
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No Active Deliveries',
              subtitle: 'Accept a request from the dashboard to start.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = orders[index];
              return _ActiveDeliveryCard(
                order: o,
                onTap: () => context.push('/order-detail/${o.id}'),
                onComplete: () => delivery.completeDelivery(o.id, user.id, 45.0),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _ActiveDeliveryCard({required this.order, required this.onTap, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Order #${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                 OrderStatusBadge(status: order.status.name, isSmall: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                 const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
                 const SizedBox(width: 8),
                 Expanded(child: Text(order.deliveryAddress.fullAddress, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Complete Delivery',
              onTap: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}
