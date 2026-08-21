import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  late TextEditingController _bankName;
  late TextEditingController _accHolder;
  late TextEditingController _accNumber;
  late TextEditingController _ifscCode;
  late TextEditingController _upiId;

  @override
  void initState() {
    super.initState();
    final user = context.read<DeliveryAuthProvider>().user;
    _bankName = TextEditingController(text: user?.bankName ?? '');
    _accHolder = TextEditingController(text: user?.accountHolder ?? (user?.name ?? ''));
    _accNumber = TextEditingController(text: user?.accountNumber ?? '');
    _ifscCode = TextEditingController(text: user?.ifscCode ?? '');
    _upiId = TextEditingController(text: user?.upiId ?? '');
  }

  @override
  void dispose() {
    _bankName.dispose();
    _accHolder.dispose();
    _accNumber.dispose();
    _ifscCode.dispose();
    _upiId.dispose();
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

    final hasBank = user.bankName != null && user.bankName!.isNotEmpty && user.accountNumber != null && user.accountNumber!.isNotEmpty;
    final hasUpi = user.upiId != null && user.upiId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Payout Accounts',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emerald Virtual Account Card Preview
            _buildVirtualAccountCard(user, hasBank, hasUpi),
            const SizedBox(height: 20),

            // Security Info Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your payout credentials are encrypted. Earnings are credited directly to your saved bank or UPI ID.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.35, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // UPI Section
            const Text('UPI Instant Payout (VPA)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            AppTextField(
              label: 'UPI ID (Virtual Payment Address)',
              controller: _upiId,
              hint: 'e.g. drivername@okaxis, 9876543210@paytm',
              prefixIcon: Icons.qr_code_2_rounded,
            ),

            const SizedBox(height: 28),

            // Bank Account Section
            const Text('Bank Account Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Bank Name',
              controller: _bankName,
              hint: 'e.g. HDFC Bank, SBI, ICICI, Axis Bank',
              prefixIcon: Icons.account_balance_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Account Holder Name',
              controller: _accHolder,
              hint: 'Enter full name as per bank passbook',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Account Number',
              controller: _accNumber,
              hint: 'Enter bank account number',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'IFSC Code',
              controller: _ifscCode,
              hint: 'e.g. HDFC0001234',
              prefixIcon: Icons.code_rounded,
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _saveBankDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Save Payout Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualAccountCard(dynamic user, bool hasBank, bool hasUpi) {
    final accNum = user.accountNumber ?? '';
    final maskedNum = accNum.length > 4 ? '•••• •••• •••• ${accNum.substring(accNum.length - 4)}' : (accNum.isNotEmpty ? accNum : '•••• •••• •••• ••••');
    final holderName = (user.accountHolder != null && user.accountHolder!.isNotEmpty) ? user.accountHolder! : (user.name.isNotEmpty ? user.name : 'PARTNER NAME');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF062316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3C26).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasBank ? (user.bankName!.toUpperCase()) : 'GROCERYGO PAYOUT',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (hasBank || hasUpi) ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (hasBank || hasUpi) ? 'ACTIVE' : 'NOT LINKED',
                  style: TextStyle(
                    color: (hasBank || hasUpi) ? const Color(0xFF4ADE80) : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            maskedNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACCOUNT HOLDER', style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(holderName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                ],
              ),
              if (hasUpi)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('UPI VPA', style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(user.upiId!, style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                )
              else if (hasBank && user.ifscCode != null && user.ifscCode!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('IFSC CODE', style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(user.ifscCode!.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveBankDetails() async {
    final ifsc = _ifscCode.text.trim().toUpperCase();
    final upi = _upiId.text.trim();
    final acc = _accNumber.text.trim();
    final bank = _bankName.text.trim();
    final holder = _accHolder.text.trim();

    if (upi.isEmpty && (acc.isEmpty || bank.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least a UPI ID or Bank Account number'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final auth = context.read<DeliveryAuthProvider>();
    await auth.updateBankDetails(
      bankName: bank,
      accountHolder: holder,
      accountNumber: acc,
      ifscCode: ifsc,
      upiId: upi,
    );

    if (mounted) {
      if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error!),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Bank & UPI details updated successfully!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
