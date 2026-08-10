import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _filterGateway = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Payment Transactions'),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Razorpay', 'Stripe', 'COD', 'Wallet'].map((g) {
                  final selected = _filterGateway == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.grey100,
                      onSelected: (val) => setState(() => _filterGateway = val ? g : 'All'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('payments').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                var docs = snap.data?.docs ?? [];
                if (_filterGateway != 'All') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final gateway = (data['gateway'] ?? '').toString().toLowerCase();
                    return gateway == _filterGateway.toLowerCase();
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No Payment Transactions',
                    subtitle: 'Completed or pending payment transactions will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final orderId = data['orderId'] ?? '';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final gateway = data['gateway'] ?? 'COD';
                    final status = data['status'] ?? 'pending';

                    final isSuccess = status == 'success';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSuccess ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSuccess ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: isSuccess ? AppColors.success : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order #${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                Text('Gateway: ${gateway.toString().toUpperCase()}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                              Text(status.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isSuccess ? AppColors.success : AppColors.warning)),
                            ],
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
  }
}
