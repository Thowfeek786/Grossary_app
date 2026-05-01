import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<DeliveryAuthProvider>().user;
    _bankName = TextEditingController(text: user?.bankName ?? '');
    _accHolder = TextEditingController(text: user?.accountHolder ?? '');
    _accNumber = TextEditingController(text: user?.accountNumber ?? '');
    _ifscCode = TextEditingController(text: user?.ifscCode ?? '');
  }

  @override
  void dispose() {
    _bankName.dispose();
    _accHolder.dispose();
    _accNumber.dispose();
    _ifscCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Bank Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlertBox(
              type: AlertType.info,
              message: 'Earnings will be credited to this account every Monday.',
            ),
            const SizedBox(height: 32),
            AppTextField(label: 'Bank Name', controller: _bankName, hint: 'e.g. HDFC Bank'),
            const SizedBox(height: 16),
            AppTextField(label: 'Account Holder Name', controller: _accHolder, hint: 'Enter name as per bank'),
            const SizedBox(height: 16),
            AppTextField(label: 'Account Number', controller: _accNumber, hint: 'Enter account number'),
            const SizedBox(height: 16),
            AppTextField(label: 'IFSC Code', controller: _ifscCode, hint: 'e.g. HDFC0001234'),
            const SizedBox(height: 48),
            AppButton(
              label: 'Update Bank Details',
              isLoading: auth.isLoading,
              onTap: () async {
                await auth.updateBankDetails(
                  bankName: _bankName.text.trim(),
                  accountHolder: _accHolder.text.trim(),
                  accountNumber: _accNumber.text.trim(),
                  ifscCode: _ifscCode.text.trim(),
                );
                if (mounted) {
                  if (auth.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bank details updated successfully'), backgroundColor: AppColors.success),
                    );
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
