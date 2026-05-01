import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final delivery = context.watch<DeliveryProvider>();
    final isOnline = delivery.isOnline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Partner Dashboard',
        showBackButton: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isOnline ? AppColors.success : AppColors.grey400,
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: (_) => delivery.toggleOnlineStatus(),
                  activeColor: AppColors.success,
                  activeTrackColor: AppColors.success.withOpacity(0.3),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Partner greeting banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.grey300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                fontSize: 22),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppColors.white)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnline
                                ? '● Looking for orders...'
                                : '● You are offline',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats row
            StreamBuilder<List<OrderModel>>(
              stream: delivery.getActiveDeliveries(user.id),
              builder: (context, snapshot) {
                final orders = snapshot.data ?? [];
                final active = orders
                    .where((o) =>
                        o.status != OrderStatus.delivered &&
                        o.status != OrderStatus.cancelled)
                    .length;
                final delivered =
                    orders.where((o) => o.status == OrderStatus.delivered).length;
                final earned = delivered * 45.0;

                return Row(
                  children: [
                    Expanded(
                        child: StatCard(
                      title: "Today's Earnings",
                      value: '₹${earned.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.success,
                    )),
                    const SizedBox(width: 16),
                    Expanded(
                        child: StatCard(
                      title: 'Active Orders',
                      value: active.toString(),
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push('/active-deliveries'),
                    )),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('New Delivery Requests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                if (!isOnline)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Go online to see requests',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 48, color: AppColors.grey300),
                      SizedBox(height: 12),
                      Text('You are currently offline',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      SizedBox(height: 4),
                      Text('Toggle Online to receive new delivery requests',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              StreamBuilder<List<OrderModel>>(
                stream: delivery.getNewRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }
                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 48, color: AppColors.success),
                            SizedBox(height: 12),
                            Text('No new requests!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text('New orders will appear here automatically',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final o = requests[index];
                      return _DeliveryCard(
                        orderId: o.id.substring(0, 8).toUpperCase(),
                        distance: '2.4 km',
                        pickup: o.dealerName ?? 'Local Store',
                        dropoff: o.deliveryAddress.fullAddress,
                        earnings: '₹45',
                        total: '₹${o.total.toStringAsFixed(0)}',
                        itemCount: o.itemCount,
                        onAccept: () =>
                            context.read<DeliveryProvider>().acceptDelivery(
                                  orderId: o.id,
                                  partnerId: user.id,
                                  partnerName: user.name,
                                  partnerPhone: user.phone,
                                ),
                        onReject: () {},
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String orderId;
  final String distance;
  final String pickup;
  final String dropoff;
  final String earnings;
  final String total;
  final int itemCount;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _DeliveryCard({
    required this.orderId,
    required this.distance,
    required this.pickup,
    required this.dropoff,
    required this.earnings,
    required this.total,
    required this.itemCount,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#$orderId',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(earnings,
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Text(distance,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.store_rounded,
                      color: AppColors.primary, size: 20),
                  Container(
                      height: 30,
                      width: 2,
                      color: AppColors.grey300,
                      margin: const EdgeInsets.symmetric(vertical: 4)),
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.error, size: 20),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pickup,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 30),
                    Text(dropoff,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('$itemCount items • Order value $total',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: AppButton(
                      label: 'Reject',
                      variant: AppButtonVariant.outlined,
                      onTap: onReject)),
              const SizedBox(width: 12),
              Expanded(
                  child: AppButton(label: 'Accept', onTap: onAccept)),
            ],
          ),
        ],
      ),
    );
  }
}
