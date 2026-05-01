import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/management_provider.dart';

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
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Order Management'),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            ...statuses.map((status) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _statusIcon(status),
                  title: Text(
                    _statusLabel(status),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await management.updateOrderStatus(order.id, status);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order status updated to ${_statusLabel(status)}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                )),
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
                            await management.assignDeliveryPartner(
                              orderId: order.id,
                              partnerId: p.id,
                              partnerName: p.name,
                              partnerPhone: p.phone,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
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
        color: color.withOpacity(0.1),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  Text(
                    AppHelpers.formatDateTime(order.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              OrderStatusBadge(status: order.status.name, isSmall: true),
            ],
          ),
          const Divider(height: 20),
          // Customer Info
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(order.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(order.userPhone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.deliveryAddress.fullAddress,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.itemCount} items',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                '₹${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 18),
              ),
            ],
          ),
          if (order.deliveryPartnerName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.delivery_dining_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Assigned: ${order.deliveryPartnerName}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Update Status',
                    variant: AppButtonVariant.outlined,
                    onTap: onUpdateStatus,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: order.deliveryPartnerName == null ? 'Assign Delivery' : 'Reassign',
                    onTap: order.status == OrderStatus.accepted ||
                            order.status == OrderStatus.processing
                        ? onAssignDelivery
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
