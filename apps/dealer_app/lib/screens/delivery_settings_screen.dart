import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class DealerDeliverySettingsScreen extends StatefulWidget {
  const DealerDeliverySettingsScreen({super.key});

  @override
  State<DealerDeliverySettingsScreen> createState() => _DealerDeliverySettingsScreenState();
}

class _DealerDeliverySettingsScreenState extends State<DealerDeliverySettingsScreen> {
  final _feeCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  bool _isFreeDeliveryEnabled = true;
  double _deliveryRadiusKm = 5.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _feeCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _initFields(StoreSettingsModel settings) {
    if (_feeCtrl.text.isEmpty && _thresholdCtrl.text.isEmpty) {
      _feeCtrl.text = settings.baseDeliveryFee.toStringAsFixed(0);
      _thresholdCtrl.text = settings.freeDeliveryThreshold.toStringAsFixed(0);
      _isFreeDeliveryEnabled = settings.isFreeDeliveryEnabled;
    }
  }

  Future<void> _save(String dealerId) async {
    final fee = double.tryParse(_feeCtrl.text.trim());
    final threshold = double.tryParse(_thresholdCtrl.text.trim());
    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid base delivery fee'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final settings = StoreSettingsModel(
        id: dealerId,
        baseDeliveryFee: fee,
        freeDeliveryThreshold: threshold ?? 500.0,
        isFreeDeliveryEnabled: _isFreeDeliveryEnabled,
      );

      final ok = await SettingsRepository().updateSettings(settings);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Store delivery fee settings updated successfully!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Dealer authentication required.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Delivery & Shipping Rates',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<StoreSettingsModel>(
        stream: SettingsRepository().getDealerSettings(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          final settings = snapshot.data ?? StoreSettingsModel(id: user.id);
          _initFields(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF059669), size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Custom Delivery Rates', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                            SizedBox(height: 2),
                            Text('Set custom radius, delivery fee & free order thresholds for your store.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Delivery Radius Range Slider Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Store Delivery Radius', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${_deliveryRadiusKm.toStringAsFixed(1)} km',
                              style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Maximum distance riders will fulfill orders from your store', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Slider(
                        value: _deliveryRadiusKm,
                        min: 1.0,
                        max: 20.0,
                        divisions: 38,
                        activeColor: const Color(0xFF059669),
                        onChanged: (val) => setState(() => _deliveryRadiusKm = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Delivery Fees Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Base Delivery Fees & Free Threshold', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Base Delivery Fee (₹)',
                        hint: 'e.g. 40',
                        controller: _feeCtrl,
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Enable Free Delivery Threshold', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                                SizedBox(height: 2),
                                Text('Offer free delivery when customer order exceeds minimum amount', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFreeDeliveryEnabled,
                            activeThumbColor: const Color(0xFF059669),
                            onChanged: (val) => setState(() => _isFreeDeliveryEnabled = val),
                          ),
                        ],
                      ),

                      if (_isFreeDeliveryEnabled) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Minimum Free Delivery Order Amount (₹)',
                          hint: 'e.g. 500',
                          controller: _thresholdCtrl,
                          prefixIcon: Icons.card_giftcard_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _save(user.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Delivery Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
