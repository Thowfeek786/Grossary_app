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
    _accHolder = TextEditingController(text: user?.accountHolder ?? '');
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Payout Accounts (Bank & UPI)',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Alert Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Link your Bank Account or UPI ID to receive weekly earnings payouts and manual withdrawal requests.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // UPI Section Card
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
            const Text('Bank Account Information', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Bank Name',
              controller: _bankName,
              hint: 'e.g. HDFC Bank, SBI, ICICI',
              prefixIcon: Icons.account_balance_rounded,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Account Holder Name',
              controller: _accHolder,
              hint: 'Enter full name as per bank passbook',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Account Number',
              controller: _accNumber,
              hint: 'Enter bank account number',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
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
                          Text('Save Payout Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBankDetails() async {
    final auth = context.read<DeliveryAuthProvider>();
    await auth.updateBankDetails(
      bankName: _bankName.text.trim(),
      accountHolder: _accHolder.text.trim(),
      accountNumber: _accNumber.text.trim(),
      ifscCode: _ifscCode.text.trim(),
      upiId: _upiId.text.trim(),
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
