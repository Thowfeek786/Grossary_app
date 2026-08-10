import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
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
        const SnackBar(content: Text('Please enter a valid base delivery fee'), backgroundColor: AppColors.error),
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
          const SnackBar(content: Text('🎉 Store delivery fee settings updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: AppErrorWidget(message: 'Dealer authentication required.'));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Delivery & Shipping Settings'),
      body: StreamBuilder<StoreSettingsModel>(
        stream: SettingsRepository().getDealerSettings(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          final settings = snapshot.data ?? StoreSettingsModel(id: user.id);
          _initFields(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Custom Delivery Rates',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Set custom delivery charges and minimum free delivery order thresholds for your store.',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Base Delivery Fee Field
                AppTextField(
                  label: 'Base Delivery Fee (₹)',
                  hint: 'e.g. 40',
                  controller: _feeCtrl,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 20),

                // Free Delivery Switch
                SwitchListTile(
                  title: const Text('Enable Free Delivery Threshold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Offer free delivery to customers when order exceeds minimum amount'),
                  value: _isFreeDeliveryEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isFreeDeliveryEnabled = val),
                  contentPadding: EdgeInsets.zero,
                ),

                if (_isFreeDeliveryEnabled) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Minimum Free Delivery Order Amount (₹)',
                    hint: 'e.g. 500',
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 36),

                AppButton(
                  label: 'Save Settings',
                  isLoading: _isSaving,
                  icon: Icons.save_rounded,
                  onTap: () => _save(user.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
