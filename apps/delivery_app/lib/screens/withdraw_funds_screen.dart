import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class WithdrawFundsScreen extends StatefulWidget {
  const WithdrawFundsScreen({super.key});

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    final balance = user?.totalEarnings ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Withdraw Funds'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceSummary(balance),
            const SizedBox(height: 32),
            const Text('Withdrawal Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              hint: 'Enter amount to withdraw',
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildBankPreview(user),
            const SizedBox(height: 48),
            AppButton(
              label: 'Request Withdrawal',
              isLoading: _isProcessing,
              onTap: () => _handleWithdrawal(balance),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Funds are typically processed within 24-48 hours.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
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
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('AVAILABLE FOR WITHDRAWAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBankPreview(dynamic user) {
    final hasBank = user?.bankName != null && user?.accountNumber != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RECIPIENT BANK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
              if (!hasBank)
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          if (hasBank) ...[
            Text(user!.bankName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('A/C: ****${user.accountNumber!.substring(user.accountNumber!.length > 4 ? user.accountNumber!.length - 4 : 0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ] else ...[
            const Text('No bank account linked', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.error)),
            const Text('Please update your bank details first', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _handleWithdrawal(double balance) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount > balance) {
      _showError('Insufficient balance');
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2)); // Mock API delay
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _showSuccess('Withdrawal request submitted successfully!');
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  }
}
