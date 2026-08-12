import 'package:flutter/material.dart';
import 'package:repository/repository.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_drawer.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen>
    with SingleTickerProviderStateMixin {
  final _paymentRepo = PaymentRepository();
  late TabController _tabController;

  String _filterGateway = 'All';
  String _searchQuery = '';

  // Setup Form Controllers
  final _upiIdCtrl = TextEditingController();
  final _merchantNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  bool _enableCod = true;
  bool _enableUpi = true;
  bool _enableWallet = true;
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiIdCtrl.dispose();
    _merchantNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  void _savePaymentSettings() async {
    setState(() => _isSavingSettings = true);
    try {
      final settings = AdminPaymentSettings(
        upiId: _upiIdCtrl.text.trim(),
        merchantName: _merchantNameCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accNoCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim(),
        enableCod: _enableCod,
        enableUpi: _enableUpi,
        enableWallet: _enableWallet,
      );
      await _paymentRepo.updatePaymentSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment gateway configuration saved!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  void _showRefundModal(PaymentTransaction tx) {
    final reasonCtrl =
        TextEditingController(text: 'Customer requested refund');
    final amountCtrl =
        TextEditingController(text: tx.amount.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_exchange_rounded,
                      color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund Order #${tx.orderId.substring(0, tx.orderId.length > 8 ? 8 : tx.orderId.length).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text('Credit refund amount directly to customer wallet',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Refund Amount (₹)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Reason for Refund',
                prefixIcon: const Icon(Icons.notes_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final refAmount = double.tryParse(amountCtrl.text);
                  if (refAmount == null || refAmount <= 0) return;

                  Navigator.pop(ctx);
                  final success = await _paymentRepo.refundToUserWallet(
                    transactionId: tx.id,
                    userId: tx.userId ?? '',
                    orderId: tx.orderId,
                    amount: refAmount,
                    reason: reasonCtrl.text.trim(),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Refund of ₹$refAmount credited to customer wallet!'
                            : 'Failed to process refund'),
                        backgroundColor: success
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Process Instant Refund',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Payment Center & Setup',
          style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Transactions & Refunds'),
            Tab(text: 'UPI & Gateway Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildConfigurationTab(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Filter & Search Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by Order ID or User...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['All', 'UPI', 'Razorpay', 'Stripe', 'Wallet', 'COD']
                          .map((g) {
                    final selected = _filterGateway == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: selected,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF0F172A),
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) =>
                            setState(() => _filterGateway = val ? g : 'All'),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Transactions Feed
        Expanded(
          child: StreamBuilder<List<PaymentTransaction>>(
            stream: _paymentRepo.streamAllTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                );
              }
              var txs = snapshot.data ?? [];

              if (_filterGateway != 'All') {
                txs = txs
                    .where((t) =>
                        t.gateway.name.toLowerCase() ==
                        _filterGateway.toLowerCase())
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                txs = txs
                    .where((t) =>
                        t.orderId.toLowerCase().contains(_searchQuery) ||
                        (t.userName?.toLowerCase().contains(_searchQuery) ??
                            false))
                    .toList();
              }

              if (txs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No payment transactions found',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: txs.length,
                itemBuilder: (context, i) {
                  final tx = txs[i];
                  final isSuccess = tx.status == 'success';
                  final isRefunded = tx.status == 'refunded';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSuccess
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.12)
                                    : (isRefunded
                                        ? const Color(0xFFEF4444)
                                            .withValues(alpha: 0.12)
                                        : const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isSuccess
                                    ? Icons.check_circle_rounded
                                    : (isRefunded
                                        ? Icons.refresh_rounded
                                        : Icons.pending_rounded),
                                color: isSuccess
                                    ? const Color(0xFF059669)
                                    : (isRefunded
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFD97706)),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #${tx.orderId.substring(0, tx.orderId.length > 8 ? 8 : tx.orderId.length).toUpperCase()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${tx.gateway.name.toUpperCase()} · ${DateFormat('MMM dd, hh:mm a').format(tx.createdAt)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${tx.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSuccess
                                        ? const Color(0xFF10B981)
                                            .withValues(alpha: 0.12)
                                        : (isRefunded
                                            ? const Color(0xFFEF4444)
                                                .withValues(alpha: 0.12)
                                            : const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.12)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tx.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isSuccess
                                          ? const Color(0xFF059669)
                                          : (isRefunded
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isSuccess && (tx.userId?.isNotEmpty ?? false)) ...[
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Customer: ${tx.userName ?? 'User'}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showRefundModal(tx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(
                                      color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.replay_rounded, size: 14),
                                label: const Text('Issue Refund',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
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
    );
  }

  Widget _buildConfigurationTab() {
    return StreamBuilder<AdminPaymentSettings>(
      stream: _paymentRepo.streamPaymentSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final s = snapshot.data!;
          if (_upiIdCtrl.text.isEmpty) _upiIdCtrl.text = s.upiId;
          if (_merchantNameCtrl.text.isEmpty) {
            _merchantNameCtrl.text = s.merchantName;
          }
          if (_bankNameCtrl.text.isEmpty) _bankNameCtrl.text = s.bankName;
          if (_accNoCtrl.text.isEmpty) _accNoCtrl.text = s.accountNumber;
          if (_ifscCtrl.text.isEmpty) _ifscCtrl.text = s.ifscCode;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Admin UPI Details
              const Text(
                'Store UPI & Direct Payment Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'These details are dynamically loaded during customer checkout for GPay, PhonePe, Paytm & QR Code payments.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _upiIdCtrl,
                        decoration: InputDecoration(
                          labelText: 'Admin UPI ID (VPA)',
                          hintText: 'e.g. merchant@upi',
                          prefixIcon: const Icon(Icons.qr_code_2_rounded,
                              color: Color(0xFF6366F1)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _merchantNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Merchant Name',
                          hintText: 'e.g. GroceryGo Official Store',
                          prefixIcon: const Icon(Icons.store_rounded,
                              color: Color(0xFF6366F1)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section 2: Bank Account Details
              const Text(
                'Bank Account Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _bankNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Bank Name',
                          prefixIcon: const Icon(Icons.account_balance_rounded,
                              color: Color(0xFF10B981)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _accNoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          prefixIcon: const Icon(Icons.numbers_rounded,
                              color: Color(0xFF10B981)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ifscCtrl,
                        decoration: InputDecoration(
                          labelText: 'IFSC Code',
                          prefixIcon: const Icon(Icons.code_rounded,
                              color: Color(0xFF10B981)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section 3: Enabled Payment Gateways
              const Text(
                'Enabled Payment Gateways',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('UPI & Instant QR Payments',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('GPay, PhonePe, Paytm & QR Code'),
                      value: _enableUpi,
                      activeThumbColor: const Color(0xFF6366F1),
                      onChanged: (val) => setState(() => _enableUpi = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('GroceryGo Wallet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Pay using pre-stored wallet balance'),
                      value: _enableWallet,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _enableWallet = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Cash / Pay on Delivery (COD)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Pay cash or UPI upon delivery'),
                      value: _enableCod,
                      activeThumbColor: const Color(0xFFF59E0B),
                      onChanged: (val) => setState(() => _enableCod = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Settings Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSavingSettings ? null : _savePaymentSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSavingSettings
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save Gateway Configuration',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
