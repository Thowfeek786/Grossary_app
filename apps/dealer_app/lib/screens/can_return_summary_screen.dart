import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import '../providers/auth_provider.dart';

class CanReturnSummaryScreen extends StatefulWidget {
  const CanReturnSummaryScreen({super.key});

  @override
  State<CanReturnSummaryScreen> createState() => _CanReturnSummaryScreenState();
}

class _CanReturnSummaryScreenState extends State<CanReturnSummaryScreen> {
  final WaterCanRepository _waterCanRepo = WaterCanRepository();
  final WaterAssetRepository _assetRepo = WaterAssetRepository();
  String _selectedFilter = 'Today';
  final List<String> _filters = ['Today', 'This Week', 'All Time'];

  void _showBatchQcModal(BuildContext context, UserModel dealer) {
    final batchCtrl = TextEditingController(text: 'BATCH-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-01');
    final tdsCtrl = TextEditingController(text: '95');
    final phCtrl = TextEditingController(text: '7.2');
    final fssaiCtrl = TextEditingController(text: '10020042000189');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                        child: const Icon(Icons.science_rounded, color: Color(0xFF2563EB), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Record Batch Lab Quality (TDS / pH)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: batchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Batch Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tdsCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'TDS (ppm)',
                            helperText: 'Ideal: 80 - 120 ppm',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'pH Level',
                            helperText: 'Ideal: 6.8 - 7.5',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fssaiCtrl,
                    decoration: InputDecoration(
                      labelText: 'FSSAI License Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                              final qual = WaterQualityModel(
                                id: '',
                                dealerId: dealer.id,
                                batchNumber: batchCtrl.text.trim(),
                                tdsValue: double.tryParse(tdsCtrl.text) ?? 95.0,
                                phValue: double.tryParse(phCtrl.text) ?? 7.2,
                                fssaiNumber: fssaiCtrl.text.trim(),
                                certifiedBy: '${dealer.shopName ?? dealer.name} Quality Lab',
                              );
                              try {
                                await _assetRepo.recordQualityBatch(qual);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✓ Batch Quality Certificate published to customers!'),
                                      backgroundColor: Color(0xFF059669),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Publish Certificate ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

  void _showWalkInReturnModal(BuildContext context, UserModel dealer) {
    final customerNameCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    final cansCountCtrl = TextEditingController(text: '1');
    final refundAmountCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Store Walk-in Return',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Customer returned empty water cans directly at shop',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Customer Name
                  TextField(
                    controller: customerNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'e.g. John Doe',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Customer Phone
                  TextField(
                    controller: customerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Customer Phone',
                      hintText: 'e.g. 9876543210',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Empty Cans Count
                      Expanded(
                        child: TextField(
                          controller: cansCountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Cans Returned',
                            prefixIcon: const Icon(Icons.sync_rounded, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Deposit Refunded (if any)
                      Expanded(
                        child: TextField(
                          controller: refundAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Deposit Refund (₹)',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. Returned 2 cans in good condition',
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = customerNameCtrl.text.trim();
                              final phone = customerPhoneCtrl.text.trim();
                              final cans = int.tryParse(cansCountCtrl.text) ?? 1;
                              final refund = double.tryParse(refundAmountCtrl.text) ?? 0.0;

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter customer name')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                await _waterCanRepo.recordWalkInCanReturn(
                                  dealerId: dealer.id,
                                  dealerName: dealer.shopName ?? 'Dealer Store',
                                  userId: phone.isNotEmpty ? phone : 'WALKIN-${name.toLowerCase().replaceAll(' ', '_')}',
                                  userName: name,
                                  userPhone: phone,
                                  emptyCollected: cans,
                                  refundDepositAmount: refund,
                                  notes: notesCtrl.text.trim(),
                                );

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('🎉 Recorded walk-in return of $cans can(s) from $name!'),
                                      backgroundColor: const Color(0xFF059669),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Record Return ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

  void _showCustomerBreakdownSheet(BuildContext context, String dealerId) {
    String searchKeyword = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Customer Can Balance Ledger',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active empty cans pending collection by customer',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Search field
                TextField(
                  onChanged: (val) => setSheetState(() => searchKeyword = val.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: 'Search customer name or phone...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: StreamBuilder<List<CanTransactionModel>>(
                    stream: _waterCanRepo.getDealerCanLedger(dealerId),
                    builder: (context, snapshot) {
                      final txList = snapshot.data ?? [];
                      if (txList.isEmpty) {
                        return const Center(child: Text('No active customer can records.'));
                      }

                      // Group by user
                      final Map<String, ({String name, String phone, int delivered, int returned})> userMap = {};
                      for (final tx in txList) {
                        final prev = userMap[tx.userId] ?? (name: tx.userName, phone: tx.userPhone, delivered: 0, returned: 0);
                        userMap[tx.userId] = (
                          name: tx.userName.isNotEmpty ? tx.userName : prev.name,
                          phone: tx.userPhone.isNotEmpty ? tx.userPhone : prev.phone,
                          delivered: prev.delivered + tx.fullDelivered,
                          returned: prev.returned + tx.emptyCollected,
                        );
                      }

                      var list = userMap.entries.toList();
                      if (searchKeyword.isNotEmpty) {
                        list = list.where((e) {
                          final name = e.value.name.toLowerCase();
                          final phone = e.value.phone.toLowerCase();
                          return name.contains(searchKeyword) || phone.contains(searchKeyword);
                        }).toList();
                      }

                      if (list.isEmpty) {
                        return const Center(child: Text('No customers found matching search.'));
                      }

                      return ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final item = list[idx].value;
                          final balance = item.delivered - item.returned;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0FDF4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Color(0xFF059669), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name.isNotEmpty ? item.name : 'Customer',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.phone.isNotEmpty ? "${item.phone} • " : ""}${item.delivered} Delivered • ${item.returned} Returned',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: balance > 0
                                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                                        : const Color(0xFF64748B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$balance with user',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: balance > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dealer = context.watch<DealerAuthProvider>().user;
    final dealerId = dealer?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Can Return Summary',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          if (dealer != null) ...[
            IconButton(
              icon: const Icon(Icons.science_outlined, color: Color(0xFF2563EB)),
              tooltip: 'Batch Lab QC',
              onPressed: () => _showBatchQcModal(context, dealer),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF059669)),
              tooltip: 'Scan Can QR',
              onPressed: () async {
                final scannedSerial = await CanQrScannerDialog.show(
                  context,
                  title: 'Scan Returned Water Can',
                  prompt: 'Scan QR code on water can to verify lifecycle & sanitization history',
                );
                if (scannedSerial != null && context.mounted) {
                  try {
                    await _assetRepo.scanReturnEmptyCan(
                      serialId: scannedSerial,
                      collectorId: dealer.id,
                      collectorName: dealer.shopName ?? dealer.name,
                      collectorType: 'dealer',
                      dealerId: dealer.id,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Can #$scannedSerial checked into dark store queue!'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _waterCanRepo.getDealerCanSummary(dealerId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};

          final deliveredCount = _selectedFilter == 'Today'
              ? (data['todayDelivered'] ?? 0)
              : (data['totalDelivered'] ?? 0);
          final collectedCount = _selectedFilter == 'Today'
              ? (data['todayCollected'] ?? 0)
              : (data['totalCollected'] ?? 0);
          final canBalance = data['canBalance'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Dropdown / Segment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Return Metrics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          items: _filters.map((f) {
                            return DropdownMenuItem(
                              value: f,
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Metric Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        title: 'Full Cans Delivered',
                        value: '$deliveredCount',
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFF0FDF4),
                        icon: Icons.water_drop_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryBox(
                        title: 'Empty Cans Collected',
                        value: '$collectedCount',
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                        icon: Icons.sync_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Can Balance (With Customers) Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Can Balance (With Customers)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$canBalance',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total 20L empty cans pending collection from customers',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => _showCustomerBreakdownSheet(context, dealerId),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF059669), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Recent Can Dispatches & Returns Ledger
                const Text(
                  'Recent Can Exchanges',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<CanTransactionModel>>(
                  stream: _waterCanRepo.getDealerCanLedger(dealerId),
                  builder: (context, ledgerSnapshot) {
                    final txList = ledgerSnapshot.data ?? [];

                    if (txList.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No can exchange transactions recorded yet.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final tx = txList[idx];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0FDF4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync_rounded,
                                  color: Color(0xFF059669),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.userName.isNotEmpty ? tx.userName : 'Customer',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Order #${tx.orderId.length > 8 ? tx.orderId.substring(0, 8).toUpperCase() : tx.orderId.toUpperCase()} • ${AppHelpers.formatDate(tx.createdAt)}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${tx.fullDelivered} Full',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  Text(
                                    '-${tx.emptyCollected} Empty',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: dealer != null
          ? FloatingActionButton.extended(
              onPressed: () => _showWalkInReturnModal(context, dealer),
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text(
                'Record Walk-in Return',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            )
          : null,
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
