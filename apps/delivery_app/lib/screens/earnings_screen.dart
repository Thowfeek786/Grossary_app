import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class EarningHistoryScreen extends StatefulWidget {
  const EarningHistoryScreen({super.key});

  @override
  State<EarningHistoryScreen> createState() => _EarningHistoryScreenState();
}

class _EarningHistoryScreenState extends State<EarningHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderRepository _orderRepo = OrderRepository();
  final PayoutRepository _payoutRepo = PayoutRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Earnings & Payouts',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderRepo.getOrdersByDeliveryPartner(user.id),
        builder: (context, ordersSnap) {
          final allOrders = ordersSnap.data ?? [];
          final deliveredOrders = allOrders.where((o) => o.status == OrderStatus.delivered).toList();

          // Calculate dynamic live delivered earnings
          double dynamicEarnings = 0.0;
          for (final o in deliveredOrders) {
            dynamicEarnings += o.deliveryFee > 0 ? o.deliveryFee : 45.0;
          }
          final totalEarnings = user.totalEarnings > dynamicEarnings ? user.totalEarnings : dynamicEarnings;
          final totalCompleted = deliveredOrders.length > user.totalDeliveries ? deliveredOrders.length : user.totalDeliveries;

          return NestedScrollView(
            headerSliverBuilder: (ctx, innerScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Emerald Balance Hero Banner
                    _buildBalanceCard(context, totalEarnings, totalCompleted),
                    const SizedBox(height: 16),

                    // Segmented Tabs Header
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        labelColor: const Color(0xFF0F172A),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.two_wheeler_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text('Trip Earnings (${deliveredOrders.length})'),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, size: 16),
                                SizedBox(width: 6),
                                Text('Withdrawals'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Real-time Delivered Trips
                _buildDeliveredTripsList(deliveredOrders),

                // Tab 2: Real-time Payout Requests & Withdrawals
                _buildPayoutRequestsList(user.id),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double totalEarnings, int totalCompleted) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3C26).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PARTNER EARNINGS',
                    style: TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lifetime delivered earnings',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/withdraw'),
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0B3C26),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${totalEarnings.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickMetric('Completed Trips', '$totalCompleted orders'),
                Container(width: 1, height: 24, color: Colors.white24),
                _buildQuickMetric(
                  'Avg. / Delivery',
                  totalCompleted > 0 ? '₹${(totalEarnings / totalCompleted).toStringAsFixed(0)}' : '₹45',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildDeliveredTripsList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.two_wheeler_rounded, size: 48, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 16),
              const Text('No Delivered Trips Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              const Text('Complete pickup and delivery orders to see your trip payouts breakdown here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final order = orders[i];
        final fee = order.deliveryFee > 0 ? order.deliveryFee : 45.0;
        final shortId = order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase();
        final formattedDate = order.deliveredAt != null
            ? DateFormat('MMM dd, yyyy • hh:mm a').format(order.deliveredAt!)
            : DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${order.itemCount} items', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.deliveryAddress.addressLine1.isNotEmpty ? order.deliveryAddress.addressLine1 : (order.userName.isNotEmpty ? order.userName : 'Delivered'),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(formattedDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+₹${fee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669))),
                  const Text('Delivery Fee', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutRequestsList(String partnerId) {
    return StreamBuilder<List<PayoutRequestModel>>(
      stream: _payoutRepo.getPartnerPayoutRequests(partnerId),
      builder: (context, snapshot) {
        final payouts = snapshot.data ?? [];

        if (payouts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Withdrawal Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  const Text('When you request a payout, your bank/UPI transfer records will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/withdraw'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort descending by createdAt
        payouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: payouts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final p = payouts[i];
            final status = p.status.toLowerCase();
            final isApproved = status == 'approved';
            final isPending = status == 'pending';

            final statusColor = isApproved ? const Color(0xFF059669) : (isPending ? const Color(0xFFD97706) : const Color(0xFFEF4444));
            final statusBg = isApproved ? const Color(0xFF10B981).withValues(alpha: 0.12) : (isPending ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12));

            final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(p.createdAt);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isApproved ? Icons.check_circle_rounded : (isPending ? Icons.pending_actions_rounded : Icons.cancel_rounded),
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.status.toUpperCase(),
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.payoutMethod == 'upi' && p.upiId != null && p.upiId!.isNotEmpty
                              ? 'UPI: ${p.upiId}'
                              : (p.bankName.isNotEmpty ? '${p.bankName} • A/C: ••••${p.accountNumber.length > 4 ? p.accountNumber.substring(p.accountNumber.length - 4) : p.accountNumber}' : 'Direct Bank Payout'),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(formattedDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
