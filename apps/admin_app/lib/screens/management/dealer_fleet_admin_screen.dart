import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class DealerFleetAdminScreen extends StatefulWidget {
  const DealerFleetAdminScreen({super.key});

  @override
  State<DealerFleetAdminScreen> createState() => _DealerFleetAdminScreenState();
}

class _DealerFleetAdminScreenState extends State<DealerFleetAdminScreen> {
  final _fleetRepo = DealerFleetRepository();
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
          'Store Dedicated Fleets',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<DealerDriverModel>>(
        stream: _fleetRepo.streamAllFleets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
          }

          final allDrivers = snapshot.data ?? [];
          final onRouteCount = allDrivers.where((d) => d.workStatus == DriverWorkStatus.onRoute).length;
          final availableCount = allDrivers.where((d) => d.workStatus == DriverWorkStatus.availableAtStore).length;
          final totalDrops = allDrivers.fold<int>(0, (sum, d) => sum + d.totalDropsCompleted);

          // Unique dealers list for filter
          final dealersMap = <String, String>{};
          for (final d in allDrivers) {
            if (d.dealerId.isNotEmpty && d.dealerName.isNotEmpty) {
              dealersMap[d.dealerId] = d.dealerName;
            }
          }

          final filtered = allDrivers.where((d) {
            if (_selectedDealerId != 'all' && d.dealerId != _selectedDealerId) return false;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              return d.driverName.toLowerCase().contains(q) ||
                  d.driverPhone.toLowerCase().contains(q) ||
                  d.dealerName.toLowerCase().contains(q) ||
                  d.vehicleNumber.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // ─────────────────────────────────────────────
              // 1. Platform Fleet Telemetry Banner
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
                          'GLOBAL IN-HOUSE FLEET TELEMETRY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.8),
                        ),
                        Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Total Hired Drivers',
                            '${allDrivers.length} Drivers',
                            'Across all dark stores',
                            Icons.people_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            'Active on Route',
                            '$onRouteCount Delivering',
                            '$availableCount at store',
                            Icons.directions_bike_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Total Trips Fulfilled',
                            '$totalDrops Completed',
                            'Regular & morning drops',
                            Icons.local_shipping_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // 2. Search & Dark Store Filters
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
                        hintText: 'Search driver by name, phone, plate...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    if (dealersMap.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Filter by Dark Store',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _storeFilterChip('all', 'All Stores (${allDrivers.length})'),
                            ...dealersMap.entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _storeFilterChip(e.key, e.value),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // 3. Driver Directory Listing
              // ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hired Drivers Directory', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
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
                        Icon(Icons.two_wheeler_rounded, size: 44, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text('No store-hired drivers found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map((driver) => _buildAdminDriverCard(driver)),
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
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
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

  Widget _buildAdminDriverCard(DealerDriverModel driver) {
    final isOnRoute = driver.workStatus == DriverWorkStatus.onRoute;
    final isAvailable = driver.workStatus == DriverWorkStatus.availableAtStore;

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
                      driver.driverName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver.driverPhone} • ${driver.vehicleType} (${driver.vehicleNumber.isNotEmpty ? driver.vehicleNumber : "No Plate"})',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFECFDF5)
                      : isOnRoute
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFFA7F3D0)
                        : isOnRoute
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  driver.workStatus.displayName.toUpperCase(),
                  style: TextStyle(
                    color: isAvailable
                        ? const Color(0xFF065F46)
                        : isOnRoute
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF475569),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
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
                    'Employed by: ${driver.dealerName}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F766E)),
                  ),
                ),
                Text(
                  driver.employmentType == DriverEmploymentType.dedicatedMonthly
                      ? '₹${driver.payoutRate.toStringAsFixed(0)}/mo'
                      : '₹${driver.payoutRate.toStringAsFixed(0)}/drop',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${driver.totalDropsCompleted} Drops Fulfilled', style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text('${driver.totalCansDelivered} Cans Supplied', style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text('Pending: ₹${driver.pendingPayout.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF059669), fontSize: 11.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
