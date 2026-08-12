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
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: Text('Order not found')),
          );
        }

        final orderCode = order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: 'Order #$orderCode',
            backgroundColor: const Color(0xFF0B3C26),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Status Header Card
                _buildHeroHeader(order),
                const SizedBox(height: 16),

                // Order Stepper Progress
                _buildStatusTimeline(order),
                const SizedBox(height: 16),

                // Customer Delivery Location Card
                _buildCustomerCard(context, order),
                const SizedBox(height: 16),

                // Pickup Store Location Card
                _buildStoreCard(context, order),
                const SizedBox(height: 16),

                // Ordered Items Summary
                _buildItemsCard(order),
                const SizedBox(height: 16),

                // Payment & Earnings Summary Card
                _buildPaymentCard(context, delivery, order),
              ],
            ),
          ),
          bottomSheet: _buildActionPanel(context, delivery, order),
        );
      },
    );
  }

  Widget _buildHeroHeader(OrderModel order) {
    Color statusBg;
    Color statusTextColor;
    String statusText;

    switch (order.status) {
      case OrderStatus.delivered:
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.15);
        statusTextColor = const Color(0xFF34D399);
        statusText = 'DELIVERED';
        break;
      case OrderStatus.outForDelivery:
        statusBg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        statusTextColor = const Color(0xFF60A5FA);
        statusText = 'OUT FOR DELIVERY';
        break;
      case OrderStatus.shipped:
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        statusTextColor = const Color(0xFFFBBF24);
        statusText = 'PICKED UP FROM STORE';
        break;
      case OrderStatus.cancelled:
        statusBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        statusTextColor = const Color(0xFFF87171);
        statusText = 'CANCELLED';
        break;
      default:
        statusBg = Colors.white.withValues(alpha: 0.15);
        statusTextColor = Colors.white70;
        statusText = order.status.name.toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3C26).withValues(alpha: 0.25),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusTextColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+₹45 Pay',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Order #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Placed on ${AppHelpers.formatDate(order.createdAt)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Timeline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 18),
          ...allSteps.asMap().entries.map((entry) {
            final idx = entry.key;
            final (_, label, icon) = entry.value;
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
                        color: isCompleted ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: isCurrent ? Border.all(color: const Color(0xFF34D399), width: 3) : null,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isCompleted ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (idx < allSteps.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                          color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      if (isCurrent)
                        const Text(
                          'Current Active Step',
                          style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_circle_rounded, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Text('CUSTOMER DELIVERY DESTINATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          Text(order.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(
            order.deliveryAddress.fullAddress,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final lat = order.deliveryAddress.latitude ?? 11.0183;
                    final lng = order.deliveryAddress.longitude ?? 76.9740;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigationScreen(
                          destLat: lat,
                          destLng: lng,
                          title: 'Customer: ${order.userName}',
                          address: order.deliveryAddress.fullAddress,
                          phone: order.deliveryAddress.phone.isNotEmpty ? order.deliveryAddress.phone : order.userPhone,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final targetPhone = order.deliveryAddress.phone.isNotEmpty
                        ? order.deliveryAddress.phone
                        : (order.userPhone.isNotEmpty ? order.userPhone : '+919876543210');
                    final cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9+]'), '');
                    final Uri url = Uri(scheme: 'tel', path: cleanPhone);
                    try {
                      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                      if (!launched) await launchUrl(url);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Text('PICKUP STORE LOCATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF64748B), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          Text(order.dealerName ?? 'GroceryGo Express Darkstore', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Central Darkstore Hub • Sector 4 Dispatch Bay #2',
            style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigationScreen(
                          destLat: 11.0168,
                          destLng: 76.9558,
                          title: 'Store: ${order.dealerName ?? "GroceryGo Darkstore Hub"}',
                          address: 'Central Darkstore Hub • Sector 4 Dispatch Bay #2',
                          phone: '+91 98765 43210',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Store Route'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items Checklist (${order.itemCount})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${order.itemCount} Items', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              ),
            ],
          ),
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
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 52,
                                height: 52,
                                color: const Color(0xFFF1F5F9),
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF059669))),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 52,
                                height: 52,
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.shopping_basket_rounded, size: 22, color: Color(0xFF94A3B8)),
                              ),
                            )
                          : Container(
                              width: 52,
                              height: 52,
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.shopping_basket_rounded, size: 22, color: Color(0xFF94A3B8)),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          Text('${item.quantity} × ${item.unit}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                  ],
                ),
              )),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bill Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
              Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, DeliveryProvider delivery, OrderModel order) {
    final isCOD = order.paymentMethod.toLowerCase().contains('cash');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: order.isPaid ? const Color(0xFF10B981).withValues(alpha: 0.08) : const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: order.isPaid ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                order.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: order.isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isPaid ? 'Payment Complete' : 'Collect Cash Payment on Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: order.isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.paymentMethod} • ₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!order.isPaid && isCOD && order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: delivery.isLoading
                      ? null
                      : () async {
                          await delivery.updatePaymentStatus(order.id, true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🎉 Cash Payment Confirmed Received!'), backgroundColor: Color(0xFF059669)),
                            );
                          }
                        },
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('Confirm Cash Collected', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, DeliveryProvider delivery, OrderModel order) {
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    String label;
    VoidCallback? action;

    switch (order.status) {
      case OrderStatus.shipped:
        label = 'Confirm Pickup from Store';
        action = () async {
          await delivery.markPickedUp(order.id);
        };
        break;
      case OrderStatus.outForDelivery:
        final isCOD = order.paymentMethod.toLowerCase().contains('cash');
        final canDeliver = !isCOD || order.isPaid;

        label = canDeliver ? 'Enter OTP & Complete Delivery 🔑' : 'Please Collect Cash First';
        action = canDeliver ? () => _showOtpDialog(context, delivery, order) : null;
        break;
      default:
        label = 'Awaiting Store Dispatch';
        action = null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: action != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: action != null ? 3 : 0,
          ),
          child: delivery.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }

  void _showOtpDialog(BuildContext context, DeliveryProvider delivery, OrderModel order) {
    final controllers = List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter Delivery Verification OTP',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ask customer for their 4-digit verification code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 56,
                          height: 60,
                          child: TextField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && index < 3) {
                                focusNodes[index + 1].requestFocus();
                              } else if (val.isEmpty && index > 0) {
                                focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(error, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: delivery.isLoading
                            ? null
                            : () async {
                                final inputOtp = controllers.map((c) => c.text).join();
                                if (inputOtp.length < 4) {
                                  setState(() => error = 'Please enter all 4 digits');
                                  return;
                                }

                                final partnerId = context.read<DeliveryAuthProvider>().user?.id ?? '';
                                final success = await delivery.verifyAndCompleteDelivery(
                                  orderId: order.id,
                                  partnerId: partnerId,
                                  inputOtp: inputOtp,
                                  amount: 45.0,
                                );

                                if (success) {
                                  if (modalContext.mounted) Navigator.pop(modalContext);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎉 OTP Verified & Order Delivered!'),
                                        backgroundColor: Color(0xFF059669),
                                      ),
                                    );
                                    context.pop();
                                  }
                                } else {
                                  setState(() => error = 'Incorrect OTP. Please check with customer.');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: delivery.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Verify & Complete Delivery ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
