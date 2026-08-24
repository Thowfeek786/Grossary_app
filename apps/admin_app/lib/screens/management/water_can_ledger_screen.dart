import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';

class WaterCanLedgerScreen extends StatefulWidget {
  const WaterCanLedgerScreen({super.key});

  @override
  State<WaterCanLedgerScreen> createState() => _WaterCanLedgerScreenState();
}

class _WaterCanLedgerScreenState extends State<WaterCanLedgerScreen> {
  final WaterCanRepository _waterCanRepo = WaterCanRepository();
  String _searchQuery = '';

  void _showRefundDialog() {
    final nameCtrl = TextEditingController();
    final userIdCtrl = TextEditingController();
    final cansCtrl = TextEditingController(text: '1');
    final amountCtrl = TextEditingController(text: '100');
    final notesCtrl = TextEditingController();

    cansCtrl.addListener(() {
      final count = int.tryParse(cansCtrl.text) ?? 1;
      amountCtrl.text = (count * 100).toString();
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.currency_rupee_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text(
              'Process Can Deposit Refund',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Customer User ID / Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cansCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Empty Cans Returned',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Refund Amount (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Admin Notes (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || userIdCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final cans = int.tryParse(cansCtrl.text) ?? 1;
              final refundAmount = double.tryParse(amountCtrl.text) ?? 100.0;

              Navigator.pop(ctx);

              try {
                await _waterCanRepo.processCanDepositRefund(
                  userId: userIdCtrl.text.trim(),
                  userName: nameCtrl.text.trim(),
                  refundAmount: refundAmount,
                  cansReturned: cans,
                  adminNotes: notesCtrl.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deposit refund of ₹${refundAmount.toStringAsFixed(0)} processed successfully!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refund failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Refund', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Platform Can Ledger',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669)),
            tooltip: 'Issue Deposit Refund',
            onPressed: _showRefundDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by Customer Name or Order ID...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Transactions Stream
          Expanded(
            child: StreamBuilder<List<CanTransactionModel>>(
              stream: _waterCanRepo.getAllCanTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }

                final allList = snapshot.data ?? [];
                final filtered = allList.where((tx) {
                  if (_searchQuery.isEmpty) return true;
                  return tx.userName.toLowerCase().contains(_searchQuery) ||
                      tx.orderId.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Can Transactions',
                      subtitle: _searchQuery.isEmpty
                          ? 'Water can exchanges and deliveries will appear here.'
                          : 'No transactions match "$_searchQuery".',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final tx = filtered[idx];
                    final isRefund = tx.exchangeType == CanExchangeType.returnOnly;
                    final isRefill = tx.exchangeType == CanExchangeType.refill;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isRefund
                                          ? const Color(0xFFFEF2F2)
                                          : (isRefill ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isRefund
                                          ? Icons.currency_rupee_rounded
                                          : (isRefill ? Icons.sync_rounded : Icons.water_drop_rounded),
                                      color: isRefund
                                          ? const Color(0xFFEF4444)
                                          : (isRefill ? const Color(0xFF059669) : const Color(0xFF2563EB)),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.userName.isNotEmpty ? tx.userName : 'Customer',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Order #${tx.orderId.length > 8 ? tx.orderId.substring(0, 8).toUpperCase() : tx.orderId.toUpperCase()}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isRefund
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                      : (isRefill
                                          ? const Color(0xFF059669).withValues(alpha: 0.1)
                                          : const Color(0xFF2563EB).withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isRefund ? 'DEPOSIT REFUND' : (isRefill ? 'REFILL EXCHANGE' : 'NEW CAN'),
                                  style: TextStyle(
                                    color: isRefund
                                        ? const Color(0xFFEF4444)
                                        : (isRefill ? const Color(0xFF059669) : const Color(0xFF2563EB)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '+${tx.fullDelivered} Dispatched',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '-${tx.emptyCollected} Returned',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (tx.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              tx.notes,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRefundDialog,
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.currency_rupee_rounded, color: Colors.white),
        label: const Text(
          'Issue Refund',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
