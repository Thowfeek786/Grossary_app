import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/management_provider.dart';
import '../../widgets/admin_drawer.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  OrderStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final management = context.watch<AdminManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Order Management',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, size: 20, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            ),
            tooltip: 'Export Orders (CSV/PDF)',
            onPressed: () async {
              final orders = await OrderRepository().getAllOrders().first;
              final csv = ExportService.generateOrdersCsv(orders);
              if (context.mounted) {
                ExportService.showExportDialog(context, title: 'Orders List', csvContent: csv, pdfSummaryTitle: 'Orders Statement Report');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: management.getOrders(status: _filterStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoader();
                }
                if (snapshot.hasError) {
                  return AppErrorWidget(message: snapshot.error.toString());
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Orders Found',
                    subtitle: 'Orders matching the selected filter will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return _OrderCard(
                      order: o,
                      onUpdateStatus: () => _showUpdateStatusModal(context, o, management),
                      onAssignDelivery: () => _showAssignDeliveryModal(context, o, management),
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

  Widget _buildFilterBar() {
    final filters = <String, OrderStatus?>{
      'All': null,
      'Pending': OrderStatus.pending,
      'Accepted': OrderStatus.accepted,
      'Processing': OrderStatus.processing,
      'Shipped': OrderStatus.shipped,
      'Delivered': OrderStatus.delivered,
      'Cancelled': OrderStatus.cancelled,
    };

    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: filters.entries.map((entry) {
          final isSelected = _filterStatus == entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterTag(
              label: entry.key,
              isSelected: isSelected,
              onTap: () => setState(() => _filterStatus = entry.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showUpdateStatusModal(
      BuildContext context, OrderModel order, AdminManagementProvider management) async {
    final statuses = OrderStatus.values.where((s) => s != order.status).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Order Status',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Order #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: statuses.map((status) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _statusIcon(status),
                    title: Text(
                      _statusLabel(status),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await management.updateOrderStatus(order.id, status);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Order status updated to ${_statusLabel(status)}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignDeliveryModal(
      BuildContext context, OrderModel order, AdminManagementProvider management) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              const Text(
                'Assign Delivery Partner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: UserRepository().getUsersByRole(UserRole.deliveryPartner),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppLoader();
                    }
                    final partners = snapshot.data ?? [];
                    if (partners.isEmpty) {
                      return const EmptyState(
                        icon: Icons.person_off_outlined,
                        title: 'No Delivery Partners',
                        subtitle: 'No delivery partners registered yet.',
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      itemCount: partners.length,
                      itemBuilder: (_, i) {
                        final p = partners[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primarySurface,
                            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                            child: p.photoUrl == null
                                ? Text(p.name.isNotEmpty ? p.name[0] : 'P',
                                    style: const TextStyle(
                                        color: AppColors.primary, fontWeight: FontWeight.w700))
                                : null,
                          ),
                          title: Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                              const SizedBox(width: 4),
                              Text('${p.rating ?? 4.8}  •  ${p.totalDeliveries} deliveries',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            await management.assignDeliveryPartner(
                              orderId: order.id,
                              partnerId: p.id,
                              partnerName: p.name,
                              partnerPhone: p.phone,
                            );
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('${p.name} assigned to Order #${order.id.substring(0, 6)}'),
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

  Widget _statusIcon(OrderStatus status) {
    final data = {
      OrderStatus.pending: (Icons.hourglass_empty_rounded, AppColors.warning),
      OrderStatus.accepted: (Icons.check_circle_outline_rounded, AppColors.info),
      OrderStatus.processing: (Icons.inventory_2_rounded, AppColors.primary),
      OrderStatus.shipped: (Icons.local_shipping_rounded, AppColors.info),
      OrderStatus.outForDelivery: (Icons.directions_bike_rounded, AppColors.primary),
      OrderStatus.delivered: (Icons.done_all_rounded, AppColors.success),
      OrderStatus.cancelled: (Icons.cancel_outlined, AppColors.error),
    };
    final (icon, color) = data[status]!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.accepted: return 'Accepted';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onUpdateStatus;
  final VoidCallback onAssignDelivery;

  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onAssignDelivery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/management/orders/${order.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              AppHelpers.formatDateTime(order.createdAt),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    OrderStatusBadge(status: order.status.name, isSmall: true),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                // Customer Details Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      child: Text(
                        order.userName.isNotEmpty ? order.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF3B82F6)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          if (order.userPhone.isNotEmpty)
                            Text(order.userPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
                        ),
                        Text(
                          '${order.itemCount} items',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order.deliveryAddress.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress.fullAddress,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.deliveryPartnerName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining_rounded, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          'Driver: ${order.deliveryPartnerName}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
                if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onUpdateStatus,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: order.status == OrderStatus.accepted || order.status == OrderStatus.processing
                              ? onAssignDelivery
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            order.deliveryPartnerName == null ? 'Assign Driver' : 'Reassign',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
