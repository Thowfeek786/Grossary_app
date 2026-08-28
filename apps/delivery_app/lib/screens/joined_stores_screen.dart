import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/join_store_fleet_dialog.dart';

class JoinedStoresScreen extends StatefulWidget {
  const JoinedStoresScreen({super.key});

  @override
  State<JoinedStoresScreen> createState() => _JoinedStoresScreenState();
}

class _JoinedStoresScreenState extends State<JoinedStoresScreen> {
  final DealerFleetRepository _fleetRepo = DealerFleetRepository();

  void _showLeaveConfirmation(BuildContext context, DealerDriverModel affil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Store Fleet?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Text(
          'Are you sure you want to disconnect from ${affil.dealerName}\'s delivery fleet? You can rejoin anytime using their store invite code.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _fleetRepo.removeDriver(affil.id);
              HapticFeedback.mediumImpact();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Disconnected from ${affil.dealerName}\'s fleet.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Leave Fleet', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final driverId = user.phone.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
        ? user.phone.replaceAll(RegExp(r'[^0-9]'), '')
        : user.id;

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
          'My Affiliated Stores',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link_rounded, color: Color(0xFF059669)),
            tooltip: 'Enter Invite Code',
            onPressed: () => JoinStoreFleetDialog.show(context, user),
          ),
        ],
      ),
      body: StreamBuilder<List<DealerDriverModel>>(
        stream: _fleetRepo.streamDriverAffiliations(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }

          final stores = snapshot.data ?? [];
          final totalDrops = stores.fold<int>(0, (sum, s) => sum + s.totalDropsCompleted);
          final totalCans = stores.fold<int>(0, (sum, s) => sum + s.totalCansDelivered);
          final totalPendingPayout = stores.fold<double>(0.0, (sum, s) => sum + s.pendingPayout);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // ─────────────────────────────────────────────
              // 1. Telemetry Header Banner
              // ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B3C26), Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AFFILIATED DARK STORES',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.8),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${stores.length} Joined Store${stores.length == 1 ? "" : "s"}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBannerStat('Drops Done', '$totalDrops Trips', 'Across stores', Icons.local_shipping_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBannerStat('Cans Supplied', '$totalCans Jars', 'Water deliveries', Icons.water_drop_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBannerStat('Payout Due', '₹${totalPendingPayout.toStringAsFixed(0)}', 'Pending credit', Icons.payments_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => JoinStoreFleetDialog.show(context, user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0B3C26),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_link_rounded, size: 18),
                        label: const Text('Join Another Store (Invite Code)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────────
              // 2. Joined Store Cards
              // ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Store Contracts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  Text('${stores.length} Active', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              if (stores.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        const Text(
                          'No Affiliated Stores Yet',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter the store invite code (e.g. STORE-QJJJP) provided by your dealer to receive dedicated morning drops.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => JoinStoreFleetDialog.show(context, user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_link_rounded, size: 16),
                          label: const Text('Enter Store Invite Code', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...stores.map((store) => _buildStoreCard(context, store)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerStat(String label, String value, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(icon, color: Colors.white, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(color: Colors.white60, fontSize: 8.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, DealerDriverModel store) {
    final isMonthly = store.employmentType == DriverEmploymentType.dedicatedMonthly;
    final storeCode = 'STORE-${store.dealerId.substring(0, store.dealerId.length > 5 ? 5 : store.dealerId.length).toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Store Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.dealerName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Store Code: $storeCode',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 12),
                    SizedBox(width: 4),
                    Text('Active Fleet', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Payout & Contract Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COMPENSATION CONTRACT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(
                        isMonthly
                            ? 'Monthly Salary: ₹${store.payoutRate.toStringAsFixed(0)}/mo'
                            : 'Per-Drop Rate: ₹${store.payoutRate.toStringAsFixed(0)}/can',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: store.pendingPayout > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: store.pendingPayout > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Text(
                    store.pendingPayout > 0
                        ? 'Due: ₹${store.pendingPayout.toStringAsFixed(0)}'
                        : 'Settled ✓',
                    style: TextStyle(
                      color: store.pendingPayout > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${store.totalDropsCompleted} Drops', style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text('${store.totalCansDelivered} Cans', style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text(
                'Status: ${store.workStatus.displayName}',
                style: const TextStyle(color: Color(0xFF059669), fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/morning-drops'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.water_drop_rounded, size: 14),
                  label: const Text('Morning Drops', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showLeaveConfirmation(context, store),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 14),
                label: const Text('Leave', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
