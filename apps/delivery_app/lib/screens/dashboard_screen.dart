import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import 'widgets/daily_goal_card.dart';
import '../widgets/emergency_sos_dialog.dart';
import '../widgets/join_store_fleet_dialog.dart';

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    final delivery = context.watch<DeliveryProvider>();
    final isOnline = delivery.isOnline;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Partner Dashboard',
        showBackButton: false,
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => NotificationBottomSheet.show(context, stream: NotificationRepository().getUserNotifications(user.id, userRole: 'deliveryPartner')),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => EmergencySosDialog.show(context, user: user),
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFFCA5A5)),
            tooltip: 'Partner SOS & Help',
          ),
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171)),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Emerald Partner Duty Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isOnline ? const Color(0xFF34D399) : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                    boxShadow: isOnline
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF34D399).withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isOnline ? 'ON DUTY • Active & Ready' : 'OFF DUTY • Tap to go online',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isOnline ? const Color(0xFF34D399) : Colors.white60,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Duty Toggle Switch Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.white : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isOnline ? 'ONLINE' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isOnline ? const Color(0xFF0B3C26) : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: isOnline,
                              onChanged: (_) => delivery.toggleOnlineStatus(user.id),
                              activeThumbColor: const Color(0xFF059669),
                              activeTrackColor: const Color(0xFFA7F3D0),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.white24,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dedicated Store Affiliation Pill / Join Button
                  StreamBuilder<DealerDriverModel?>(
                    stream: DealerFleetRepository().streamDriverAffiliation(user.phone.replaceAll(RegExp(r'[^0-9]'), '')),
                    builder: (context, affilSnap) {
                      final affil = affilSnap.data;

                      if (affil == null) {
                        return InkWell(
                          onTap: () => JoinStoreFleetDialog.show(context, user),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_link_rounded, color: Color(0xFF34D399), size: 15),
                                SizedBox(width: 6),
                                Text(
                                  '+ Join Store Fleet (Invite Code)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () => context.push('/joined-stores'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 15),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Dedicated Partner • ${affil.dealerName}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Performance Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<OrderModel>>(
                stream: OrderRepository().getOrdersByDeliveryPartner(user.id),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  final activeCount = orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length;
                  final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();
                  
                  final now = DateTime.now();
                  final todayOrders = deliveredOrders.where((o) {
                    final d = o.deliveredAt ?? o.createdAt;
                    return d.year == now.year && d.month == now.month && d.day == now.day;
                  }).toList();

                  double todayEarned = 0.0;
                  for (final o in todayOrders) {
                    todayEarned += o.deliveryFee > 0 ? o.deliveryFee : 45.0;
                  }

                  // If user has recorded earnings
                  if (todayEarned == 0.0 && todayOrders.isEmpty && user.totalDeliveries > 0) {
                    todayEarned = (user.totalDeliveries * 45.0) > 450 ? 450.0 : (user.totalDeliveries * 45.0);
                  }

                  final deliveredCount = todayOrders.isNotEmpty ? todayOrders.length : (deliveredOrders.isNotEmpty ? deliveredOrders.length : user.totalDeliveries);

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: "Today's Earnings",
                              value: '₹${todayEarned.toStringAsFixed(0)}',
                              subtitle: '$deliveredCount Trips Done',
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFF10B981),
                              onTap: () => context.push('/earnings'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Active Trips',
                              value: '$activeCount',
                              subtitle: activeCount > 0 ? 'Action Needed' : 'Idle',
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFF3B82F6),
                              onTap: () => context.push('/active-deliveries'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DailyGoalCard(
                        currentEarnings: todayEarned > 0 ? todayEarned : user.totalEarnings,
                        completedOrders: deliveredCount,
                      ),
                      const SizedBox(height: 14),
                      // Morning Jar Drops Action Card
                      InkWell(
                        onTap: () => context.push('/morning-drops'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Morning Jar Drops (5:30 AM)',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'View scheduled water subscription route stops',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // New Delivery Requests Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Delivery Requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  if (isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.radar_rounded, size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Scanning Near You',
                            style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Offline vs Requests Stream State
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: !isOnline
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_off_rounded, size: 36, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'You are currently Offline',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Switch your duty status to Online at the top banner to start receiving high-paying order requests near your location.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => delivery.toggleOnlineStatus(user.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                            label: const Text('Go Online Now', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<List<OrderModel>>(
                      stream: delivery.getNewRequests(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF059669))));
                        }
                        final requests = snapshot.data ?? [];
                        if (requests.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF059669)),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No Pending Requests Right Now',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Stay online! New customer orders will pop up here in real-time.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
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
                              orderId: o.id.length >= 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase(),
                              distance: '2.4 km',
                              estTime: '12 min delivery',
                              pickup: o.dealerName ?? 'GroceryGo Darkstore #12',
                              dropoff: o.deliveryAddress.fullAddress,
                              earnings: '₹45',
                              total: '₹${o.total.toStringAsFixed(0)}',
                              itemCount: o.itemCount,
                              onAccept: () {
                                context.read<DeliveryProvider>().acceptDelivery(
                                      orderId: o.id,
                                      partnerId: user.id,
                                      partnerName: user.name,
                                      partnerPhone: user.phone,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Accepted Delivery #${o.id.substring(0, 8).toUpperCase()}!'),
                                    backgroundColor: const Color(0xFF059669),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              onReject: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Order request passed'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String orderId;
  final String distance;
  final String estTime;
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
    required this.estTime,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#$orderId',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        estTime,
                        style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$earnings Pay',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Route Timeline Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.store_rounded, color: Color(0xFF059669), size: 16),
                        ),
                        Container(
                          height: 32,
                          width: 2,
                          color: const Color(0xFFCBD5E1),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup Store
                          const Text(
                            'PICKUP STORE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pickup,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 18),

                          // Dropoff Customer
                          const Text(
                            'DELIVER TO CUSTOMER',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dropoff,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Order Metadata Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            '$itemCount Items • $total Order Value',
                            style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFF059669).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
