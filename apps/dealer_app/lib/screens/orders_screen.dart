import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class DealerOrdersScreen extends StatefulWidget {
  const DealerOrdersScreen({super.key});

  @override
  State<DealerOrdersScreen> createState() => _DealerOrdersScreenState();
}

class _DealerOrdersScreenState extends State<DealerOrdersScreen> {
  final _orderRepo = OrderRepository();
  OrderStatus? _filterStatus;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Store Orders',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusSummary(user.id),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _orderRepo.getOrdersByDealer(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoader();
                }
                if (snapshot.hasError) {
                  return AppErrorWidget(message: snapshot.error.toString());
                }

                var orders = snapshot.data ?? [];

                // Apply filter
                if (_filterStatus != null) {
                  orders = orders.where((o) => o.status == _filterStatus).toList();
                }

                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _filterStatus == null
                        ? 'No Orders Yet'
                        : 'No ${_statusLabel(_filterStatus!)} Orders',
                    subtitle: 'Orders assigned to your store will appear here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    return _DealerOrderCard(
                      order: order,
                      isUpdating: _isUpdating,
                      onTap: () => context.push('/order/${order.id}'),
                      onAccept: () => _updateStatus(order.id, OrderStatus.processing),
                      onReject: () => _showRejectDialog(context, order.id),
                      onReadyForPickup: () =>
                          _updateStatus(order.id, OrderStatus.accepted),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(String dealerId) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getOrdersByDealer(dealerId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final pending = orders.where((o) => o.status == OrderStatus.pending).length;
        final processing = orders.where((o) => o.status == OrderStatus.processing).length;
        final today = orders.where((o) {
          final now = DateTime.now();
          return o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day;
        }).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.white,
          child: Row(
            children: [
              _SummaryChip('Pending', pending.toString(), AppColors.warning),
              const SizedBox(width: 12),
              _SummaryChip('Processing', processing.toString(), AppColors.info),
              const SizedBox(width: 12),
              _SummaryChip("Today's", today.toString(), AppColors.primary),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String orderId, OrderStatus status) async {
    setState(() => _isUpdating = true);
    try {
      await _orderRepo.updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_statusLabel(status)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, String orderId) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this order:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Out of stock, Cannot fulfill',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isUpdating = true);
      try {
        await _orderRepo.cancelOrder(orderId, reasonCtrl.text.trim().isEmpty
            ? 'Cancelled by dealer'
            : reasonCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order rejected'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                null,
                OrderStatus.pending,
                OrderStatus.accepted,
                OrderStatus.processing,
                OrderStatus.delivered,
                OrderStatus.cancelled,
              ].map((status) {
                final label = status == null ? 'All Orders' : _statusLabel(status);
                final isSelected = _filterStatus == status;
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _filterStatus = status);
                    Navigator.pop(ctx);
                  },
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.accepted: return 'Ready for Pickup';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label,
                style:
                    TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _DealerOrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onReadyForPickup;

  const _DealerOrderCard({
    required this.order,
    required this.isUpdating,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
    required this.onReadyForPickup,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.status == OrderStatus.pending
                ? AppColors.warning.withOpacity(0.5)
                : AppColors.grey200,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                OrderStatusBadge(status: order.statusString, isSmall: true),
              ],
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(order.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${order.itemCount} items',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Order Value',
                        style:
                            TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.formatDateTime(order.createdAt),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            // Order items preview
            const SizedBox(height: 10),
            Text(
              order.items.take(3).map((i) => '${i.quantity}x ${i.productName}').join(' · '),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Action buttons
            if (order.status == OrderStatus.pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      variant: AppButtonVariant.outlined,
                      isLoading: isUpdating,
                      onTap: onReject,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Accept & Prepare',
                      isLoading: isUpdating,
                      onTap: onAccept,
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.processing) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Mark Ready for Pickup',
                  isLoading: isUpdating,
                  onTap: onReadyForPickup,
                ),
              ),
            ] else if (order.status == OrderStatus.cancelled) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cancelled${order.cancellationReason != null ? ': ${order.cancellationReason}' : ''}',
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
