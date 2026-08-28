import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class DealerFleetScreen extends StatefulWidget {
  const DealerFleetScreen({super.key});

  @override
  State<DealerFleetScreen> createState() => _DealerFleetScreenState();
}

class _DealerFleetScreenState extends State<DealerFleetScreen> {
  final _fleetRepo = DealerFleetRepository();
  String _filterStatus = 'all'; // all, available, onRoute, offDuty

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  void _shareStoreInviteLink(String dealerName, String dealerId) {
    final storeCode = 'STORE-${dealerId.substring(0, dealerId.length > 5 ? 5 : dealerId.length).toUpperCase()}';
    final message =
        '🛵 *Join the Dedicated Delivery Fleet for $dealerName!*\n\n'
        'We are hiring full-time and dedicated delivery partners for daily morning water runs and grocery delivery.\n\n'
        '• Store Code: *$storeCode*\n'
        '• Instant Payouts & Flexible Shifts\n'
        'Download the GroceryGo Partner app and enter our Store Code to link directly.';

    Clipboard.setData(ClipboardData(text: message));
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.share_rounded, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 10),
                Text('Driver Invite Link Ready', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Store invitation with code "$storeCode" has been copied to your clipboard.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openWhatsApp('', message);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('Share Invite on WhatsApp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHireDriverModal(BuildContext context, String dealerId, String dealerName) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final vehicleNumCtrl = TextEditingController();
    String vehicleType = 'Bike / Two-Wheeler';
    DriverEmploymentType empType = DriverEmploymentType.dedicatedPerDrop;
    final rateCtrl = TextEditingController(text: '25');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(22, 18, 22, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0F766E), size: 22),
                    SizedBox(width: 10),
                    Text('Hire In-House Delivery Partner', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Add a dedicated driver for your store runs and water supply.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                const SizedBox(height: 18),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Partner Full Name *',
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0F766E), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0F766E), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle Type & Number
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: vehicleType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Vehicle',
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: ['Bike / Two-Wheeler', '3-Wheeler / Auto', 'Mini-Van / Pickup', 'Bicycle']
                            .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => vehicleType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: vehicleNumCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Plate No.',
                          hintText: 'e.g. TN-38-AX-9128',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────
                // Payout Terms Highlight Container
                // ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF99F6E4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_rounded, color: Color(0xFF0F766E), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'PAYOUT TERMS & COMPENSATION',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F766E), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  empType = DriverEmploymentType.dedicatedPerDrop;
                                  rateCtrl.text = '25';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: empType == DriverEmploymentType.dedicatedPerDrop ? const Color(0xFF0F766E) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: empType == DriverEmploymentType.dedicatedPerDrop ? const Color(0xFF0F766E) : const Color(0xFFCCFBF1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_shipping_rounded,
                                      size: 18,
                                      color: empType == DriverEmploymentType.dedicatedPerDrop ? Colors.white : const Color(0xFF0F766E),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Per-Drop / Can',
                                      style: TextStyle(
                                        color: empType == DriverEmploymentType.dedicatedPerDrop ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  empType = DriverEmploymentType.dedicatedMonthly;
                                  rateCtrl.text = '15000';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: empType == DriverEmploymentType.dedicatedMonthly ? const Color(0xFF0F766E) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: empType == DriverEmploymentType.dedicatedMonthly ? const Color(0xFF0F766E) : const Color(0xFFCCFBF1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                      color: empType == DriverEmploymentType.dedicatedMonthly ? Colors.white : const Color(0xFF0F766E),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Monthly Salary',
                                      style: TextStyle(
                                        color: empType == DriverEmploymentType.dedicatedMonthly ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: empType == DriverEmploymentType.dedicatedMonthly ? 'Monthly Fixed Salary (₹)' : 'Rate Per Drop / 20L Can (₹)',
                          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                          prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF0F766E), size: 20),
                          helperText: empType == DriverEmploymentType.dedicatedMonthly
                              ? 'Fixed salary credited monthly to delivery partner.'
                              : 'Auto-calculated on each completed morning water drop / grocery delivery.',
                          helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF0F766E)),
                          helperMaxLines: 2,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF99F6E4))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF99F6E4))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            if (name.isEmpty || phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter partner name and phone')));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final rate = double.tryParse(rateCtrl.text.trim()) ?? 25.0;

                            final driver = DealerDriverModel(
                              id: '',
                              driverId: phone.replaceAll(RegExp(r'[^0-9]'), ''),
                              driverName: name,
                              driverPhone: phone,
                              vehicleType: vehicleType,
                              vehicleNumber: vehicleNumCtrl.text.trim().toUpperCase(),
                              dealerId: dealerId,
                              dealerName: dealerName,
                              employmentType: empType,
                              payoutRate: rate,
                              hiredAt: DateTime.now(),
                            );

                            try {
                              await _fleetRepo.hireDriver(driver);
                              if (ctx.mounted) Navigator.pop(modalCtx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ $name added to your dedicated delivery fleet!'),
                                    backgroundColor: const Color(0xFF0F766E),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm & Add to Fleet ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettlePayoutDialog(DealerDriverModel driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Settle Fleet Payout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm payout settlement for ${driver.driverName}:', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pending Payout:', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                  Text(
                    '₹${driver.pendingPayout.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _fleetRepo.settlePayout(driver.id, driver.pendingPayout);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Payout of ₹${driver.pendingPayout.toStringAsFixed(0)} settled for ${driver.driverName}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
            child: const Text('Mark Paid ✓', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          'My Delivery Fleet',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareStoreInviteLink(user.name, user.id),
            icon: const Icon(Icons.share_rounded, color: Color(0xFF0F766E)),
            tooltip: 'Invite Drivers via WhatsApp',
          ),
        ],
      ),
      body: StreamBuilder<List<DealerDriverModel>>(
        stream: _fleetRepo.streamDealerFleet(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
          }

          final fleet = snapshot.data ?? [];
          final onRouteCount = fleet.where((d) => d.workStatus == DriverWorkStatus.onRoute).length;
          final availableCount = fleet.where((d) => d.workStatus == DriverWorkStatus.availableAtStore).length;
          final totalDrops = fleet.fold<int>(0, (sum, d) => sum + d.totalDropsCompleted);

          final filtered = fleet.where((d) {
            if (_filterStatus == 'available' && d.workStatus != DriverWorkStatus.availableAtStore) return false;
            if (_filterStatus == 'onRoute' && d.workStatus != DriverWorkStatus.onRoute) return false;
            if (_filterStatus == 'offDuty' && d.workStatus != DriverWorkStatus.offDuty) return false;
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─────────────────────────────────────────────
              // 1. Fleet Telemetry Header Banner
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STORE IN-HOUSE FLEET',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.8),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${fleet.length} Dedicated Drivers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBannerStat(
                            'At Store',
                            '$availableCount Idle',
                            'Ready for dispatch',
                            Icons.storefront_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBannerStat(
                            'On Route',
                            '$onRouteCount Delivering',
                            'Live trip active',
                            Icons.two_wheeler_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBannerStat(
                            'Total Drops Done',
                            '$totalDrops Trips',
                            'Across all runs',
                            Icons.local_shipping_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showHireDriverModal(context, user.id, user.name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F766E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: const Text('Hire Driver +', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _shareStoreInviteLink(user.name, user.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Invite', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // 2. Filter Strip
              // ─────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All Fleet (${fleet.length})'),
                    const SizedBox(width: 8),
                    _filterChip('available', 'At Store ($availableCount)'),
                    const SizedBox(width: 8),
                    _filterChip('onRoute', 'On Route ($onRouteCount)'),
                    const SizedBox(width: 8),
                    _filterChip('offDuty', 'Off Duty'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────────────
              // 3. Driver Cards Listing
              // ─────────────────────────────────────────────
              if (filtered.isEmpty)
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
                        const Icon(Icons.two_wheeler_rounded, size: 44, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        const Text('No Delivery Partners in this State', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('Tap "Hire Driver +" to onboard your in-house delivery staff.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map((driver) => _buildDriverCard(driver)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerStat(String title, String val, String sub, IconData icon) {
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
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
              Icon(icon, color: Colors.white, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(DealerDriverModel driver) {
    final isOnRoute = driver.workStatus == DriverWorkStatus.onRoute;
    final isAvailable = driver.workStatus == DriverWorkStatus.availableAtStore;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0F766E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.driverName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(driver.driverPhone, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : isOnRoute
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      driver.workStatus.displayName,
                      style: TextStyle(
                        color: isAvailable
                            ? const Color(0xFF065F46)
                            : isOnRoute
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF475569),
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Vehicle & Contract Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${driver.vehicleType} • ${driver.vehicleNumber.isNotEmpty ? driver.vehicleNumber : "No Plate"}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        driver.employmentType == DriverEmploymentType.dedicatedMonthly
                            ? 'Salary: ₹${driver.payoutRate.toStringAsFixed(0)}/mo'
                            : 'Rate: ₹${driver.payoutRate.toStringAsFixed(0)}/drop',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${driver.totalDropsCompleted} Drops', style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700)),
                    Text('${driver.totalCansDelivered} Cans', style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700)),
                    InkWell(
                      onTap: driver.pendingPayout > 0 ? () => _showSettlePayoutDialog(driver) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: driver.pendingPayout > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: driver.pendingPayout > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Text(
                          driver.pendingPayout > 0
                              ? 'Pay Due: ₹${driver.pendingPayout.toStringAsFixed(0)} ⚡'
                              : 'Paid Up ✓',
                          style: TextStyle(
                            color: driver.pendingPayout > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(driver.driverPhone),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFFCCFBF1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 14),
                  label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(driver.driverPhone, 'Hi ${driver.driverName}, please check your assigned delivery runs for today.'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFFDCFCE7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                  label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                onSelected: (val) async {
                  if (val == 'status_avail') {
                    await _fleetRepo.updateDriverWorkStatus(driver.id, DriverWorkStatus.availableAtStore);
                  } else if (val == 'status_route') {
                    await _fleetRepo.updateDriverWorkStatus(driver.id, DriverWorkStatus.onRoute);
                  } else if (val == 'status_off') {
                    await _fleetRepo.updateDriverWorkStatus(driver.id, DriverWorkStatus.offDuty);
                  } else if (val == 'settle') {
                    _showSettlePayoutDialog(driver);
                  } else if (val == 'remove') {
                    await _fleetRepo.removeDriver(driver.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'status_avail', child: Text('Mark Available at Store')),
                  const PopupMenuItem(value: 'status_route', child: Text('Mark On Route / Delivering')),
                  const PopupMenuItem(value: 'status_off', child: Text('Mark Off Duty / Offline')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'settle', child: Text('Settle Pending Payout')),
                  const PopupMenuItem(value: 'remove', child: Text('Remove from Fleet', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
