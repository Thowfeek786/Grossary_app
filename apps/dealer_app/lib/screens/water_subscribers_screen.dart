import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';
import '../providers/auth_provider.dart';

class WaterSubscribersScreen extends StatefulWidget {
  const WaterSubscribersScreen({super.key});

  @override
  State<WaterSubscribersScreen> createState() => _WaterSubscribersScreenState();
}

class _WaterSubscribersScreenState extends State<WaterSubscribersScreen> with SingleTickerProviderStateMixin {
  final _subRepo = WaterSubscriptionRepository();
  late TabController _tabController;
  String _filterStatus = 'all'; // all, active, paused, cancelled
  String _searchQuery = '';

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

  void _showDealerCancelDialog(WaterSubscriptionModel sub) {
    String reason = 'Customer requested cancellation';
    final customCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Customer Subscription', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel the recurring drops for ${sub.userName}?', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: customCtrl,
              decoration: InputDecoration(
                hintText: 'Reason (e.g. Relocated, Customer Call)',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final finalReason = customCtrl.text.trim().isNotEmpty ? customCtrl.text.trim() : reason;
              await _subRepo.cancelSubscription(sub.id, reason: finalReason, cancelledBy: 'dealer');
              HapticFeedback.mediumImpact();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Subscription for ${sub.userName} cancelled.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Cancel Plan', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _shareManifestWithDriver(List<WaterSubscriptionModel> subs, String dealerName) {
    if (subs.isEmpty) return;

    final now = DateTime.now();
    final dateStr = AppHelpers.formatDate(now);
    int totalCans = 0;

    final buffer = StringBuffer();
    buffer.writeln('🚚 *MORNING WATER DELIVERY MANIFEST*');
    buffer.writeln('🏢 *Store:* $dealerName');
    buffer.writeln('📅 *Date:* $dateStr');
    buffer.writeln('⏰ *Slot:* 5:30 AM – 7:30 AM');
    buffer.writeln('────────────────────────');

    for (int i = 0; i < subs.length; i++) {
      final sub = subs[i];
      totalCans += sub.quantityPerDelivery;
      buffer.writeln('${i + 1}. *${sub.userName}* (${sub.quantityPerDelivery} Cans)');
      buffer.writeln('   📍 ${sub.deliveryAddress}');
      if (sub.deliveryInstructions != null && sub.deliveryInstructions!.isNotEmpty) {
        buffer.writeln('   📝 Note: ${sub.deliveryInstructions}');
      }
      buffer.writeln('   📞 ${sub.userPhone}');
      buffer.writeln('');
    }

    buffer.writeln('────────────────────────');
    buffer.writeln('📦 *TOTAL CANS TO LOAD:* $totalCans Cans');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
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
                Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF0D9488), size: 24),
                SizedBox(width: 10),
                Text('Morning Manifest Generated', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Route sheet with $totalCans cans across ${subs.length} customer stops has been copied to your clipboard.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openWhatsApp('', buffer.toString());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('Forward to Driver on WhatsApp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
          ],
        ),
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
          'Water Subscribers & Manifest',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.local_shipping_rounded, size: 18), text: 'Daily Run Manifest'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'All Subscribers'),
          ],
        ),
      ),
      body: StreamBuilder<List<WaterSubscriptionModel>>(
        stream: _subRepo.getDealerAllSubscriptions(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
          }

          final allSubs = snapshot.data ?? [];
          final activeSubs = allSubs.where((s) => s.status == SubscriptionStatus.active).toList();
          final pausedSubs = allSubs.where((s) => s.status == SubscriptionStatus.paused).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // ─────────────────────────────────────────────
              // TAB 1: DAILY DELIVERY RUN MANIFEST
              // ─────────────────────────────────────────────
              _buildDailyManifestTab(context, activeSubs, user.name),

              // ─────────────────────────────────────────────
              // TAB 2: SUBSCRIBER DIRECTORY
              // ─────────────────────────────────────────────
              _buildSubscriberDirectoryTab(allSubs, activeSubs.length, pausedSubs.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyManifestTab(BuildContext context, List<WaterSubscriptionModel> activeSubs, String dealerName) {
    final now = DateTime.now();
    final totalMorningCans = activeSubs.fold<int>(0, (sum, s) => sum + s.quantityPerDelivery);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TODAY\'S MORNING RUN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppHelpers.formatDate(now),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 14),
                        SizedBox(width: 5),
                        Text('5:30 - 7:30 AM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Drops', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${activeSubs.length} Houses', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vehicle Load', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('$totalMorningCans Cans (20L)', style: const TextStyle(color: Colors.amberAccent, fontSize: 17, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _shareManifestWithDriver(activeSubs, dealerName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Export Driver Route Sheet 📤', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Route Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text('${activeSubs.length} Stops', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),

        if (activeSubs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.water_drop_outlined, size: 48, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text('No Scheduled Morning Drops', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF334155))),
                SizedBox(height: 4),
                Text('Customer recurring subscriptions will populate here automatically.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          )
        else
          ...activeSubs.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final sub = entry.value;
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
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$idx',
                                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            sub.userName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          '${sub.quantityPerDelivery}x 20L Cans',
                          style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sub.deliveryAddress,
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                  if (sub.deliveryInstructions != null && sub.deliveryInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Note: ${sub.deliveryInstructions}',
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _makeCall(sub.userPhone),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFFCCFBF1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 14),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWhatsApp(sub.userPhone, 'Hi ${sub.userName}, your water delivery is on the way! 🚚💧'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFFDCFCE7)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                          label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSubscriberDirectoryTab(List<WaterSubscriptionModel> allSubs, int activeCount, int pausedCount) {
    final filtered = allSubs.where((s) {
      if (_filterStatus == 'active' && s.status != SubscriptionStatus.active) return false;
      if (_filterStatus == 'paused' && s.status != SubscriptionStatus.paused) return false;
      if (_filterStatus == 'cancelled' && s.status != SubscriptionStatus.cancelled) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.userName.toLowerCase().contains(q) ||
            s.userPhone.toLowerCase().contains(q) ||
            s.deliveryAddress.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search subscriber by name, phone or address...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All (${allSubs.length})'),
                    const SizedBox(width: 8),
                    _filterChip('active', 'Active ($activeCount)'),
                    const SizedBox(width: 8),
                    _filterChip('paused', 'Paused ($pausedCount)'),
                    const SizedBox(width: 8),
                    _filterChip('cancelled', 'Cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Subscriber List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isEmpty ? 'No Subscribers in this Category' : 'No matches for "$_searchQuery"',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final sub = filtered[i];
                    return _buildSubscriberCard(sub);
                  },
                ),
        ),
      ],
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

  Widget _buildSubscriberCard(WaterSubscriptionModel sub) {
    final bool isActive = sub.status == SubscriptionStatus.active;
    final bool isPaused = sub.status == SubscriptionStatus.paused;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.userPhone,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              _subPill(Icons.repeat_rounded, sub.cadence.displayName, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _subPill(Icons.water_drop_rounded, '${sub.quantityPerDelivery}x 20L / drop', const Color(0xFF0D9488)),
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
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(sub.userPhone),
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
                  onPressed: () => _openWhatsApp(sub.userPhone, 'Hi ${sub.userName}, greetings from ${sub.dealerName}! 💧'),
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
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) async {
                  if (val == 'pause') {
                    await _subRepo.pauseSubscription(
                      subscriptionId: sub.id,
                      startDate: DateTime.now(),
                      endDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Subscription paused for 7 days.')),
                      );
                    }
                  } else if (val == 'resume') {
                    await _subRepo.resumeSubscription(sub.id, DateTime.now().add(const Duration(days: 1)));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Subscription resumed!')),
                      );
                    }
                  } else if (val == 'cancel') {
                    _showDealerCancelDialog(sub);
                  }
                },
                itemBuilder: (ctx) => [
                  if (isActive)
                    const PopupMenuItem(
                      value: 'pause',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle_outline_rounded, color: Color(0xFF2563EB), size: 18),
                          SizedBox(width: 8),
                          Text('Pause Deliveries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  if (isPaused)
                    const PopupMenuItem(
                      value: 'resume',
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_outline_rounded, color: Color(0xFF059669), size: 18),
                          SizedBox(width: 8),
                          Text('Resume Deliveries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  if (!sub.status.name.contains('cancelled'))
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Text('Cancel Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (sub.status == SubscriptionStatus.cancelled && sub.cancellationReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cancelled: ${sub.cancellationReason}',
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _subPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
