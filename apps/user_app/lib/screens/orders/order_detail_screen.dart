import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Order Status',
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: orderProvider.getOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const AppErrorWidget(message: 'Could not load order details');
          }
          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(order),
                const SizedBox(height: 24),
                _buildOrderTimeline(order),
                const SizedBox(height: 24),
                if (order.status == OrderStatus.delivered) ...[
                   _buildRatingSection(context, order),
                   const SizedBox(height: 24),
                ],
                const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildAddressCard(order),
                const SizedBox(height: 24),
                const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildItemsCard(context, order),
                const SizedBox(height: 24),
                _buildPaymentCard(order),
              ],
            ),
          );
        },
      ),
      bottomSheet: StreamBuilder<OrderModel?>(
        stream: orderProvider.getOrderStream(orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
          final order = snapshot.data!;
          if (order.status != OrderStatus.pending) return const SizedBox.shrink();
          
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: AppButton(
              label: 'Cancel Order',
              variant: AppButtonVariant.outlined,
              onTap: () => _showCancelDialog(context, order.id, orderProvider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(AppHelpers.formatDateTime(order.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          OrderStatusBadge(status: order.statusString),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text('Share your feedback!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Rate each item in your order to help us improve.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    final steps = [
      (OrderStatus.pending, 'Order Received'),
      (OrderStatus.processing, 'Store is Preparing'),
      (OrderStatus.accepted, 'Ready for Pickup'),
      (OrderStatus.shipped, 'Picked up by Partner'),
      (OrderStatus.outForDelivery, 'On the way to you'),
      (OrderStatus.delivered, 'Order Delivered'),
    ];

    if (order.status == OrderStatus.cancelled) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
               const Icon(Icons.cancel_rounded, color: AppColors.error),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Order Cancelled', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                     if (order.cancellationReason != null) 
                        Text(order.cancellationReason!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                   ],
                 ),
               ),
            ],
          ),
        );
    }

    final currentIndex = steps.indexWhere((s) => s.$1 == order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Track Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
           const SizedBox(height: 20),
           ...steps.asMap().entries.map((it) {
              final idx = it.key;
              final (status, label) = it.value;
              final isCompleted = idx <= currentIndex;
              final isLast = idx == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Column(
                     children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.primary : AppColors.grey200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded, size: 14, color: isCompleted ? AppColors.white : AppColors.grey400),
                        ),
                        if (!isLast)
                           Container(width: 2, height: 30, color: isCompleted ? AppColors.primary : AppColors.grey200),
                     ],
                   ),
                   const SizedBox(width: 16),
                   Padding(
                     padding: const EdgeInsets.only(top: 2),
                     child: Text(label, style: TextStyle(
                       fontWeight: idx == currentIndex ? FontWeight.w700 : FontWeight.w500,
                       color: isCompleted ? AppColors.textPrimary : AppColors.grey400,
                     )),
                   ),
                ],
              );
           }),
        ],
      ),
    );
  }

  Widget _buildAddressCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.deliveryAddress.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(order.deliveryAddress.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text(order.deliveryAddress.fullAddress, style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
      child: Column(
        children: [
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, width: 44, height: 44, fit: BoxFit.cover)
                      : Container(width: 44, height: 44, color: AppColors.grey100, child: const Icon(Icons.image_outlined, size: 20, color: AppColors.grey400)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${item.quantity} × ${item.unit}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (order.status == OrderStatus.delivered)
                   TextButton(
                     onPressed: () => context.push('/orders/review', extra: item),
                     child: const Text('Rate & Review', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                   )
                else
                   Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('₹${order.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(order.deliveryFee == 0 ? 'FREE' : '₹${order.deliveryFee.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, color: order.deliveryFee == 0 ? AppColors.success : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: order.isPaid ? AppColors.success.withOpacity(0.05) : AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: order.isPaid ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(order.isPaid ? Icons.check_circle_rounded : Icons.info_rounded, 
               color: order.isPaid ? AppColors.success : AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.isPaid ? 'Payment Confirmed' : 'Payment at Doorstep', 
                     style: TextStyle(fontWeight: FontWeight.w800, color: order.isPaid ? AppColors.success : AppColors.warning, fontSize: 14)),
                Text(order.paymentMethod, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, String orderId, OrderProvider provider) async {
      final reasonCtrl = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel Order?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(hintText: 'Optional reason...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Go Back')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), 
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Yes, Cancel Order'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await provider.cancelOrder(orderId, reasonCtrl.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Cancelled Successfully'), backgroundColor: AppColors.info));
          context.pop();
        }
      }
  }
}
