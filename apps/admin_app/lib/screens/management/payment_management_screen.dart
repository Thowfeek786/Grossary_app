import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repository/repository.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_order_detail_screen.dart';

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
  String _filterStatus = 'All';
  String _searchQuery = '';

  // Setup Form Controllers
  final _upiIdCtrl = TextEditingController();
  final _merchantNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accHolderCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  bool _enableCod = true;
  bool _enableUpi = true;
  bool _enableWallet = true;
  bool _isLoadingSettings = true;
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    try {
      final s = await _paymentRepo.getPaymentSettings();
      _upiIdCtrl.text = s.upiId;
      _merchantNameCtrl.text = s.merchantName;
      _bankNameCtrl.text = s.bankName;
      _accNoCtrl.text = s.accountNumber;
      _ifscCtrl.text = s.ifscCode;
      _enableCod = s.enableCod;
      _enableUpi = s.enableUpi;
      _enableWallet = s.enableWallet;
    } catch (e) {
      debugPrint('Error loading payment settings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiIdCtrl.dispose();
    _merchantNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accHolderCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePaymentSettings() async {
    if (_upiIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Admin UPI ID (VPA)'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _isSavingSettings = true);
    try {
      final settings = AdminPaymentSettings(
        upiId: _upiIdCtrl.text.trim(),
        merchantName: _merchantNameCtrl.text.trim().isNotEmpty ? _merchantNameCtrl.text.trim() : 'GroceryGo Official Store',
        bankName: _bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : 'HDFC Bank',
        accountNumber: _accNoCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim().toUpperCase(),
        enableCod: _enableCod,
        enableUpi: _enableUpi,
        enableWallet: _enableWallet,
      );
      await _paymentRepo.updatePaymentSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Payment Gateway & UPI configuration saved!'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _testUpiIntent() async {
    final upiId = _upiIdCtrl.text.trim();
    final name = Uri.encodeComponent(_merchantNameCtrl.text.trim());
    if (upiId.isEmpty) return;

    final uri = Uri.parse('upi://pay?pa=$upiId&pn=$name&am=1.00&cu=INR&tn=TestPayment');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('UPI Test: $e. Ensure a UPI app (GPay/PhonePe/Paytm) is installed.'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRefundModal(PaymentTransaction tx) {
    final reasonCtrl = TextEditingController(text: 'Customer requested refund');
    final amountCtrl = TextEditingController(text: tx.amount.toStringAsFixed(0));
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(modalCtx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded,
                        color: Color(0xFFEF4444), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refund Order #${tx.orderId.substring(0, tx.orderId.length > 8 ? 8 : tx.orderId.length).toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const Text('Credit refund amount directly to customer wallet',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Reason for Refund',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final refAmount = double.tryParse(amountCtrl.text);
                          if (refAmount == null || refAmount <= 0) return;

                          setModalState(() => isProcessing = true);
                          final success = await _paymentRepo.refundToUserWallet(
                            transactionId: tx.id,
                            userId: tx.userId ?? '',
                            orderId: tx.orderId,
                            amount: refAmount,
                            reason: reasonCtrl.text.trim(),
                          );

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '🎉 Refund of ₹$refAmount credited to customer wallet!'
                                    : 'Failed to process refund'),
                                backgroundColor: success
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Process Instant Refund', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(PaymentTransaction tx) {
    final dateStr = DateFormat('dd MMMM yyyy, hh:mm a').format(tx.createdAt);
    final shortOrderId = tx.orderId.length > 8 ? tx.orderId.substring(0, 8).toUpperCase() : tx.orderId.toUpperCase();
    final statusColor = _getStatusColor(tx.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction #${tx.id.length > 8 ? tx.id.substring(0, 8).toUpperCase() : tx.id.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tx.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Amount Paid', '₹${tx.amount.toStringAsFixed(0)}', isBold: true),
                  if (tx.walletAmountUsed > 0) ...[
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildDetailRow('Wallet Balance Used', '₹${tx.walletAmountUsed.toStringAsFixed(0)}'),
                  ],
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  _buildDetailRow('Payment Method', tx.gateway.name.toUpperCase()),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  _buildDetailRow('Order Reference', '#$shortOrderId', isCopyable: true, copyValue: tx.orderId),
                  if (tx.userName != null && tx.userName!.isNotEmpty) ...[
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildDetailRow('Customer Name', tx.userName!),
                  ],
                  if (tx.transactionId != null && tx.transactionId!.isNotEmpty) ...[
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildDetailRow('Gateway Txn ID', tx.transactionId!, isCopyable: true, copyValue: tx.transactionId!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: tx.orderId)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('View Order', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                if (tx.status != 'refunded') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRefundModal(tx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.currency_exchange_rounded, size: 18),
                      label: const Text('Refund', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isCopyable = false, String? copyValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w600)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                fontSize: isBold ? 15 : 13,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _copyToClipboard(copyValue ?? value, label),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'refunded':
        return const Color(0xFF6366F1);
      case 'failed':
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Center & Setup',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Live Transactions & Refunds'),
            Tab(text: 'UPI & Gateway Setup'),
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
    return StreamBuilder<List<PaymentTransaction>>(
      stream: _paymentRepo.streamAllTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        final allTxs = snapshot.data ?? [];

        // Compute metrics
        double totalVolume = 0;
        double onlineVolume = 0;
        double codVolume = 0;
        double refundedVolume = 0;

        for (final tx in allTxs) {
          if (tx.status == 'success' || tx.status == 'paid') {
            totalVolume += tx.amount;
            if (tx.gateway == PaymentGateway.cod) {
              codVolume += tx.amount;
            } else {
              onlineVolume += tx.amount;
            }
          } else if (tx.status == 'refunded') {
            refundedVolume += tx.amount;
          }
        }

        // Apply filters
        final filteredTxs = allTxs.where((tx) {
          if (_filterGateway != 'All' && tx.gateway.name.toLowerCase() != _filterGateway.toLowerCase()) {
            return false;
          }
          if (_filterStatus != 'All' && tx.status.toLowerCase() != _filterStatus.toLowerCase()) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchesOrder = tx.orderId.toLowerCase().contains(q);
            final matchesUser = (tx.userName ?? '').toLowerCase().contains(q);
            final matchesTx = (tx.transactionId ?? '').toLowerCase().contains(q);
            if (!matchesOrder && !matchesUser && !matchesTx) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Top Analytics Row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Volume',
                      '₹${totalVolume.toStringAsFixed(0)}',
                      Icons.payments_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Online / UPI',
                      '₹${onlineVolume.toStringAsFixed(0)}',
                      Icons.qr_code_rounded,
                      const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'COD Collected',
                      '₹${codVolume.toStringAsFixed(0)}',
                      Icons.local_shipping_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Refunds',
                      '₹${refundedVolume.toStringAsFixed(0)}',
                      Icons.currency_exchange_rounded,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),

            // Search and Filters Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search Order ID, Customer, or Txn ID...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'UPI', 'Wallet', 'COD', 'Razorpay', 'Stripe'].map((g) {
                        final selected = _filterGateway == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: selected,
                            selectedColor: const Color(0xFF0F172A),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 11.5,
                            ),
                            onSelected: (val) => setState(() => _filterGateway = val ? g : 'All'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Success', 'Pending', 'Refunded', 'Failed'].map((s) {
                        final selected = _filterStatus == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(s),
                            selected: selected,
                            selectedColor: const Color(0xFF38BDF8),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                              fontSize: 11,
                            ),
                            onSelected: (val) => setState(() => _filterStatus = val ? s : 'All'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: filteredTxs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text('No transactions match your criteria', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTxs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final tx = filteredTxs[i];
                        final statusColor = _getStatusColor(tx.status);
                        final dateStr = DateFormat('dd MMM, hh:mm a').format(tx.createdAt);
                        final shortOrderId = tx.orderId.length > 8 ? tx.orderId.substring(0, 8).toUpperCase() : tx.orderId.toUpperCase();

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _showTransactionDetails(tx),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      tx.gateway == PaymentGateway.upi
                                          ? Icons.qr_code_2_rounded
                                          : (tx.gateway == PaymentGateway.wallet
                                              ? Icons.account_balance_wallet_rounded
                                              : Icons.payments_rounded),
                                      color: statusColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('#$shortOrderId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(tx.gateway.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 9.5, color: Color(0xFF475569))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('${tx.userName ?? "Customer"} • $dateStr', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${tx.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                                      Text(tx.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
          Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.white60, fontWeight: FontWeight.w600), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    final upiUrl = 'upi://pay?pa=${_upiIdCtrl.text.trim()}&pn=${Uri.encodeComponent(_merchantNameCtrl.text.trim())}&cu=INR';
    final qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(upiUrl)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Dynamic QR Preview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: qrApiUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, _, _) => const Icon(Icons.qr_code_2_rounded, size: 60, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 18),
                          SizedBox(width: 6),
                          Text('Direct UPI Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _upiIdCtrl.text.isNotEmpty ? _upiIdCtrl.text : 'sthowfeek65@okaxis',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _merchantNameCtrl.text.isNotEmpty ? _merchantNameCtrl.text : 'GroceryGo Official Store',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _testUpiIntent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.launch_rounded, size: 14),
                        label: const Text('Test UPI Intent', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: Admin UPI Details
          const Text(
            'Store UPI & Direct Payment Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'These credentials power real-time GPay, PhonePe, Paytm & QR Code checkout for all customers.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _upiIdCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Admin UPI ID (VPA)',
                    hintText: 'e.g. merchant@upi',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _merchantNameCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Merchant Payee Name',
                    hintText: 'e.g. GroceryGo Official Store',
                    prefixIcon: const Icon(Icons.store_rounded, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Bank Account Settlement Details
          const Text(
            'Bank Account Settlement Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text('Primary bank account for business settlements and manual transfers.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _bankNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Bank Name',
                    prefixIcon: const Icon(Icons.account_balance_rounded, color: Color(0xFF10B981)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accNoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF10B981)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ifscCtrl,
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    prefixIcon: const Icon(Icons.code_rounded, color: Color(0xFF10B981)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Enabled Payment Gateways
          const Text(
            'Active Payment Gateways',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('UPI & Instant QR Payments', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('GPay, PhonePe, Paytm & Dynamic QR Codes', style: TextStyle(fontSize: 11.5)),
                  value: _enableUpi,
                  activeTrackColor: const Color(0xFF6366F1),
                  onChanged: (val) => setState(() => _enableUpi = val),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  title: const Text('GroceryGo In-App Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Pay instantly with user stored balance', style: TextStyle(fontSize: 11.5)),
                  value: _enableWallet,
                  activeTrackColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => _enableWallet = val),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Pay cash or UPI upon doorstep delivery', style: TextStyle(fontSize: 11.5)),
                  value: _enableCod,
                  activeTrackColor: const Color(0xFFF59E0B),
                  onChanged: (val) => setState(() => _enableCod = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save Settings Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSavingSettings ? null : _savePaymentSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isSavingSettings
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Gateway Configuration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
