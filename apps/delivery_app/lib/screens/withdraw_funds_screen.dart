import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class WithdrawFundsScreen extends StatefulWidget {
  const WithdrawFundsScreen({super.key});

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final _amountController = TextEditingController();
  final _orderRepo = OrderRepository();
  final _payoutRepo = PayoutRepository();
  final _notifRepo = NotificationRepository();

  bool _isProcessing = false;
  String _selectedMethod = 'bank'; // 'bank' or 'upi'

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    final hasBank = user.bankName != null && user.accountNumber != null && user.accountNumber!.isNotEmpty;
    final hasUpi = user.upiId != null && user.upiId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Withdraw Funds',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderRepo.getOrdersByDeliveryPartner(user.id),
        builder: (context, ordersSnap) {
          final deliveredOrders = (ordersSnap.data ?? []).where((o) => o.status == OrderStatus.delivered).toList();

          double totalEarned = 0.0;
          for (final o in deliveredOrders) {
            totalEarned += o.deliveryFee > 0 ? o.deliveryFee : 45.0;
          }
          if (user.totalEarnings > totalEarned) {
            totalEarned = user.totalEarnings;
          }

          return StreamBuilder<List<PayoutRequestModel>>(
            stream: _payoutRepo.getPartnerPayoutRequests(user.id),
            builder: (context, payoutsSnap) {
              final payouts = payoutsSnap.data ?? [];
              
              // Calculate withdrawn & pending amounts
              double alreadyRequested = 0.0;
              for (final p in payouts) {
                if (p.status.toLowerCase() == 'approved' || p.status.toLowerCase() == 'pending') {
                  alreadyRequested += p.amount;
                }
              }

              final availableBalance = (totalEarned - alreadyRequested) > 0 ? (totalEarned - alreadyRequested) : 0.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Balance Hero Gradient Card
                    _buildBalanceSummary(availableBalance, totalEarned, alreadyRequested),
                    const SizedBox(height: 24),

                    const Text(
                      'Withdrawal Amount',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _amountController,
                      hint: 'Enter amount to withdraw (min ₹100)',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Quick Amount Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [100, 500, 1000, 2000].map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text('₹$amt'),
                              onPressed: () {
                                _amountController.text = amt.toString();
                              },
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                          );
                        }).toList()
                          ..add(
                            Padding(
                              padding: EdgeInsets.zero,
                              child: ActionChip(
                                label: const Text('Withdraw All'),
                                onPressed: () {
                                  _amountController.text = availableBalance > 0 ? availableBalance.toStringAsFixed(0) : '0';
                                },
                                backgroundColor: const Color(0xFF059669).withValues(alpha: 0.1),
                                side: const BorderSide(color: Color(0xFF6EE7B7)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF059669)),
                              ),
                            ),
                          ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text(
                      'Payout Destination Method',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),

                    // Method Selector Toggle Cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMethod = 'bank'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedMethod == 'bank' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                  width: _selectedMethod == 'bank' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_rounded, color: _selectedMethod == 'bank' ? const Color(0xFF059669) : const Color(0xFF64748B), size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Bank Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMethod = 'upi'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedMethod == 'upi' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                  width: _selectedMethod == 'upi' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code_2_rounded, color: _selectedMethod == 'upi' ? const Color(0xFF059669) : const Color(0xFF64748B), size: 20),
                                  const SizedBox(width: 8),
                                  const Text('UPI ID (VPA)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildSelectedDestinationCard(context, user, hasBank, hasUpi),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handleWithdrawal(user, availableBalance),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Submit Payout Request', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Live Payout Requests History List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Payout Requests',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${payouts.length} records',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRequestsList(payouts),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBalanceSummary(double availableBalance, double totalEarned, double requested) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B3C26).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVAILABLE FOR WITHDRAWAL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF86EFAC), letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${availableBalance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Lifetime', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('₹${totalEarned.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(width: 1, height: 24, color: Colors.white24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Withdrawn / Pending', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('₹${requested.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDestinationCard(BuildContext context, UserModel user, bool hasBank, bool hasUpi) {
    if (_selectedMethod == 'upi') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UPI ID (VPA)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(
                    hasUpi ? user.upiId! : 'No UPI ID linked yet',
                    style: TextStyle(fontSize: 12, color: hasUpi ? const Color(0xFF64748B) : const Color(0xFFEF4444), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/bank-details'),
              child: Text(hasUpi ? 'Edit' : 'Add UPI', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasBank ? user.bankName! : 'No Bank Account Linked', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(
                    hasBank ? 'A/C: ••••${user.accountNumber!.length > 4 ? user.accountNumber!.substring(user.accountNumber!.length - 4) : user.accountNumber} • IFSC: ${user.ifscCode}' : 'Update bank details in profile first',
                    style: TextStyle(fontSize: 11.5, color: hasBank ? const Color(0xFF64748B) : const Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/bank-details'),
              child: Text(hasBank ? 'Edit' : 'Add Bank', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRequestsList(List<PayoutRequestModel> requests) {
    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No previous payout requests recorded yet.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // Sort descending by createdAt
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final req = requests[i];
        final status = req.status.toLowerCase();
        final isApproved = status == 'approved';
        final isPending = status == 'pending';

        final statusColor = isApproved ? const Color(0xFF059669) : (isPending ? const Color(0xFFD97706) : const Color(0xFFEF4444));
        final statusBg = isApproved ? const Color(0xFF10B981).withValues(alpha: 0.12) : (isPending ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12));

        final isUpi = req.payoutMethod == 'upi' || (req.upiId != null && req.upiId!.isNotEmpty);
        final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(req.createdAt);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isApproved ? Icons.check_circle_rounded : (isPending ? Icons.pending_actions_rounded : Icons.cancel_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isUpi ? 'UPI Transfer' : 'Bank Transfer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUpi ? (req.upiId ?? 'UPI VPA') : '${req.bankName} • ••••${req.accountNumber.length > 4 ? req.accountNumber.substring(req.accountNumber.length - 4) : req.accountNumber}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(formattedDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                  ],
                ),
              ),
              Text('₹${req.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleWithdrawal(UserModel user, double availableBalance) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount to withdraw');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid numeric amount');
      return;
    }

    if (amount < 100) {
      _showError('Minimum withdrawal amount is ₹100');
      return;
    }

    if (amount > availableBalance) {
      _showError('Insufficient balance. Available: ₹${availableBalance.toStringAsFixed(0)}');
      return;
    }

    if (_selectedMethod == 'upi') {
      if (user.upiId == null || user.upiId!.isEmpty) {
        _showError('Please enter your UPI ID in Bank & UPI details first');
        return;
      }
    } else {
      if (user.bankName == null || user.accountNumber == null || user.accountNumber!.isEmpty) {
        _showError('Please update your bank details first before requesting payout');
        return;
      }
    }

    setState(() => _isProcessing = true);
    try {
      final request = PayoutRequestModel(
        id: '',
        partnerId: user.id,
        partnerName: user.name.isNotEmpty ? user.name : 'Delivery Partner',
        partnerPhone: user.phone,
        bankName: user.bankName ?? '',
        accountNumber: user.accountNumber ?? '',
        ifscCode: user.ifscCode ?? '',
        upiId: user.upiId,
        payoutMethod: _selectedMethod,
        amount: amount,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _payoutRepo.requestPayout(request);

      // Create Admin Notification
      await _notifRepo.sendNotification(
        NotificationModel(
          id: '',
          userId: 'broadcast_admin_notifications',
          title: '💳 New Partner Payout Request: ₹${amount.toStringAsFixed(0)}',
          body: '${user.name.isNotEmpty ? user.name : "Partner"} requested ₹${amount.toStringAsFixed(0)} via ${_selectedMethod.toUpperCase()}.',
          type: 'payout',
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _amountController.clear();
        _showSuccess('🎉 Payout request of ₹${amount.toStringAsFixed(0)} via ${_selectedMethod.toUpperCase()} submitted successfully!');
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
