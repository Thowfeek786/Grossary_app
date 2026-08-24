import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountCtrl = TextEditingController();
  bool _isAddingFunds = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddFundsDialog(String userId) async {
    _amountCtrl.clear();
    double selectedAmount = 500;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF059669)),
                  SizedBox(width: 10),
                  Text('Add Wallet Money', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF111827))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select preset or enter custom amount:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [100.0, 500.0, 1000.0].map((amt) {
                      final isSel = selectedAmount == amt && _amountCtrl.text.isEmpty;
                      return ChoiceChip(
                        label: Text('₹${amt.toInt()}'),
                        selected: isSel,
                        onSelected: (b) {
                          if (b) {
                            setStateSB(() {
                              selectedAmount = amt;
                              _amountCtrl.clear();
                            });
                          }
                        },
                        selectedColor: const Color(0xFF059669),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setStateSB(() {}),
                    decoration: InputDecoration(
                      labelText: 'Custom Amount (₹)',
                      hintText: 'Enter amount e.g. 250',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF059669)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                ),
                ElevatedButton.icon(
                  onPressed: _isAddingFunds
                      ? null
                      : () async {
                          final inputAmt = double.tryParse(_amountCtrl.text.trim());
                          final finalAmt = inputAmt ?? selectedAmount;
                          if (finalAmt <= 0) return;

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          setState(() => _isAddingFunds = true);
                          try {
                            // Launch UPI app for wallet top-up to Admin UPI ID
                            try {
                              final settings = await SettingsRepository().getGlobalSettings().first;
                              final upiVpa = settings.adminUpiId.isNotEmpty ? settings.adminUpiId : 'groceryadmin@upi';
                              final payeeName = Uri.encodeComponent(settings.adminPayeeName.isNotEmpty ? settings.adminPayeeName : 'GroceryGo Admin');
                              final amt = finalAmt.toStringAsFixed(2);
                              final note = Uri.encodeComponent('GroceryGo Wallet TopUp');
                              final upiUrl = 'upi://pay?pa=$upiVpa&pn=$payeeName&am=$amt&cu=INR&tn=$note';
                              final uri = Uri.parse(upiUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } catch (_) {}

                            await WalletRepository().addFunds(
                              userId: userId,
                              amount: finalAmt,
                              description: 'Wallet Top Up via UPI',
                            );
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('🎉 Successfully added ₹${finalAmt.toStringAsFixed(0)} to your wallet!'),
                                  backgroundColor: const Color(0xFF059669),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isAddingFunds = false);
                          }
                        },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Funds', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(body: AppErrorWidget(message: 'Please login to access your wallet.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Wallet', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<WalletModel>(
        stream: WalletRepository().getWallet(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          final wallet = snapshot.data ?? WalletModel(userId: user.id, balance: 0.0, transactions: [], updatedAt: DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Wallet Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                        blurRadius: 16,
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
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'GroceryGo Wallet',
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '⚡ Instant Checkout',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '₹${wallet.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isAddingFunds ? null : () => _showAddFundsDialog(user.id),
                        icon: _isAddingFunds
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)))
                            : const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('Top Up Wallet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0B3C26),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Transactions Header
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 14),

                // Transactions Stream
                StreamBuilder<List<WalletTransaction>>(
                  stream: WalletRepository().getTransactions(user.id),
                  builder: (context, txSnapshot) {
                    if (txSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                    }
                    final transactions = txSnapshot.data ?? [];
                    if (transactions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 12),
                            Text('No Wallet Transactions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))),
                            SizedBox(height: 4),
                            Text('Top up your wallet or place an order to get started!', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final tx = transactions[i];
                        final isCredit = tx.type == TransactionType.credit;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredit ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isCredit ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year} • ${tx.type.name.toUpperCase()}',
                                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isCredit ? const Color(0xFF059669) : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
