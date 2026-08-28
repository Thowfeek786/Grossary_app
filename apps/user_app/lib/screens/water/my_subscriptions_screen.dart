import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> with SingleTickerProviderStateMixin {
  final WaterSubscriptionRepository _subRepo = WaterSubscriptionRepository();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // 1. Cancel Subscription Modal Flow
  // ─────────────────────────────────────────────
  void _showCancelDialog(BuildContext context, WaterSubscriptionModel sub) {
    String selectedReason = 'Moving / Relocating';
    final TextEditingController customReasonCtrl = TextEditingController();
    bool isProcessing = false;

    final reasons = [
      'Moving / Relocating',
      'Water consumption reduced / Not needed',
      'Going on temporary vacation (Consider Pause instead)',
      'Delivery timing / schedule conflicts',
      'Switched to RO water purifier',
      'Other reason',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancel Water Subscription',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'We\'re sorry to see you go. Help us improve.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Deposit Safety Preservation Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security Deposits Remain Safe & Refundable',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF14532D)),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Your deposit balance is 100% protected. Return your empty jars anytime to your delivery partner or dark store for an instant wallet/bank refund.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Please select a reason for cancellation:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),

                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return InkWell(
                      onTap: () => setModalState(() => selectedReason = r),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: isSel ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? const Color(0xFF991B1B) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (selectedReason == 'Other reason') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customReasonCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tell us more details...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Keep Subscription', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setModalState(() => isProcessing = true);
                                  final finalReason = selectedReason == 'Other reason' && customReasonCtrl.text.trim().isNotEmpty
                                      ? customReasonCtrl.text.trim()
                                      : selectedReason;

                                  await _subRepo.cancelSubscription(
                                    sub.id,
                                    reason: finalReason,
                                    cancelledBy: 'customer',
                                  );

                                  HapticFeedback.mediumImpact();
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Subscription cancelled. You can reactivate anytime!'),
                                        backgroundColor: Color(0xFF0F172A),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isProcessing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Confirm Cancel', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 2. Pause / Vacation Mode Modal
  // ─────────────────────────────────────────────
  void _showPauseDialog(BuildContext context, WaterSubscriptionModel sub) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    int selectedDays = 7;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.beach_access_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vacation / Pause Mode', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          SizedBox(height: 2),
                          Text('Temporarily pause doorstep drops without losing your plan', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Choose pause duration:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155))),
                const SizedBox(height: 10),

                Row(
                  children: [3, 7, 14, 30].map((days) {
                    final isSel = selectedDays == days;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedDays = days;
                            endDate = DateTime.now().add(Duration(days: days));
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$days Days',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isSel ? Colors.white : const Color(0xFF334155)),
                              ),
                              Text(
                                days == 7 ? '1 Week' : (days == 14 ? '2 Weeks' : (days == 30 ? '1 Month' : 'Short')),
                                style: TextStyle(fontSize: 9.5, color: isSel ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAUSE PERIOD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('dd MMM').format(startDate)} → ${DateFormat('dd MMM yyyy').format(endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            await _subRepo.pauseSubscription(
                              subscriptionId: sub.id,
                              startDate: startDate,
                              endDate: endDate,
                            );
                            HapticFeedback.selectionClick();
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Deliveries paused until ${DateFormat('dd MMM').format(endDate)}'),
                                  backgroundColor: const Color(0xFF2563EB),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Vacation Pause', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 3. Modify Plan Modal
  // ─────────────────────────────────────────────
  void _showModifyPlanDialog(BuildContext context, WaterSubscriptionModel sub) {
    SubscriptionCadence selectedCadence = sub.cadence;
    int selectedQty = sub.quantityPerDelivery;
    String selectedSlot = sub.timeSlot;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF059669), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modify Subscription Plan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            SizedBox(height: 2),
                            Text('Update delivery schedule, frequency & quantity', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cadence
                  const Text('Delivery Cadence:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  ...[
                    SubscriptionCadence.daily,
                    SubscriptionCadence.alternateDays,
                    SubscriptionCadence.every3Days,
                    SubscriptionCadence.weekly,
                  ].map((cad) {
                    final isSel = selectedCadence == cad;
                    return InkWell(
                      onTap: () => setModalState(() => selectedCadence = cad),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_off, color: isSel ? const Color(0xFF059669) : const Color(0xFF94A3B8), size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(cad.displayName, style: TextStyle(fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, fontSize: 12.5))),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Quantity
                  const Text('Quantity Per Delivery:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3, 4].map((qty) {
                      final isSel = selectedQty == qty;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedQty = qty),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$qty Can${qty > 1 ? "s" : ""}',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isSel ? Colors.white : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final nextDate = _subRepo.calculateNextDelivery(selectedCadence, fromDate: DateTime.now());

                              await _subRepo.updateSubscriptionPlan(
                                subscriptionId: sub.id,
                                cadence: selectedCadence,
                                quantityPerDelivery: selectedQty,
                                timeSlot: selectedSlot,
                                nextScheduledDelivery: nextDate,
                              );

                              HapticFeedback.selectionClick();
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✓ Subscription schedule updated!'), backgroundColor: Color(0xFF059669)),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Schedule Changes ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
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
        title: const Text('My Water Subscriptions', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: 'Active Plans'),
            Tab(text: 'Paused (Vacation)'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<WaterSubscriptionModel>>(
        stream: _subRepo.getUserSubscriptions(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }

          final allSubs = snapshot.data ?? [];
          final activeSubs = allSubs.where((s) => s.status == SubscriptionStatus.active).toList();
          final pausedSubs = allSubs.where((s) => s.status == SubscriptionStatus.paused).toList();
          final cancelledSubs = allSubs.where((s) => s.status == SubscriptionStatus.cancelled).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildSubList(context, activeSubs, 'No active subscriptions', 'Start a smart recurring hydration plan to get doorstep water jars at discount rates.'),
              _buildSubList(context, pausedSubs, 'No paused plans', 'Your plans are currently active and delivering on schedule.'),
              _buildSubList(context, cancelledSubs, 'No cancelled plans', 'Any cancelled subscription history will appear here.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubList(BuildContext context, List<WaterSubscriptionModel> list, String emptyTitle, String emptySub) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop_outlined, size: 52, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 14),
              Text(emptyTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text(emptySub, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, idx) => _buildSubscriptionCard(context, list[idx]),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WaterSubscriptionModel sub) {
    final isActive = sub.status == SubscriptionStatus.active;
    final isPaused = sub.status == SubscriptionStatus.paused;
    final isCancelled = sub.status == SubscriptionStatus.cancelled;

    final formattedNext = DateFormat('EEE, dd MMM').format(sub.nextScheduledDelivery);
    final daysUntilNext = sub.nextScheduledDelivery.difference(DateTime.now()).inDays;
    final countdownText = daysUntilNext == 0 ? 'Today' : (daysUntilNext == 1 ? 'Tomorrow' : 'In $daysUntilNext days');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : (isPaused ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
          width: isActive ? 1.5 : 1,
        ),
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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF059669).withValues(alpha: 0.12)
                      : (isPaused ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.water_drop_rounded : (isPaused ? Icons.pause_rounded : Icons.cancel_outlined),
                  color: isActive ? const Color(0xFF059669) : (isPaused ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sub.quantityPerDelivery}x 20L Pure Water Cans',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cadence: ${sub.cadence.displayName}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFECFDF5)
                      : (isPaused ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFA7F3D0)
                        : (isPaused ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA)),
                  ),
                ),
                child: Text(
                  sub.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? const Color(0xFF065F46) : (isPaused ? const Color(0xFF1E40AF) : const Color(0xFF991B1B)),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Details Box
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
                    const Text('Next Drop', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCancelled
                            ? 'Cancelled'
                            : (isPaused ? 'On Vacation Hold' : '$formattedNext ($countdownText)'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isCancelled ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time Slot', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.timeSlot,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Price per Drop', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹${(sub.pricePerCan * sub.quantityPerDelivery).toStringAsFixed(0)} (10% OFF)',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dark Store', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.dealerName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isCancelled && sub.cancellationReason != null) ...[
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reason', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.cancellationReason!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700, fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Actions
          if (isActive)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPauseDialog(context, sub),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.beach_access_rounded, size: 14),
                    label: const Text('Vacation Hold', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showModifyPlanDialog(context, sub),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                    label: const Text('Modify Plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 18),
                  tooltip: 'WhatsApp Store Support',
                  onPressed: () => _launchWhatsApp(sub.userPhone, 'Hi, I have a question regarding my subscription (#${sub.id.substring(0, 5)}):'),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                  tooltip: 'Cancel Subscription',
                  onPressed: () => _showCancelDialog(context, sub),
                ),
              ],
            )
          else if (isPaused)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _subRepo.resumeSubscription(sub.id, DateTime.now().add(const Duration(days: 1)));
                      HapticFeedback.selectionClick();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Deliveries resumed successfully!'), backgroundColor: Color(0xFF059669)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Resume Deliveries Now', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showCancelDialog(context, sub),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cancelled on ${sub.cancelledAt != null ? DateFormat('dd MMM yyyy').format(sub.cancelledAt!) : "Past date"}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/water-can'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                  label: const Text('Reactivate Plan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
