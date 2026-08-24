import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class TotalSalesScreen extends StatefulWidget {
  const TotalSalesScreen({super.key});

  @override
  State<TotalSalesScreen> createState() => _TotalSalesScreenState();
}

class _TotalSalesScreenState extends State<TotalSalesScreen> {
  String _selectedPeriod = 'All Time'; // 'Today', 'This Week', 'This Month', 'All Time'
  String _searchQuery = '';
  String _paymentFilter = 'All';

  List<OrderModel> _filterOrdersByPeriod(List<OrderModel> orders) {
    final now = DateTime.now();
    return orders.where((order) {
      if (order.status != OrderStatus.delivered) return false;

      if (_selectedPeriod == 'Today') {
        return order.createdAt.year == now.year &&
            order.createdAt.month == now.month &&
            order.createdAt.day == now.day;
      } else if (_selectedPeriod == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final beginningOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return order.createdAt.isAfter(beginningOfWeek);
      } else if (_selectedPeriod == 'This Month') {
        return order.createdAt.year == now.year && order.createdAt.month == now.month;
      }
      return true;
    }).toList();
  }

  List<OrderModel> _filterOrders(List<OrderModel> deliveredOrders) {
    var list = deliveredOrders;
    if (_searchQuery.isNotEmpty) {
      list = list.where((o) =>
          o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.userName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_paymentFilter != 'All') {
      list = list.where((o) => o.paymentMethod.toLowerCase().contains(_paymentFilter.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Sales & Revenue',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderRepository().getOrdersByDealer(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }

          final allOrders = snapshot.data ?? [];
          final periodDeliveredOrders = _filterOrdersByPeriod(allOrders);
          final displayOrders = _filterOrders(periodDeliveredOrders);

          // Calculations
          final double totalRevenue = periodDeliveredOrders.fold(0.0, (sum, o) => sum + o.total);
          final int totalOrdersCount = periodDeliveredOrders.length;
          final double avgOrderValue = totalOrdersCount > 0 ? totalRevenue / totalOrdersCount : 0.0;
          final int totalItemsSold = periodDeliveredOrders.fold(0, (sum, o) => sum + o.itemCount);

          // Payment breakdowns
          final double upiSales = periodDeliveredOrders
              .where((o) => o.paymentMethod.toLowerCase().contains('upi') || o.paymentMethod.toLowerCase().contains('online'))
              .fold(0.0, (sum, o) => sum + o.total);
          final double codSales = periodDeliveredOrders
              .where((o) => o.paymentMethod.toLowerCase().contains('cash') || o.paymentMethod.toLowerCase().contains('cod'))
              .fold(0.0, (sum, o) => sum + o.total);
          final double walletSales = periodDeliveredOrders
              .where((o) => o.paymentMethod.toLowerCase().contains('wallet'))
              .fold(0.0, (sum, o) => sum + o.total);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emerald Hero Revenue Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Today', 'This Week', 'This Month', 'All Time'].map((period) {
                            final isSel = _selectedPeriod == period;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedPeriod = period),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF34D399) : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    period,
                                    style: TextStyle(
                                      color: isSel ? const Color(0xFF064E3B) : Colors.white,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Total Gross Revenue',
                        style: TextStyle(color: Color(0xFF86EFAC), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${totalRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF34D399)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalOrdersCount Delivered',
                                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4-Card KPI Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.45,
                    children: [
                      _SalesMetricCard(
                        title: 'Delivered Orders',
                        value: totalOrdersCount.toString(),
                        icon: Icons.done_all_rounded,
                        color: const Color(0xFF10B981),
                        subtitle: 'Completed checkouts',
                      ),
                      _SalesMetricCard(
                        title: 'Avg. Order Value',
                        value: '₹${avgOrderValue.toStringAsFixed(0)}',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF3B82F6),
                        subtitle: 'Per completed order',
                      ),
                      _SalesMetricCard(
                        title: 'Units Sold',
                        value: totalItemsSold.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFF59E0B),
                        subtitle: 'Grocery items sold',
                      ),
                      _SalesMetricCard(
                        title: 'Digital Payments',
                        value: '₹${(upiSales + walletSales).toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF8B5CF6),
                        subtitle: 'Prepaid & UPI',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Distribution Breakdown Card
                if (totalRevenue > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Mode Breakdown',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 14),
                          _PaymentBarItem(
                            label: 'UPI & Online Payment',
                            amount: upiSales,
                            total: totalRevenue,
                            color: const Color(0xFF059669),
                            icon: Icons.qr_code_rounded,
                          ),
                          const SizedBox(height: 10),
                          _PaymentBarItem(
                            label: 'Cash on Delivery (COD)',
                            amount: codSales,
                            total: totalRevenue,
                            color: const Color(0xFFF59E0B),
                            icon: Icons.money_rounded,
                          ),
                          const SizedBox(height: 10),
                          _PaymentBarItem(
                            label: 'GroceryGo Wallet',
                            amount: walletSales,
                            total: totalRevenue,
                            color: const Color(0xFF8B5CF6),
                            icon: Icons.wallet_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Transactions Header & Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sales Transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${displayOrders.length} records',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search bar
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by Order ID or Customer Name...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Payment Method Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'UPI', 'Cash', 'Wallet'].map((method) {
                            final isSelected = _paymentFilter == method;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(method == 'All' ? 'All Payments' : method),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _paymentFilter = method),
                                selectedColor: const Color(0xFF059669),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                                side: BorderSide(color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Transactions List
                if (displayOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF059669)),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            periodDeliveredOrders.isEmpty
                                ? 'No Sales in $_selectedPeriod'
                                : 'No Orders Match Search Filter',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Delivered store orders will appear here automatically.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final order = displayOrders[i];
                      final orderCode = order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/order/${order.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '#$orderCode',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              order.paymentMethod,
                                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Customer: ${order.userName.isNotEmpty ? order.userName : 'Shopper'} • ${order.itemCount} items',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppHelpers.formatDate(order.createdAt),
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+₹${order.total.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669)),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: [
                                        Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                        Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SalesMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _SalesMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PaymentBarItem extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final IconData icon;

  const _PaymentBarItem({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (amount / total) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)} (${(percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
