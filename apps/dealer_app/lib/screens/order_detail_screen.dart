import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: OrderRepository().getOrderById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFFF8FAFC), body: Center(child: CircularProgressIndicator(color: Color(0xFF059669))));
        }
        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Order Details', backgroundColor: Color(0xFF0B3C26), foregroundColor: Colors.white),
            body: const Center(child: Text('Order not found')),
          );
        }

        final code = order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: 'Order #$code',
            backgroundColor: const Color(0xFF0B3C26),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #$code', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('Placed: ${AppHelpers.formatDate(order.createdAt)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                          OrderStatusBadge(status: order.statusString),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stepper Status Indicator Row
                      Row(
                        children: [
                          _buildStepIndicator('Received', true),
                          _buildStepLine(order.status != OrderStatus.pending),
                          _buildStepIndicator('Packing', order.status != OrderStatus.pending),
                          _buildStepLine(order.status == OrderStatus.accepted || order.status == OrderStatus.shipped || order.status == OrderStatus.delivered),
                          _buildStepIndicator('Ready', order.status == OrderStatus.accepted || order.status == OrderStatus.shipped || order.status == OrderStatus.delivered),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Customer Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          ),
                          if (order.userPhone.isNotEmpty)
                            InkWell(
                              onTap: () => _makeCall(order.userPhone),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Call', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 18, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Text(order.userName.isNotEmpty ? order.userName : 'Customer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                      if (order.userEmail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(order.userEmail, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),
                      const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(order.deliveryAddress.fullAddress, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Ordered Items Checklist Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ordered Items (${order.items.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 16),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: AppHelpers.sanitizeUrl(item.imageUrl!),
                                          width: 54,
                                          height: 54,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(width: 54, height: 54, color: const Color(0xFFF1F5F9)),
                                          errorWidget: (context, url, error) => Container(width: 54, height: 54, color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))),
                                        )
                                      : Container(width: 54, height: 54, color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Qty: ${item.quantity} ${item.unit}',
                                          style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          )),

                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),

                      // Items Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items Subtotal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text(
                            '₹${(order.subtotal > 0 ? order.subtotal : order.items.fold(0.0, (s, i) => s + (i.price * i.quantity))).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Delivery Fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text(
                            order.deliveryFee == 0 ? 'FREE' : '₹${order.deliveryFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: order.deliveryFee == 0 ? const Color(0xFF059669) : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),

                      if (order.discount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Promo Discount', style: TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                            Text('-₹${order.discount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                          ],
                        ),
                      ],

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFFF1F5F9)),
                      ),

                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Bill Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Payment Method & Status Tag
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: order.isPaid ? const Color(0xFF059669).withValues(alpha: 0.08) : const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: order.isPaid ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  order.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                  size: 18,
                                  color: order.isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order.paymentMethod.isNotEmpty ? order.paymentMethod : 'Cash on Delivery',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: order.isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.isPaid ? 'PAID' : 'COLLECT CASH',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Order Action Buttons
                if (order.status == OrderStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            await OrderRepository().updateOrderStatus(order.id, OrderStatus.processing);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Accept & Pack Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () async {
                            await OrderRepository().updateOrderStatus(order.id, OrderStatus.cancelled);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.status == OrderStatus.processing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await OrderRepository().updateOrderStatus(order.id, OrderStatus.accepted);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Mark Packed & Ready for Pickup', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(String label, bool isDone) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: isDone ? Colors.white : const Color(0xFF94A3B8), size: 14),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF059669) : const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}
