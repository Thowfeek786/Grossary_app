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
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Store Orders Fulfillments',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF34D399)),
            tooltip: 'Export Store Orders (CSV/PDF)',
            onPressed: () async {
              final orders = await _orderRepo.getOrdersByDealer(user.id).first;
              final csv = ExportService.generateOrdersCsv(orders);
              if (context.mounted) {
                ExportService.showExportDialog(context, title: 'Store Orders Data', csvContent: csv, pdfSummaryTitle: 'Dealer Orders Statement');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }
                if (snapshot.hasError) {
                  return AppErrorWidget(message: snapshot.error.toString());
                }

                var orders = snapshot.data ?? [];

                if (_filterStatus != null) {
                  orders = orders.where((o) => o.status == _filterStatus).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF059669)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filterStatus == null ? 'No Store Orders Yet' : 'No ${_statusLabel(_filterStatus!)} Orders',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Incoming customer orders for your store will appear here for packing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    return _DealerOrderCard(
                      order: order,
                      isUpdating: _isUpdating,
                      onTap: () => context.push('/order/${order.id}'),
                      onAccept: () => _updateStatus(order.id, OrderStatus.processing),
                      onReject: () => _showRejectDialog(context, order.id),
                      onReadyForPickup: () => _updateStatus(order.id, OrderStatus.accepted),
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
          return o.createdAt.year == now.year && o.createdAt.month == now.month && o.createdAt.day == now.day;
        }).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              _SummaryChip('Pending', pending.toString(), const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              _SummaryChip('Processing', processing.toString(), const Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              _SummaryChip("Today's Total", today.toString(), const Color(0xFF059669)),
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
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Order', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please state why your store cannot fulfill this order:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Items out of stock',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(orderId, OrderStatus.cancelled);
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Orders'),
                  selected: _filterStatus == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterStatus = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...OrderStatus.values.map((s) {
                  final isSel = _filterStatus == s;
                  return ChoiceChip(
                    label: Text(_statusLabel(s)),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterStatus = s);
                      Navigator.pop(ctx);
                    },
                    selectedColor: const Color(0xFF059669),
                    labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w800),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Ready for Pickup';
      case OrderStatus.processing:
        return 'Packing';
      case OrderStatus.shipped:
        return 'Dispatched';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
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
    final code = order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_rounded, color: Color(0xFF059669), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('#$code', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                                Text(order.userName.isNotEmpty ? order.userName : 'Customer', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '₹${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669)),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFF1F5F9)),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('${order.itemCount} items to pack', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF059669)),
                          ],
                        ),
                        OrderStatusBadge(status: order.statusString, isSmall: true),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons bar if pending or processing
              if (order.status == OrderStatus.pending) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUpdating ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Accept & Pack', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: isUpdating ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ] else if (order.status == OrderStatus.processing) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : onReadyForPickup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 16),
                      label: const Text('Mark Packed & Ready for Pickup', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
