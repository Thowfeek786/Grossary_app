import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _orderRepo = OrderRepository();
  final _userRepo = UserRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Sticky header
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            title: const Text('Analytics & Insights',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Export Report (CSV/PDF)',
                onPressed: () async {
                  final orders = await _orderRepo.getAllOrders().first;
                  final csv = ExportService.generateOrdersCsv(orders);
                  if (context.mounted) {
                    ExportService.showExportDialog(context, title: 'Analytics & Revenue', csvContent: csv, pdfSummaryTitle: 'Platform Analytics Report');
                  }
                },
              ),
            ],
          ),

          // Revenue cards
          SliverToBoxAdapter(child: _buildRevenueCards()),

          // Bar Chart — Orders by Day
          SliverToBoxAdapter(child: _buildBarChartSection()),

          // Pie Chart — Order Status Breakdown
          SliverToBoxAdapter(child: _buildPieChartSection()),

          // Line Chart — Revenue Trend
          SliverToBoxAdapter(child: _buildLineChartSection()),

          // Top Products
          SliverToBoxAdapter(child: _buildTopProducts()),

          // User Growth
          SliverToBoxAdapter(child: _buildUserBreakdown()),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─── Revenue Summary Cards ───
  Widget _buildRevenueCards() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
        final startOfMonth = DateTime(now.year, now.month, 1);

        final delivered = orders.where((o) => o.status == OrderStatus.delivered);
        final todayRev = delivered.where((o) => o.createdAt.isAfter(startOfToday)).fold(0.0, (s, o) => s + o.total);
        final weekRev = delivered.where((o) => o.createdAt.isAfter(startOfWeek)).fold(0.0, (s, o) => s + o.total);
        final monthRev = delivered.where((o) => o.createdAt.isAfter(startOfMonth)).fold(0.0, (s, o) => s + o.total);
        final totalRev = delivered.fold(0.0, (s, o) => s + o.total);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Revenue Overview', const Color(0xFF10B981)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _revCard('Today', todayRev, const Color(0xFF6366F1))),
                const SizedBox(width: 10),
                Expanded(child: _revCard('This Week', weekRev, const Color(0xFF3B82F6))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _revCard('This Month', monthRev, const Color(0xFF10B981))),
                const SizedBox(width: 10),
                Expanded(child: _revCard('All Time', totalRev, const Color(0xFFF59E0B))),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _revCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
          child: Icon(Icons.trending_up_rounded, color: color, size: 14),
        ),
        const SizedBox(height: 8),
        Text('₹${_fmtRev(amount)}',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── Bar Chart: Orders per Day (last 7 days) ───
  Widget _buildBarChartSection() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        final now = DateTime.now();
        final dayLabels = <String>[];
        final dayCounts = <double>[];

        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          dayLabels.add(_shortDay(day));
          final count = orders.where((o) {
            return o.createdAt.year == day.year &&
                o.createdAt.month == day.month &&
                o.createdAt.day == day.day;
          }).length;
          dayCounts.add(count.toDouble());
        }

        final maxY = (dayCounts.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chartTitle('Orders — Last 7 Days', Icons.bar_chart_rounded, const Color(0xFF6366F1)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1E293B),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${dayLabels[group.x.toInt()]}\n${rod.toY.toInt()} orders',
                              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(dayLabels[val.toInt()],
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                        getDrawingHorizontalLine: (val) => FlLine(color: AppColors.grey200, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: dayCounts[i],
                              width: 18,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Pie Chart: Order Status Distribution ───
  Widget _buildPieChartSection() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _emptyChartPlaceholder('No order data available'),
          );
        }

        final statusMap = <OrderStatus, int>{};
        for (final o in orders) {
          statusMap[o.status] = (statusMap[o.status] ?? 0) + 1;
        }

        final statusColors = {
          OrderStatus.pending: const Color(0xFFF59E0B),
          OrderStatus.accepted: const Color(0xFF3B82F6),
          OrderStatus.processing: const Color(0xFF8B5CF6),
          OrderStatus.shipped: const Color(0xFF06B6D4),
          OrderStatus.outForDelivery: const Color(0xFF14B8A6),
          OrderStatus.delivered: const Color(0xFF10B981),
          OrderStatus.cancelled: const Color(0xFFEF4444),
        };

        final statusLabels = {
          OrderStatus.pending: 'Pending',
          OrderStatus.accepted: 'Accepted',
          OrderStatus.processing: 'Processing',
          OrderStatus.shipped: 'Shipped',
          OrderStatus.outForDelivery: 'Out for Delivery',
          OrderStatus.delivered: 'Delivered',
          OrderStatus.cancelled: 'Cancelled',
        };

        final sections = statusMap.entries.map((e) {
          final pct = (e.value / orders.length * 100);
          return PieChartSectionData(
            value: e.value.toDouble(),
            color: statusColors[e.key] ?? Colors.grey,
            radius: 50,
            title: '${pct.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
          );
        }).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chartTitle('Order Status Distribution', Icons.pie_chart_rounded, const Color(0xFF10B981)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 36,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: statusMap.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColors[e.key],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      statusLabels[e.key] ?? e.key.name,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    e.value.toString(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Line Chart: Revenue Trend (last 7 days) ───
  Widget _buildLineChartSection() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        final now = DateTime.now();
        final dayLabels = <String>[];
        final dayRevenue = <double>[];

        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          dayLabels.add(_shortDay(day));
          final revenue = orders
              .where((o) =>
                  o.status == OrderStatus.delivered &&
                  o.createdAt.year == day.year &&
                  o.createdAt.month == day.month &&
                  o.createdAt.day == day.day)
              .fold(0.0, (s, o) => s + o.total);
          dayRevenue.add(revenue);
        }

        final maxY = dayRevenue.isEmpty
            ? 1000.0
            : (dayRevenue.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chartTitle('Revenue Trend — 7 Days', Icons.show_chart_rounded, const Color(0xFF3B82F6)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1E293B),
                          getTooltipItems: (spots) => spots.map((s) {
                            return LineTooltipItem(
                              '${dayLabels[s.x.toInt()]}\n₹${_fmtRev(s.y)}',
                              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            );
                          }).toList(),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                        getDrawingHorizontalLine: (val) => FlLine(color: AppColors.grey200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (val, meta) {
                              if (val.toInt() >= dayLabels.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(dayLabels[val.toInt()],
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (val, meta) => Text(
                              '₹${_fmtRev(val)}',
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: maxY > 0 ? maxY : 1000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(7, (i) => FlSpot(i.toDouble(), dayRevenue[i])),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF3B82F6),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withOpacity(0.15),
                                const Color(0xFF3B82F6).withOpacity(0.01),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 400),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Top Products ───
  Widget _buildTopProducts() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.getAllOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        final productSales = <String, _ProductSale>{};

        for (final o in orders.where((o) => o.status == OrderStatus.delivered)) {
          for (final item in o.items) {
            final existing = productSales[item.productId];
            if (existing != null) {
              productSales[item.productId] = _ProductSale(
                item.productName, existing.qty + item.quantity, existing.revenue + (item.price * item.quantity));
            } else {
              productSales[item.productId] = _ProductSale(
                item.productName, item.quantity, item.price * item.quantity);
            }
          }
        }

        final sorted = productSales.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
        final top5 = sorted.take(5).toList();

        if (top5.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _emptyChartPlaceholder('No sales data yet'),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chartTitle('Top Products', Icons.star_rounded, const Color(0xFFF59E0B)),
                const SizedBox(height: 14),
                ...top5.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final maxRev = top5.first.revenue;
                  final pct = maxRev > 0 ? p.revenue / maxRev : 0.0;
                  final colors = [
                    const Color(0xFF6366F1),
                    const Color(0xFF3B82F6),
                    const Color(0xFF10B981),
                    const Color(0xFFF59E0B),
                    const Color(0xFFEF4444),
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: colors[i].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors[i])),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Text('₹${_fmtRev(p.revenue)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors[i])),
                        ]),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.grey100,
                            valueColor: AlwaysStoppedAnimation(colors[i]),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── User Breakdown ───
  Widget _buildUserBreakdown() {
    return StreamBuilder<List<UserModel>>(
      stream: _userRepo.getAllUsers(),
      builder: (context, snap) {
        final users = snap.data ?? [];
        final customers = users.where((u) => u.role == UserRole.customer).length;
        final dealers = users.where((u) => u.role == UserRole.dealer).length;
        final delivery = users.where((u) => u.role == UserRole.deliveryPartner).length;
        final admins = users.where((u) => u.role == UserRole.admin).length;
        final total = users.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chartTitle('User Breakdown', Icons.people_rounded, const Color(0xFF8B5CF6)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _userStatTile('Customers', customers, total, const Color(0xFF10B981))),
                  const SizedBox(width: 10),
                  Expanded(child: _userStatTile('Dealers', dealers, total, const Color(0xFFF59E0B))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _userStatTile('Delivery', delivery, total, const Color(0xFF3B82F6))),
                  const SizedBox(width: 10),
                  Expanded(child: _userStatTile('Admins', admins, total, const Color(0xFFEF4444))),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _userStatTile(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color), minHeight: 4),
        ),
      ]),
    );
  }

  // ─── Helpers ───

  Widget _sectionHeader(String text, Color accent) {
    return Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _chartTitle(String text, IconData icon, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _emptyChartPlaceholder(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Center(child: Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
    );
  }

  String _shortDay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String _fmtRev(double r) {
    if (r >= 100000) return '${(r / 100000).toStringAsFixed(1)}L';
    if (r >= 1000) return '${(r / 1000).toStringAsFixed(1)}K';
    return r.toStringAsFixed(0);
  }
}

class _ProductSale {
  final String name;
  final int qty;
  final double revenue;
  const _ProductSale(this.name, this.qty, this.revenue);
}
