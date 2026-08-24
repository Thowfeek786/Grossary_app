import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final _orderRepo = OrderRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Order #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8).toUpperCase() : widget.orderId}',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/management/orders');
            }
          },
        ),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderRepo.getOrderStream(widget.orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final order = snap.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order Not Found',
              subtitle: 'This order may have been removed or does not exist.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header status card
                _buildHeaderCard(order),
                const SizedBox(height: 16),

                // Customer Info
                _buildCustomerCard(order),
                const SizedBox(height: 16),

                // Delivery Address
                _buildAddressCard(order),
                const SizedBox(height: 16),

                // Items list
                _buildItemsCard(order),
                const SizedBox(height: 16),

                // Payment Breakdown
                _buildPaymentCard(order),
                const SizedBox(height: 16),

                // Delivery Partner Info (if assigned)
                if (order.deliveryPartnerName != null) ...[
                  _buildDeliveryPartnerCard(order),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                _buildActionButtons(order),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shopping_bag_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatus(order.status),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: statusColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Placed on ${_formatDateTime(order.createdAt)}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: order.isPaid ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              order.isPaid ? 'PAID' : 'UNPAID',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: order.isPaid ? const Color(0xFF059669) : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Customer Information', Icons.person_rounded, const Color(0xFF6366F1)),
          const SizedBox(height: 14),
          _infoRow(Icons.person_outline, 'Name', order.userName),
          _infoRow(Icons.phone_outlined, 'Phone', order.userPhone),
          _infoRow(Icons.email_outlined, 'Email', order.userEmail),
        ],
      ),
    );
  }

  Widget _buildAddressCard(OrderModel order) {
    final addr = order.deliveryAddress;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Delivery Address', Icons.location_on_rounded, const Color(0xFFEF4444)),
          const SizedBox(height: 14),
          Text(
            addr.fullName.isNotEmpty ? addr.fullName : order.userName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            addr.fullAddress,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Items Ordered (${order.itemCount})', Icons.inventory_2_rounded, const Color(0xFF3B82F6)),
          const SizedBox(height: 14),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, size: 20, color: Color(0xFF94A3B8)),
                              ),
                            )
                          : const Icon(Icons.fastfood_rounded, size: 20, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                          Text('₹${item.price.toStringAsFixed(0)} × ${item.quantity}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text('₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Payment Breakdown', Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
          const SizedBox(height: 14),
          _priceRow('Subtotal', order.subtotal),
          _priceRow('Delivery Fee', order.deliveryFee),
          if (order.discount > 0) _priceRow('Discount (${order.couponCode ?? ''})', -order.discount, isDiscount: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
              Text('₹${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF6366F1))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Payment Method: ${order.paymentMethod}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDeliveryPartnerCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Delivery Partner', Icons.delivery_dining_rounded, const Color(0xFF8B5CF6)),
          const SizedBox(height: 14),
          _infoRow(Icons.person_outline, 'Name', order.deliveryPartnerName ?? 'Unassigned'),
          _infoRow(Icons.phone_outlined, 'Phone', order.deliveryPartnerPhone ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showUpdateStatusModal(order),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Update Order Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _showAssignDeliveryModal(order),
            icon: const Icon(Icons.delivery_dining_rounded, size: 18),
            label: const Text('Assign Delivery Partner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  void _showUpdateStatusModal(OrderModel order) {
    final statuses = OrderStatus.values.where((s) => s != order.status).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: statuses.map((status) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.circle, color: _getStatusColor(status), size: 14),
                    title: Text(_formatStatus(status), style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _orderRepo.updateOrderStatus(order.id, status);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Status updated to ${_formatStatus(status)}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDeliveryModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assign Delivery Partner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: UserRepository().getUsersByRole(UserRole.deliveryPartner),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final partners = snapshot.data ?? [];
                    if (partners.isEmpty) {
                      return const EmptyState(
                        icon: Icons.delivery_dining_outlined,
                        title: 'No Delivery Partners',
                        subtitle: 'No delivery partner accounts registered yet.',
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      itemCount: partners.length,
                      itemBuilder: (context, index) {
                        final partner = partners[index];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(partner.phone),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            await _orderRepo.assignDeliveryPartner(
                              orderId: order.id,
                              partnerId: partner.id,
                              partnerName: partner.name,
                              partnerPhone: partner.phone,
                            );
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Assigned to ${partner.name}'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _cardTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFF59E0B);
      case OrderStatus.accepted: return const Color(0xFF3B82F6);
      case OrderStatus.processing: return const Color(0xFF8B5CF6);
      case OrderStatus.shipped: return const Color(0xFF06B6D4);
      case OrderStatus.outForDelivery: return const Color(0xFF14B8A6);
      case OrderStatus.delivered: return const Color(0xFF10B981);
      case OrderStatus.cancelled: return const Color(0xFFEF4444);
    }
  }

  String _formatStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.accepted: return 'Accepted';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  String _formatDateTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
