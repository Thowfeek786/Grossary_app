import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/delivery_provider.dart';
import '../providers/auth_provider.dart';
import 'navigation_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final delivery = context.watch<DeliveryProvider>();

    return StreamBuilder<OrderModel?>(
      stream: OrderRepository().getOrderStream(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final order = snapshot.data;
        if (order == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Order not found')));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: 'Order #${order.id.substring(0, 8).toUpperCase()}',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusTimeline(order),
                const SizedBox(height: 20),
                _buildCustomerCard(context, order),
                const SizedBox(height: 20),
                _buildStoreCard(context, order),
                const SizedBox(height: 20),
                _buildItemsCard(order),
                const SizedBox(height: 20),
                _buildPaymentCard(context, delivery, order),
              ],
            ),
          ),
          bottomSheet: _buildActionPanel(context, delivery, order),
        );
      },
    );
  }

  Widget _buildStatusTimeline(OrderModel order) {
    final allSteps = [
      (OrderStatus.pending, 'Order Placed', Icons.shopping_cart_rounded),
      (OrderStatus.accepted, 'Assigned to Store', Icons.store_rounded),
      (OrderStatus.processing, 'Being Prepared', Icons.inventory_2_rounded),
      (OrderStatus.shipped, 'Picked Up', Icons.local_shipping_rounded),
      (OrderStatus.outForDelivery, 'Out for Delivery', Icons.directions_bike_rounded),
      (OrderStatus.delivered, 'Delivered', Icons.check_circle_rounded),
    ];

    final currentIndex = allSteps.indexWhere((s) => s.$1 == order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          ...allSteps.asMap().entries.map((entry) {
            final idx = entry.key;
            final (status, label, icon) = entry.value;
            final isCompleted = idx <= currentIndex;
            final isCurrent = idx == currentIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.grey100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isCompleted ? AppColors.white : AppColors.grey400,
                      ),
                    ),
                    if (idx < allSteps.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: isCompleted ? AppColors.primary : AppColors.grey200,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 14,
                          )),
                      if (isCurrent)
                        Text(
                          'Current Status',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery To',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_pin_circle_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(order.deliveryAddress.fullAddress,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 13)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.directions_rounded,
                      color: AppColors.primary, size: 20),
                  onPressed: () {
                    final lat = order.deliveryAddress.latitude ?? 11.0;
                    final lng = order.deliveryAddress.longitude ?? 77.0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigationScreen(
                          destLat: lat,
                          destLng: lng,
                          title: 'Navigate to Customer',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pickup Location',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.dealerName ?? 'Store Location',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Text('Tap map icon to get directions',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.directions_rounded,
                      color: AppColors.primary, size: 20),
                  onPressed: () {
                    // Default store coordinates if not available in order
                    final lat = 11.01;
                    final lng = 77.01;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigationScreen(
                          destLat: lat,
                          destLng: lng,
                          title: 'Navigate to Store',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items (${order.itemCount})',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppHelpers.sanitizeUrl(item.imageUrl!),
                            width: 50, height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 50, height: 50,
                              color: AppColors.grey100,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 50, height: 50,
                              color: AppColors.grey100,
                              child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 50, height: 50,
                            color: AppColors.grey100,
                            child: const Icon(Icons.image_outlined, size: 20, color: Colors.grey),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${item.quantity} ${item.unit}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${item.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              )).toList(),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total to collect',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₹${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, DeliveryProvider delivery, OrderModel order) {
    final isCOD = order.paymentMethod.toLowerCase().contains('cash');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: order.isPaid ? AppColors.success.withOpacity(0.08) : AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isPaid ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                order.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: order.isPaid ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isPaid ? 'Payment Received' : 'Collect Payment on Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: order.isPaid ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    Text(
                      '${order.paymentMethod} • ₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Only show update option if it's COD and NOT paid yet
          if (!order.isPaid && isCOD && order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AppButton(
                label: 'Confirm Payment Received',
                height: 40,
                isFullWidth: false,
                variant: AppButtonVariant.primary,
                isLoading: delivery.isLoading,
                onTap: () async {
                  await delivery.updatePaymentStatus(order.id, true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment status updated!')),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, DeliveryProvider delivery, OrderModel order) {
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    String label;
    VoidCallback? action;
    Color color = AppColors.primary;

    switch (order.status) {
      case OrderStatus.shipped:
        label = 'Confirm Pickup';
        action = () async {
          await delivery.markPickedUp(order.id);
          // Don't pop, stream handles state
        };
        break;
      case OrderStatus.outForDelivery:
        // Ensure payment is confirmed if it's COD
        final isCOD = order.paymentMethod.toLowerCase().contains('cash');
        final canDeliver = !isCOD || order.isPaid;
        
        label = canDeliver ? 'Mark as Delivered ✓' : 'Please Collect Payment First';
        action = canDeliver ? () async {
          final userId = context.read<DeliveryAuthProvider>().user?.id;
          if (userId != null) {
            await delivery.completeDelivery(order.id, userId, 45.0);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Delivery completed!'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            }
          }
        } : null;
        color = canDeliver ? AppColors.success : AppColors.grey400;
        break;
      default:
        label = 'Awaiting Pickup Confirmation';
        action = null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: AppButton(
        label: label,
        isLoading: delivery.isLoading,
        onTap: action,
        // Disable button if no action (e.g. payment not collected)
      ),
    );
  }
}
