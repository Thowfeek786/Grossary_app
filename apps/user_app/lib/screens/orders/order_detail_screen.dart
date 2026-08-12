import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../utils/invoice_generator.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
        title: const Text('Order Details', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: orderProvider.getOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const AppErrorWidget(message: 'Could not load order details');
          }
          final order = snapshot.data!;
          final isActive = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(order),
                const SizedBox(height: 16),
                if (isActive) ...[
                  _buildOtpCard(order),
                  const SizedBox(height: 16),
                ],
                _buildOrderTimeline(order),
                const SizedBox(height: 24),
                if (order.status == OrderStatus.delivered) ...[
                  _buildRatingSection(context, order),
                  const SizedBox(height: 24),
                ],
                const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                _buildAddressCard(order),
                const SizedBox(height: 24),
                const Text('Order Items Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                _buildItemsCard(context, order),
                const SizedBox(height: 20),
                _buildPaymentCard(context, order),
                const SizedBox(height: 20),
                _buildInvoiceCard(context, order),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _showCancelModalSheet(context, order, orderProvider),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel Order', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpCard(OrderModel order) {
    final otp = order.deliveryOtp ?? '4829';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Verification OTP',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF047857)),
                ),
                SizedBox(height: 2),
                Text(
                  'Share code with driver at doorstep',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              otp,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppHelpers.formatDateTime(order.createdAt),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OrderStatusBadge(status: order.statusString),
        ],
      ),
    );
  }


  Widget _buildRatingSection(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.stars_rounded, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text('How was your order?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text(
            'Rate each item in your order to help us improve.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    final steps = [
      (OrderStatus.pending, 'Order Received'),
      (OrderStatus.processing, 'Store Preparing'),
      (OrderStatus.accepted, 'Ready for Pickup'),
      (OrderStatus.shipped, 'Picked up by Partner'),
      (OrderStatus.outForDelivery, 'On the way to you'),
      (OrderStatus.delivered, 'Order Delivered'),
    ];

    if (order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Cancelled', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  if (order.cancellationReason != null)
                    Text(order.cancellationReason!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = steps.indexWhere((s) => s.$1 == order.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Track Order Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
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
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, size: 14, color: isCompleted ? Colors.white : const Color(0xFF9CA3AF)),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 30, color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE5E7EB)),
                  ],
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: idx == currentIndex ? FontWeight.w900 : FontWeight.w600,
                      color: isCompleted ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                  ),
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
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Text(order.deliveryAddress.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.deliveryAddress.phone, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(order.deliveryAddress.fullAddress, style: const TextStyle(color: Color(0xFF4B5563), height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => context.push('/home/product/${item.productId}'),
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    width: 48,
                                    height: 48,
                                    color: const Color(0xFFF3F4F6),
                                    child: const Icon(Icons.local_grocery_store_rounded, size: 20, color: Color(0xFF10B981)),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFFF3F4F6),
                                  child: const Icon(Icons.local_grocery_store_rounded, size: 20, color: Color(0xFF10B981)),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827))),
                              Text('${item.quantity} × ${item.unit}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (order.status == OrderStatus.delivered)
                          TextButton(
                            onPressed: () => context.push('/orders/review', extra: item),
                            child: const Text('Rate Product', style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.w800)),
                          )
                        else
                          Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF111827))),
                      ],
                    ),
                  ),
                ),
              )),

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              Text('₹${order.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              Text(order.deliveryFee == 0 ? 'FREE' : '₹${order.deliveryFee.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, color: order.deliveryFee == 0 ? const Color(0xFF059669) : const Color(0xFF111827), fontWeight: FontWeight.w800)),
            ],
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount Applied', style: TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                Text('-₹${order.discount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w900)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))),
              Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF059669))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, OrderModel order) {
    final isCancelled = order.status == OrderStatus.cancelled;

    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle = order.paymentMethod;

    if (isCancelled) {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.08);
      border = const Color(0xFFEF4444).withValues(alpha: 0.3);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
      title = (order.isPaid || order.paymentMethod == 'GroceryGo Wallet')
          ? 'Refunded to Wallet'
          : 'Payment Cancelled';
      subtitle = (order.isPaid || order.paymentMethod == 'GroceryGo Wallet')
          ? '₹${order.total.toStringAsFixed(0)} credited to your wallet balance'
          : 'Order was cancelled; no payment charged.';
    } else if (order.isPaid) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.1);
      border = const Color(0xFF10B981).withValues(alpha: 0.3);
      iconColor = const Color(0xFF059669);
      icon = Icons.check_circle_rounded;
      title = 'Payment Confirmed';
    } else {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
      border = const Color(0xFFF59E0B).withValues(alpha: 0.3);
      iconColor = const Color(0xFFD97706);
      icon = Icons.info_rounded;
      title = 'Payment Pending / On Delivery';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: iconColor,
                            fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          if (!order.isPaid && !isCancelled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final settings =
                        await PaymentRepository().getPaymentSettings();
                    final upiVpa = settings.upiId.isNotEmpty
                        ? settings.upiId
                        : 'sthowfeek65@okaxis';
                    final payeeName = Uri.encodeComponent(
                        settings.merchantName.isNotEmpty
                            ? settings.merchantName
                            : 'GroceryGo Official Store');
                    final amt = order.total.toStringAsFixed(2);
                    final note = Uri.encodeComponent(
                        'Pay for Order #${order.id.substring(0, order.id.length > 6 ? 6 : order.id.length).toUpperCase()}');

                    final upiUrl =
                        'upi://pay?pa=$upiVpa&pn=$payeeName&am=$amt&cu=INR&tn=$note';
                    final uri = Uri.parse(upiUrl);

                    try {
                      final launched = await launchUrl(
                        uri,
                        mode: LaunchMode.externalNonBrowserApplication,
                      );
                      if (!launched) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (err) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Payee UPI VPA: $upiVpa. Please transfer ₹$amt directly.'),
                              backgroundColor: const Color(0xFF6366F1),
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error launching UPI retry: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(
                  'Pay ₹${order.total.toStringAsFixed(0)} Now via UPI',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, OrderModel order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => InvoiceGenerator.generateAndDownload(order),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF059669), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Tax Invoice',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Official PDF receipt with order & breakdown',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelModalSheet(
      BuildContext context, OrderModel order, OrderProvider provider) async {
    final reasons = [
      'Delivery time is too long',
      'Ordered wrong item(s) by mistake',
      'Incorrect delivery address selected',
      'Payment or pricing issue',
      'Forgot to apply coupon code',
      'Other reason',
    ];

    String? selectedReason;
    final feedbackCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isPaid = order.isPaid || order.paymentMethod == 'GroceryGo Wallet';

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cancel_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancel Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Please select a reason to cancel your order',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Select Reason',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setModalState(() => selectedReason = reason);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                    const Text(
                      'Additional Feedback (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Help us improve by providing extra feedback...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPaid
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPaid
                                ? Icons.account_balance_wallet_rounded
                                : Icons.info_outline_rounded,
                            color: isPaid
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPaid
                                  ? 'Refund Policy: ₹${order.total.toStringAsFixed(0)} will be credited back to your GroceryGo Wallet immediately.'
                                  : 'No cancellation fee applies.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isPaid
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Keep Order',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedReason == null || isSubmitting
                                ? null
                                : () async {
                                    setModalState(() => isSubmitting = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final fullReason = feedbackCtrl
                                            .text
                                            .trim()
                                            .isNotEmpty
                                        ? '$selectedReason - ${feedbackCtrl.text.trim()}'
                                        : selectedReason!;

                                    await provider.cancelOrder(
                                        order.id, fullReason);

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle_outline_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Order cancelled. $selectedReason',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              const Color(0xFFDC2626),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFFEF4444),
                              disabledBackgroundColor:
                                  const Color(0xFFFCA5A5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Confirm Cancel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
