import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Ongoing', 'Delivered', 'Cancelled'];

  bool _filterOrder(OrderModel order) {
    if (_selectedTab == 'All') return true;
    if (_selectedTab == 'Delivered') return order.status == OrderStatus.delivered;
    if (_selectedTab == 'Cancelled') return order.status == OrderStatus.cancelled;
    if (_selectedTab == 'Ongoing') {
      return order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final topPadding = MediaQuery.of(context).padding.top;

    if (user == null) {
      return Container(
        color: const Color(0xFFF9FAFB),
        child: const Center(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Please Log In',
            subtitle: 'Log in to view your orders and track live deliveries.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<List<OrderModel>>(
        stream: context.read<OrderProvider>().getUserOrders(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _OrderShimmerList();
          }
          if (snapshot.hasError) {
            return AppErrorWidget(message: snapshot.error.toString());
          }
          final allOrders = snapshot.data ?? [];
          final filteredOrders = allOrders.where(_filterOrder).toList();

          return Column(
            children: [
              // Dark Forest Green Hero Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF072F1D),
                      Color(0xFF0B462C),
                      Color(0xFF0F5A38),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track live status & details of your orders',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Filter Tabs Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _tabs.map((tab) {
                          final isSelected = _selectedTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = tab),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  tab,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF072F1D) : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _selectedTab == 'All' ? 'No orders yet' : 'No $_selectedTab orders',
                          subtitle: 'Your fresh grocery deliveries will appear here.',
                          actionLabel: 'Start Shopping',
                          onAction: () => context.go('/home'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount: filteredOrders.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _OrderCard(
                            order: filteredOrders[i],
                            onTap: () => context.push('/orders/${filteredOrders[i].id}'),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  int _getProgressStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 0; // Order Confirmed
      case OrderStatus.processing:
      case OrderStatus.shipped:
        return 1; // Preparing
      case OrderStatus.outForDelivery:
        return 2; // Out for Delivery
      case OrderStatus.delivered:
        return 3; // Delivered
      case OrderStatus.cancelled:
        return -1;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final timeStr = DateFormat('hh:mm a').format(dt);
    if (isToday) {
      return 'Today, $timeStr';
    }
    return '${DateFormat('dd MMM').format(dt)}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isOngoing = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
    final progressStep = _getProgressStep(order.status);
    final shortId = order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$shortId',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 4),

            // Date / Time
            Text(
              order.status == OrderStatus.delivered && order.deliveredAt != null
                  ? 'Delivered on ${_formatDateTime(order.deliveredAt!)}'
                  : 'Order Placed ${_formatDateTime(order.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),

            // Items count & total
            Text(
              '${order.itemCount} ${order.itemCount == 1 ? "item" : "items"} • ₹${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 12),

            // Product Thumbnails Row
            if (order.items.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length > 5 ? 5 : order.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = order.items[idx];
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                              )
                            : const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                      ),
                    );
                  },
                ),
              ),

            // Order Progress Stepper (Only for ongoing orders)
            if (isOngoing && progressStep >= 0) ...[
              const SizedBox(height: 16),
              _buildProgressStepper(progressStep),
              const SizedBox(height: 12),
              // Estimated delivery or scheduled time
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF046A38)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.notes != null && order.notes!.startsWith('Scheduled:')
                          ? order.notes!
                          : 'Estimated Delivery Today, 20–30 mins',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF046A38),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Track Order Button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF046A38), width: 1.2),
                    backgroundColor: const Color(0xFFEDF7EE),
                    foregroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Track Order',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStepper(int currentStep) {
    const steps = ['Order\nConfirmed', 'Preparing', 'Out for\nDelivery', 'Delivered'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connecting line
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              color: isCompleted ? const Color(0xFF046A38) : Colors.grey.shade300,
            ),
          );
        } else {
          // Step dot
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex <= currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF046A38) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? const Color(0xFF046A38) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: stepIndex == currentStep ? FontWeight.w800 : FontWeight.w500,
                  color: stepIndex <= currentStep ? const Color(0xFF046A38) : const Color(0xFF9CA3AF),
                  height: 1.1,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case OrderStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Pending';
        break;
      case OrderStatus.accepted:
      case OrderStatus.processing:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        label = 'Preparing';
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4F46E5);
        label = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        bg = const Color(0xFFEDF7EE);
        fg = const Color(0xFF046A38);
        label = 'Delivered';
        break;
      case OrderStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11.5),
      ),
    );
  }
}

class _OrderShimmerList extends StatelessWidget {
  const _OrderShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        itemCount: 4,
        itemBuilder: (_, _) => Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
