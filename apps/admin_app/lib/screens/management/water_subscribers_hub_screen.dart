import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class WaterSubscribersHubScreen extends StatefulWidget {
  const WaterSubscribersHubScreen({super.key});

  @override
  State<WaterSubscribersHubScreen> createState() => _WaterSubscribersHubScreenState();
}

class _WaterSubscribersHubScreenState extends State<WaterSubscribersHubScreen> {
  final _subRepo = WaterSubscriptionRepository();
  String _filterStatus = 'all'; // all, active, paused, cancelled
  String _selectedDealerId = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Water Subscriptions Hub',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<WaterSubscriptionModel>>(
        stream: _subRepo.getAllSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
          }

          final allSubs = snapshot.data ?? [];
          final activeSubs = allSubs.where((s) => s.status == SubscriptionStatus.active).toList();
          final pausedSubs = allSubs.where((s) => s.status == SubscriptionStatus.paused).toList();
          final cancelledSubs = allSubs.where((s) => s.status == SubscriptionStatus.cancelled).toList();

          // Calculate Key Metrics
          final totalActive = activeSubs.length;
          final totalDailyCans = activeSubs.fold<int>(0, (sum, s) => sum + s.quantityPerDelivery);
          final estimatedMrr = activeSubs.fold<double>(0.0, (sum, s) {
            // Approx 15 deliveries/month for alternate, 30 for daily
            final monthlyDeliveries = s.cadence == SubscriptionCadence.daily
                ? 30
                : (s.cadence == SubscriptionCadence.alternateDays ? 15 : 8);
            return sum + (s.pricePerCan * s.quantityPerDelivery * monthlyDeliveries);
          });

          // Unique dealers list for filtering
          final dealersMap = <String, String>{};
          for (final s in allSubs) {
            if (s.dealerId.isNotEmpty && s.dealerName.isNotEmpty) {
              dealersMap[s.dealerId] = s.dealerName;
            }
          }

          // Filter logic
          final filtered = allSubs.where((s) {
            if (_filterStatus == 'active' && s.status != SubscriptionStatus.active) return false;
            if (_filterStatus == 'paused' && s.status != SubscriptionStatus.paused) return false;
            if (_filterStatus == 'cancelled' && s.status != SubscriptionStatus.cancelled) return false;
            if (_selectedDealerId != 'all' && s.dealerId != _selectedDealerId) return false;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              return s.userName.toLowerCase().contains(q) ||
                  s.userPhone.toLowerCase().contains(q) ||
                  s.dealerName.toLowerCase().contains(q) ||
                  s.deliveryAddress.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // ─────────────────────────────────────────────
              // 1. Platform Recurring Analytics Banner
              // ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PLATFORM RECURRING METRICS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.8),
                        ),
                        Icon(Icons.auto_graph_rounded, color: Colors.amberAccent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Active Subscribers',
                            '$totalActive',
                            '${allSubs.length} total signups',
                            Icons.people_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            'Estimated MRR',
                            '₹${estimatedMrr.toStringAsFixed(0)}',
                            'Recurring revenue',
                            Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Daily Run Volume',
                            '$totalDailyCans Cans/day',
                            'Across all darkstores',
                            Icons.water_drop_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            'Paused / Retention',
                            '${pausedSubs.length} Paused',
                            '${cancelledSubs.length} churned',
                            Icons.pause_circle_filled_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // 2. Search & Store Filter Controls
              // ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search customer, phone, store...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (dealersMap.isNotEmpty) ...[
                      const Text(
                        'Filter by Dark Store',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _storeFilterChip('all', 'All Stores (${allSubs.length})'),
                            ...dealersMap.entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _storeFilterChip(e.key, e.value),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        _statusFilterChip('all', 'All (${allSubs.length})'),
                        const SizedBox(width: 8),
                        _statusFilterChip('active', 'Active ($totalActive)'),
                        const SizedBox(width: 8),
                        _statusFilterChip('paused', 'Paused (${pausedSubs.length})'),
                        const SizedBox(width: 8),
                        _statusFilterChip('cancelled', 'Cancelled (${cancelledSubs.length})'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // 3. Subscriptions Listing
              // ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subscriber Directory', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  Text('${filtered.length} matching', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.person_search_rounded, size: 40, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text('No subscriptions match your criteria', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map((sub) => _buildAdminSubscriberCard(sub)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
              Icon(icon, color: Colors.white, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _storeFilterChip(String dealerId, String storeName) {
    final isSelected = _selectedDealerId == dealerId;
    return GestureDetector(
      onTap: () => setState(() => _selectedDealerId = dealerId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          storeName,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _statusFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSubscriberCard(WaterSubscriptionModel sub) {
    final bool isActive = sub.status == SubscriptionStatus.active;
    final bool isPaused = sub.status == SubscriptionStatus.paused;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.userName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sub.userPhone} • ID: ${sub.id.substring(0, sub.id.length > 8 ? 8 : sub.id.length).toUpperCase()}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFECFDF5)
                      : isPaused
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFA7F3D0)
                        : isPaused
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  sub.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF065F46)
                        : isPaused
                            ? const Color(0xFF92400E)
                            : const Color(0xFF475569),
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF0F766E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fulfilled by: ${sub.dealerName}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F766E)),
                  ),
                ),
                Text(
                  '${sub.quantityPerDelivery} Cans / Drop',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoPill(Icons.repeat_rounded, sub.cadence.displayName, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _infoPill(Icons.access_time_rounded, '5:30 - 7:30 AM', const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sub.deliveryAddress,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
