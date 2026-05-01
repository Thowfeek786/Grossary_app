import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: OrderRepository().getOrderById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: AppLoader());
        final order = snapshot.data;
        if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: 'Order Details',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    OrderStatusBadge(status: order.statusString),
                  ],
                ),
                Text('Placed on ${order.createdAt.toString().split(' ')[0]}', style: const TextStyle(color: AppColors.textSecondary)),
                const Divider(height: 48),
                const Text('Customer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(order.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(order.userEmail),
                Text(order.userPhone),
                const SizedBox(height: 24),
                const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(order.deliveryAddress.fullAddress),
                const Divider(height: 48),
                const Text('Ordered Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                              width: 60, height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60, height: 60,
                                color: AppColors.grey200,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60, height: 60,
                                color: AppColors.grey200,
                                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 60, height: 60,
                              color: AppColors.grey200,
                              child: const Icon(Icons.image_outlined, color: Colors.grey),
                            ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${item.quantity} ${item.unit}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 48),
                 if (order.status == OrderStatus.pending)
                    Column(
                      children: [
                        AppButton(label: 'Accept & Start Preparing', onTap: () {
                          OrderRepository().updateOrderStatus(order.id, OrderStatus.accepted);
                          Navigator.pop(context);
                        }),
                        const SizedBox(height: 12),
                        AppButton(label: 'Reject Order', variant: AppButtonVariant.danger, onTap: () {
                           OrderRepository().updateOrderStatus(order.id, OrderStatus.cancelled);
                           Navigator.pop(context);
                        }),
                      ],
                    ),
                 if (order.status == OrderStatus.accepted)
                    AppButton(label: 'Mark as Ready for Pickup', onTap: () {
                      OrderRepository().updateOrderStatus(order.id, OrderStatus.processing);
                      Navigator.pop(context);
                    }),
              ],
            ),
          ),
        );
      },
    );
  }
}
