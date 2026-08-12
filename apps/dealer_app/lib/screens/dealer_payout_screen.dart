import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class DealerPayoutScreen extends StatefulWidget {
  const DealerPayoutScreen({super.key});

  @override
  State<DealerPayoutScreen> createState() => _DealerPayoutScreenState();
}

class _DealerPayoutScreenState extends State<DealerPayoutScreen> {
  final _amountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _acNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  String _payoutMethod = 'upi'; // 'bank' or 'upi'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<DealerAuthProvider>().user;
    if (user != null) {
      _bankCtrl.text = user.bankName ?? '';
      _acNoCtrl.text = user.accountNumber ?? '';
      _ifscCtrl.text = user.ifscCode ?? '';
      _upiCtrl.text = user.upiId ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankCtrl.dispose();
    _acNoCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPayout(UserModel user) async {
    final amtStr = _amountCtrl.text.trim();
    final amount = double.tryParse(amtStr);

    if (amount == null || amount < 100) {
      _showError('Minimum payout request amount is ₹100');
      return;
    }

    if (_payoutMethod == 'upi') {
      if (_upiCtrl.text.trim().isEmpty) {
        _showError('Please enter a valid UPI VPA ID (e.g. store@okaxis)');
        return;
      }
    } else {
      if (_bankCtrl.text.trim().isEmpty || _acNoCtrl.text.trim().isEmpty || _ifscCtrl.text.trim().isEmpty) {
        _showError('Please fill in complete bank account details');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final request = PayoutRequestModel(
        id: '',
        partnerId: user.id,
        partnerName: user.shopName ?? user.name,
        partnerPhone: user.phone,
        bankName: _bankCtrl.text.trim(),
        accountNumber: _acNoCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim(),
        upiId: _upiCtrl.text.trim(),
        payoutMethod: _payoutMethod,
        amount: amount,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await PayoutRepository().requestPayout(request);

      if (mounted) {
        setState(() => _isProcessing = false);
        _amountCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Store Payout request of ₹${amount.toStringAsFixed(0)} via ${_payoutMethod.toUpperCase()} submitted!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Failed to submit payout request: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Vendor Earnings Settlement',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payout Form Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Manual Payout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text('Transfer your store sales balance directly to your bank account or UPI VPA.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Withdrawal Amount (₹)',
                    hint: 'e.g. 1500 (Minimum ₹100)',
                    controller: _amountCtrl,
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 18),

                  const Text('Select Payout Destination', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('UPI VPA 📲')),
                          selected: _payoutMethod == 'upi',
                          onSelected: (selected) {
                            if (selected) setState(() => _payoutMethod = 'upi');
                          },
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(color: _payoutMethod == 'upi' ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Bank Account 🏦')),
                          selected: _payoutMethod == 'bank',
                          onSelected: (selected) {
                            if (selected) setState(() => _payoutMethod = 'bank');
                          },
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(color: _payoutMethod == 'bank' ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_payoutMethod == 'upi') ...[
                    AppTextField(
                      label: 'UPI ID (VPA)',
                      hint: 'e.g. store@okaxis',
                      controller: _upiCtrl,
                      prefixIcon: Icons.qr_code_2_rounded,
                    ),
                  ] else ...[
                    AppTextField(
                      label: 'Bank Name',
                      hint: 'e.g. HDFC Bank',
                      controller: _bankCtrl,
                      prefixIcon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Account Number',
                      hint: 'e.g. 501002345678',
                      controller: _acNoCtrl,
                      prefixIcon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'IFSC Code',
                      hint: 'e.g. HDFC0001234',
                      controller: _ifscCtrl,
                      prefixIcon: Icons.badge_outlined,
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _requestPayout(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Payout Request', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payout History Stream
            const Text('Payout History & Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            StreamBuilder<List<PayoutRequestModel>>(
              stream: PayoutRepository().getPartnerPayoutRequests(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 36, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text('No payout requests yet', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          Text('Submitted withdrawal requests will appear here', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: requests.map((req) {
                    final isUpi = req.payoutMethod == 'upi' || (req.upiId != null && req.upiId!.isNotEmpty);
                    Color statusColor = const Color(0xFFD97706);
                    Color statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);

                    if (req.status == 'approved') {
                      statusColor = const Color(0xFF059669);
                      statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
                    } else if (req.status == 'rejected') {
                      statusColor = const Color(0xFFEF4444);
                      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              req.status == 'approved'
                                  ? Icons.check_circle_rounded
                                  : req.status == 'rejected'
                                      ? Icons.cancel_rounded
                                      : Icons.schedule_rounded,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isUpi ? 'UPI Withdrawal' : 'Bank Transfer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                                Text(
                                  isUpi ? (req.upiId ?? 'UPI VPA') : '${req.bankName} • ${req.accountNumber}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${req.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                                child: Text(req.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
