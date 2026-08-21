import 'package:flutter/material.dart';
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
    final balance = user.totalEarnings;

    final hasBank = user.bankName != null && user.accountNumber != null && user.accountNumber!.isNotEmpty;
    final hasUpi = user.upiId != null && user.upiId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Withdraw Funds',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance Hero Gradient Card
            _buildBalanceSummary(balance),
            const SizedBox(height: 28),

            const Text('Withdrawal Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
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
                children: [500, 1000, 2000].map((amt) {
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
                          _amountController.text = balance.toStringAsFixed(0);
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
            const Text('Payout Destination Method', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
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
            _buildSelectedDestinationCard(user, hasBank, hasUpi),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _handleWithdrawal(balance),
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
            const Text('Recent Payout Requests', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildRequestsList(user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: [
          const Text(
            'AVAILABLE FOR WITHDRAWAL',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDestinationCard(dynamic user, bool hasBank, bool hasUpi) {
    if (_selectedMethod == 'upi') {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  Text(
                    hasUpi ? user!.upiId! : 'No UPI ID linked yet',
                    style: TextStyle(fontSize: 12, color: hasUpi ? const Color(0xFF64748B) : const Color(0xFFEF4444), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  Text(hasBank ? user!.bankName! : 'No bank linked', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                  Text(
                    hasBank ? 'A/C: ****${user!.accountNumber!.substring(user.accountNumber!.length > 4 ? user.accountNumber!.length - 4 : 0)} • IFSC: ${user.ifscCode}' : 'Update bank details in profile first',
                    style: TextStyle(fontSize: 12, color: hasBank ? const Color(0xFF64748B) : const Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRequestsList(String partnerId) {
    return StreamBuilder<List<PayoutRequestModel>>(
      stream: PayoutRepository().getPartnerPayoutRequests(partnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No previous payout requests.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final req = requests[i];
            Color statusBg;
            Color statusText;

            if (req.status == 'approved') {
              statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
              statusText = const Color(0xFF059669);
            } else if (req.status == 'rejected') {
              statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
              statusText = const Color(0xFFEF4444);
            } else {
              statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
              statusText = const Color(0xFFD97706);
            }

            final isUpi = req.payoutMethod == 'upi' || (req.upiId != null && req.upiId!.isNotEmpty);

            return Container(
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
                      color: statusText,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isUpi ? 'UPI Payout' : 'Bank Payout', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                        Text(
                          isUpi ? (req.upiId ?? 'UPI VPA') : '${req.bankName} • ****${req.accountNumber.length > 4 ? req.accountNumber.substring(req.accountNumber.length - 4) : req.accountNumber}',
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
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.status.toUpperCase(),
                          style: TextStyle(color: statusText, fontSize: 9, fontWeight: FontWeight.w900),
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
    );
  }

  Future<void> _handleWithdrawal(double balance) async {
    final auth = context.read<DeliveryAuthProvider>();
    final user = auth.user;

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

    if (amount > balance) {
      _showError('Insufficient partner balance');
      return;
    }

    if (_selectedMethod == 'upi') {
      if (user?.upiId == null || user!.upiId!.isEmpty) {
        _showError('Please enter your UPI ID in Bank & UPI details first');
        return;
      }
    } else {
      if (user?.bankName == null || user?.accountNumber == null || user!.accountNumber!.isEmpty) {
        _showError('Please update your bank details first before requesting payout');
        return;
      }
    }

    setState(() => _isProcessing = true);
    try {
      final request = PayoutRequestModel(
        id: '',
        partnerId: user.id,
        partnerName: user.name,
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

      await PayoutRepository().requestPayout(request);

      if (mounted) {
        setState(() => _isProcessing = false);
        _amountController.clear();
        _showSuccess('🎉 Payout request of ₹${amount.toStringAsFixed(0)} via ${_selectedMethod.toUpperCase()} submitted!');
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
