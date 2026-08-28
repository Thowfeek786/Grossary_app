import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class WaterCanManagementScreen extends StatefulWidget {
  const WaterCanManagementScreen({super.key});

  @override
  State<WaterCanManagementScreen> createState() => _WaterCanManagementScreenState();
}

class _WaterCanManagementScreenState extends State<WaterCanManagementScreen> {
  final WaterCanRepository _waterCanRepo = WaterCanRepository();

  final _refillPriceCtrl = TextEditingController();
  final _refillOriginalPriceCtrl = TextEditingController();
  final _exchangeDiscountCtrl = TextEditingController();
  final _newCanPriceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _bottlePackPriceCtrl = TextEditingController();

  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _refillPriceCtrl.dispose();
    _refillOriginalPriceCtrl.dispose();
    _exchangeDiscountCtrl.dispose();
    _newCanPriceCtrl.dispose();
    _depositCtrl.dispose();
    _bottlePackPriceCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> config) {
    if (!_isLoaded) {
      _refillPriceCtrl.text = (config['refillPrice'] as double).toStringAsFixed(0);
      _refillOriginalPriceCtrl.text = (config['refillOriginalPrice'] as double).toStringAsFixed(0);
      _exchangeDiscountCtrl.text = (config['exchangeDiscount'] as double).toStringAsFixed(0);
      _newCanPriceCtrl.text = (config['newCanPrice'] as double).toStringAsFixed(0);
      _depositCtrl.text = (config['refundableDeposit'] as double).toStringAsFixed(0);
      _bottlePackPriceCtrl.text = (config['bottlePackPrice'] as double).toStringAsFixed(0);
      _isLoaded = true;
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await _waterCanRepo.updatePlatformCanConfig(
        refillPrice: double.tryParse(_refillPriceCtrl.text) ?? 50.0,
        refillOriginalPrice: double.tryParse(_refillOriginalPriceCtrl.text) ?? 80.0,
        exchangeDiscount: double.tryParse(_exchangeDiscountCtrl.text) ?? 30.0,
        newCanPrice: double.tryParse(_newCanPriceCtrl.text) ?? 150.0,
        refundableDeposit: double.tryParse(_depositCtrl.text) ?? 100.0,
        bottlePackPrice: double.tryParse(_bottlePackPriceCtrl.text) ?? 90.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Water Can pricing & deposit settings updated!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Water Can Management',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669)),
            tooltip: 'Can Ledger & Refunds',
            onPressed: () => context.push('/management/water-cans/ledger'),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _waterCanRepo.getPlatformCanConfig(),
        builder: (context, configSnapshot) {
          if (configSnapshot.hasData) {
            _populateControllers(configSnapshot.data!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Summary Live Stream
                StreamBuilder<PlatformCanSummaryModel>(
                  stream: _waterCanRepo.getPlatformCanSummary(),
                  builder: (context, summarySnapshot) {
                    final summary = summarySnapshot.data ?? PlatformCanSummaryModel.empty();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Platform Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Cans in Circulation',
                                value: '${summary.totalCansInCirculation}',
                                icon: Icons.water_drop_rounded,
                                color: const Color(0xFF059669),
                                bgColor: const Color(0xFFF0FDF4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Deposit Liability',
                                value: '₹${summary.totalDepositLiability.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: const Color(0xFF2563EB),
                                bgColor: const Color(0xFFEFF6FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Dispatched Today',
                                value: '${summary.totalDispatchedToday}',
                                icon: Icons.local_shipping_rounded,
                                color: const Color(0xFFD97706),
                                bgColor: const Color(0xFFFFFBEB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Collected Today',
                                value: '${summary.totalCollectedToday}',
                                icon: Icons.sync_rounded,
                                color: const Color(0xFF7C3AED),
                                bgColor: const Color(0xFFF5F3FF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Pricing & Deposit Rules Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pricing & Deposit Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Global Rules',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Refill Can Price
                      _ConfigInputField(
                        controller: _refillPriceCtrl,
                        label: '20L Refill Can Price (₹)',
                        helper: 'Discounted price when customer exchanges empty can',
                      ),
                      const SizedBox(height: 14),

                      // Refill Original Price
                      _ConfigInputField(
                        controller: _refillOriginalPriceCtrl,
                        label: '20L Refill Original Price (₹)',
                        helper: 'MSRP before exchange discount (e.g. ₹80)',
                      ),
                      const SizedBox(height: 14),

                      // Exchange Discount
                      _ConfigInputField(
                        controller: _exchangeDiscountCtrl,
                        label: 'Empty Can Exchange Discount (₹)',
                        helper: 'Instant discount value applied (e.g. ₹30)',
                      ),
                      const SizedBox(height: 14),

                      // New Can Price
                      _ConfigInputField(
                        controller: _newCanPriceCtrl,
                        label: '20L New Can Price (₹)',
                        helper: 'Full price for customer without empty can (e.g. ₹150)',
                      ),
                      const SizedBox(height: 14),

                      // Refundable Can Deposit
                      _ConfigInputField(
                        controller: _depositCtrl,
                        label: 'Refundable Can Deposit Amount (₹)',
                        helper: 'Deposit returned when customer surrenders empty container (e.g. ₹100)',
                      ),
                      const SizedBox(height: 14),

                      // 1L Pack Price
                      _ConfigInputField(
                        controller: _bottlePackPriceCtrl,
                        label: '1L Water Bottle (Pack of 6) Price (₹)',
                        helper: 'Selling price for 1L bottled water pack',
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Save Configuration',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dealer Breakdown Section
                const Text(
                  'Dealer Water Circulation Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<UserModel>>(
                  stream: _waterCanRepo.getAvailableWaterDealers(),
                  builder: (context, dealersSnapshot) {
                    final dealers = dealersSnapshot.data ?? [];
                    if (dealers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No active dealers found.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dealers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final dealer = dealers[idx];
                        return StreamBuilder<Map<String, dynamic>>(
                          stream: _waterCanRepo.getDealerCanSummary(dealer.id),
                          builder: (context, summarySnap) {
                            final stats = summarySnap.data ?? {};
                            final balance = stats['canBalance'] ?? 0;
                            final activeCust = stats['activeCustomersCount'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.all(14),
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
                                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dealer.shopName ?? dealer.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$activeCust active customer${activeCust == 1 ? "" : "s"} holding cans',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: balance > 0
                                          ? const Color(0xFF059669).withValues(alpha: 0.1)
                                          : const Color(0xFF64748B).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$balance Cans Out',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: balance > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Audit Ledger Shortcut
                GestureDetector(
                  onTap: () => context.push('/management/water-cans/ledger'),
                  child: Container(
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0FDF4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Platform Can Ledger & Refunds',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Audit customer balances & issue deposit refunds',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String helper;

  const _ConfigInputField({
    required this.controller,
    required this.label,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
