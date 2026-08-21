import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../widgets/admin_drawer.dart';
import 'partner_details_screen.dart';

class PartnerEarningsScreen extends StatefulWidget {
  const PartnerEarningsScreen({super.key});

  @override
  State<PartnerEarningsScreen> createState() => _PartnerEarningsScreenState();
}

class _PartnerEarningsScreenState extends State<PartnerEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepo = UserRepository();
  final OrderRepository _orderRepo = OrderRepository();

  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Online', 'Offline'
  String _sortBy = 'Earnings'; // 'Earnings', 'Orders', 'Name'

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

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final text = Uri.encodeComponent('Hello $name, this is GroceryGo Admin operations.');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  List<UserModel> _filterAndSortPartners(
    List<UserModel> partners,
    Map<String, double> earningsMap,
    Map<String, int> ordersMap,
  ) {
    var list = partners.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.shopName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          p.phone.contains(_searchQuery);

      if (!nameMatches) return false;

      if (_statusFilter == 'Online') {
        return p.isOnline == true;
      } else if (_statusFilter == 'Offline') {
        return p.isOnline == false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (_sortBy == 'Earnings') {
        final double earningsA = (earningsMap[a.id] ?? 0.0) > 0 ? earningsMap[a.id]! : a.totalEarnings;
        final double earningsB = (earningsMap[b.id] ?? 0.0) > 0 ? earningsMap[b.id]! : b.totalEarnings;
        return earningsB.compareTo(earningsA);
      } else if (_sortBy == 'Orders') {
        final int ordersA = (ordersMap[a.id] ?? 0) > 0 ? ordersMap[a.id]! : a.totalDeliveries;
        final int ordersB = (ordersMap[b.id] ?? 0) > 0 ? ordersMap[b.id]! : b.totalDeliveries;
        return ordersB.compareTo(ordersA);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Partner & Dealer Earnings',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderRepo.getAllOrders(status: OrderStatus.delivered),
        builder: (context, ordersSnap) {
          final deliveredOrders = ordersSnap.data ?? [];

          // Compute aggregated delivered sales per dealer
          final Map<String, double> dealerSalesMap = {};
          final Map<String, int> dealerOrdersCountMap = {};
          double totalDealerGrossSales = 0.0;

          // Compute aggregated delivery run fees per delivery partner
          final Map<String, double> partnerEarningsMap = {};
          final Map<String, int> partnerOrdersCountMap = {};
          double totalPartnerPayouts = 0.0;

          for (final order in deliveredOrders) {
            if (order.dealerId != null && order.dealerId!.isNotEmpty) {
              dealerSalesMap[order.dealerId!] = (dealerSalesMap[order.dealerId!] ?? 0.0) + order.total;
              dealerOrdersCountMap[order.dealerId!] = (dealerOrdersCountMap[order.dealerId!] ?? 0) + 1;
              totalDealerGrossSales += order.total;
            }

            if (order.deliveryPartnerId != null && order.deliveryPartnerId!.isNotEmpty) {
              final fee = order.deliveryFee > 0 ? order.deliveryFee : 40.0;
              partnerEarningsMap[order.deliveryPartnerId!] = (partnerEarningsMap[order.deliveryPartnerId!] ?? 0.0) + fee;
              partnerOrdersCountMap[order.deliveryPartnerId!] = (partnerOrdersCountMap[order.deliveryPartnerId!] ?? 0) + 1;
              totalPartnerPayouts += fee;
            }
          }

          return StreamBuilder<List<UserModel>>(
            stream: _userRepo.getUsersByRole(UserRole.dealer),
            builder: (context, dealersSnap) {
              final allDealers = dealersSnap.data ?? [];
              final onlineDealersCount = allDealers.where((d) => d.isOnline).length;

              return StreamBuilder<List<UserModel>>(
                stream: _userRepo.getUsersByRole(UserRole.deliveryPartner),
                builder: (context, partnersSnap) {
                  final allPartners = partnersSnap.data ?? [];
                  final onlinePartnersCount = allPartners.where((p) => p.isOnline).length;

                  final filteredDealers = _filterAndSortPartners(allDealers, dealerSalesMap, dealerOrdersCountMap);
                  final filteredPartners = _filterAndSortPartners(allPartners, partnerEarningsMap, partnerOrdersCountMap);

                  return NestedScrollView(
                    headerSliverBuilder: (ctx, innerScrolled) => [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Dark Slate Hero KPI Summary Header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Earnings & Duty Intelligence',
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Live revenue & online operational tracking',
                                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF34D399)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.circle, color: Color(0xFF34D399), size: 10),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${onlineDealersCount + onlinePartnersCount} Online',
                                              style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w800, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // 2 Major Metric Hero Cards
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TopKpiCard(
                                          title: 'Dealer Gross Sales',
                                          value: '₹${totalDealerGrossSales.toStringAsFixed(0)}',
                                          subtitle: '$onlineDealersCount/${allDealers.length} stores open',
                                          color: const Color(0xFF10B981),
                                          icon: Icons.storefront_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _TopKpiCard(
                                          title: 'Partner Delivery Fees',
                                          value: '₹${totalPartnerPayouts.toStringAsFixed(0)}',
                                          subtitle: '$onlinePartnersCount/${allPartners.length} riders on duty',
                                          color: const Color(0xFF3B82F6),
                                          icon: Icons.two_wheeler_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Search & Filters Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  TextField(
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                    decoration: InputDecoration(
                                      hintText: 'Search by Store, Partner Name, Phone...',
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

                                  Row(
                                    children: [
                                      // Status Filter Chips
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: ['All', 'Online', 'Offline'].map((status) {
                                              final isSel = _statusFilter == status;
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: ChoiceChip(
                                                  label: Text(status == 'All' ? 'All Status' : status),
                                                  selected: isSel,
                                                  onSelected: (_) => setState(() => _statusFilter = status),
                                                  selectedColor: const Color(0xFF0F172A),
                                                  backgroundColor: Colors.white,
                                                  labelStyle: TextStyle(
                                                    color: isSel ? Colors.white : const Color(0xFF475569),
                                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                                    fontSize: 11.5,
                                                  ),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),

                                      // Sort Dropdown
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _sortBy,
                                            icon: const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
                                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700),
                                            items: ['Earnings', 'Orders', 'Name'].map((s) => DropdownMenuItem(value: s, child: Text('Sort: $s'))).toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _sortBy = val);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Tab Bar
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
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
                                        const Icon(Icons.store_rounded, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Dealers (${filteredDealers.length})'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.two_wheeler_rounded, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Delivery (${filteredPartners.length})'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        // Dealers List Tab
                        _buildDealersList(filteredDealers, dealerSalesMap, dealerOrdersCountMap),

                        // Delivery Partners List Tab
                        _buildDeliveryPartnersList(filteredPartners, partnerEarningsMap, partnerOrdersCountMap),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDealersList(
    List<UserModel> dealers,
    Map<String, double> salesMap,
    Map<String, int> ordersMap,
  ) {
    if (dealers.isEmpty) {
      return _buildEmptyState('No Vendors Found', 'No store profiles match your active search or status filter.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: dealers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final dealer = dealers[i];
        final sales = (salesMap[dealer.id] ?? 0.0) > 0 ? salesMap[dealer.id]! : dealer.totalEarnings;
        final ordersCount = (ordersMap[dealer.id] ?? 0) > 0 ? ordersMap[dealer.id]! : dealer.totalDeliveries;
        final isOpen = dealer.isOnline;
        final hasImage = dealer.photoUrl != null && dealer.photoUrl!.isNotEmpty;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          elevation: 0,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartnerDetailsScreen(user: dealer)),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dealer Profile Image or Avatar
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: ClipOval(
                              child: hasImage
                                  ? CachedNetworkImage(
                                      imageUrl: dealer.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => _buildDealerFallbackAvatar(dealer),
                                    )
                                  : _buildDealerFallbackAvatar(dealer),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dealer.shopName ?? dealer.name,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Live Status Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOpen ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isOpen ? const Color(0xFF34D399) : const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 8),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOpen ? 'STORE OPEN' : 'STORE CLOSED',
                                        style: TextStyle(
                                          color: isOpen ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Owner: ${dealer.name} • ${dealer.phone}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                            if (dealer.shopAddress != null && dealer.shopAddress!.isNotEmpty)
                              Text(
                                dealer.shopAddress!,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gross Revenue', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text('₹${sales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Delivered Orders', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text('$ordersCount orders', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Row(
                        children: [
                          if (dealer.phone.isNotEmpty) ...[
                            IconButton(
                              onPressed: () => _makeCall(dealer.phone),
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF059669), size: 20),
                              tooltip: 'Call Dealer',
                            ),
                            IconButton(
                              onPressed: () => _openWhatsApp(dealer.phone, dealer.name),
                              icon: const Icon(Icons.chat_rounded, color: Color(0xFF10B981), size: 20),
                              tooltip: 'WhatsApp Dealer',
                            ),
                          ],
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
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
    );
  }

  Widget _buildDealerFallbackAvatar(UserModel dealer) {
    final initial = dealer.name.isNotEmpty ? dealer.name[0].toUpperCase() : 'D';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669)),
      ),
    );
  }

  Widget _buildDeliveryPartnersList(
    List<UserModel> partners,
    Map<String, double> earningsMap,
    Map<String, int> ordersMap,
  ) {
    if (partners.isEmpty) {
      return _buildEmptyState('No Delivery Partners Found', 'No riders match your active search or status filter.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: partners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final partner = partners[i];
        final earnings = (earningsMap[partner.id] ?? 0.0) > 0 ? earningsMap[partner.id]! : partner.totalEarnings;
        final deliveriesCount = (ordersMap[partner.id] ?? 0) > 0 ? ordersMap[partner.id]! : partner.totalDeliveries;
        final isOnDuty = partner.isOnline;
        final hasImage = partner.photoUrl != null && partner.photoUrl!.isNotEmpty;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          elevation: 0,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartnerDetailsScreen(user: partner)),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Partner Profile Image or Avatar
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: ClipOval(
                              child: hasImage
                                  ? CachedNetworkImage(
                                      imageUrl: partner.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => _buildPartnerFallbackAvatar(partner),
                                    )
                                  : _buildPartnerFallbackAvatar(partner),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: isOnDuty ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    partner.name,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Live Status Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOnDuty ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isOnDuty ? const Color(0xFF34D399) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: isOnDuty ? const Color(0xFF10B981) : const Color(0xFF64748B), size: 8),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                                        style: TextStyle(
                                          color: isOnDuty ? const Color(0xFF065F46) : const Color(0xFF475569),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: ${partner.phone} • Vehicle: ${partner.vehicleType ?? 'Bike'}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                            if (partner.rating != null && partner.rating! > 0)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                  const SizedBox(width: 4),
                                  Text('${partner.rating!.toStringAsFixed(1)} Rating', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.w800)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Earnings', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text('₹${earnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Total Deliveries', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Text('$deliveriesCount trips', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Row(
                        children: [
                          if (partner.phone.isNotEmpty) ...[
                            IconButton(
                              onPressed: () => _makeCall(partner.phone),
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 20),
                              tooltip: 'Call Driver',
                            ),
                            IconButton(
                              onPressed: () => _openWhatsApp(partner.phone, partner.name),
                              icon: const Icon(Icons.chat_rounded, color: Color(0xFF10B981), size: 20),
                              tooltip: 'WhatsApp Driver',
                            ),
                          ],
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
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
    );
  }

  Widget _buildPartnerFallbackAvatar(UserModel partner) {
    final initial = partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2563EB)),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _TopKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _TopKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
