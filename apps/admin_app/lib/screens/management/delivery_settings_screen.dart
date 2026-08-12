import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../widgets/admin_drawer.dart';

class AdminDeliverySettingsScreen extends StatefulWidget {
  const AdminDeliverySettingsScreen({super.key});

  @override
  State<AdminDeliverySettingsScreen> createState() => _AdminDeliverySettingsScreenState();
}

class _AdminDeliverySettingsScreenState extends State<AdminDeliverySettingsScreen> {
  final _feeCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  final _etaCtrl = TextEditingController();
  bool _isFreeDeliveryEnabled = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _feeCtrl.dispose();
    _thresholdCtrl.dispose();
    _etaCtrl.dispose();
    super.dispose();
  }

  void _initFields(StoreSettingsModel settings) {
    if (_feeCtrl.text.isEmpty && _thresholdCtrl.text.isEmpty && _etaCtrl.text.isEmpty) {
      _feeCtrl.text = settings.baseDeliveryFee.toStringAsFixed(0);
      _thresholdCtrl.text = settings.freeDeliveryThreshold.toStringAsFixed(0);
      _etaCtrl.text = settings.estimatedDeliveryTime;
      _isFreeDeliveryEnabled = settings.isFreeDeliveryEnabled;
    }
  }

  Future<void> _saveGlobalSettings() async {
    final fee = double.tryParse(_feeCtrl.text.trim());
    final threshold = double.tryParse(_thresholdCtrl.text.trim());
    final eta = _etaCtrl.text.trim().isNotEmpty ? _etaCtrl.text.trim() : '20 to 30 minutes';

    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid base delivery fee'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = await SettingsRepository().getGlobalSettings().first;
      final settings = existing.copyWith(
        id: 'global',
        baseDeliveryFee: fee,
        freeDeliveryThreshold: threshold ?? 500.0,
        isFreeDeliveryEnabled: _isFreeDeliveryEnabled,
        estimatedDeliveryTime: eta,
      );

      final ok = await SettingsRepository().updateSettings(settings);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Global platform delivery settings updated successfully!'), backgroundColor: Color(0xFF0F172A)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Global Delivery Fee Settings',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, size: 20, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: StreamBuilder<StoreSettingsModel>(
        stream: SettingsRepository().getGlobalSettings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          final settings = snapshot.data ?? const StoreSettingsModel(id: 'global');
          _initFields(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6366F1), size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Global Platform Delivery Rates & Timing',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Set the default platform delivery fee, estimated timing label, and minimum order amount.',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Base Fee Field
                AppTextField(
                  label: 'Default Base Delivery Fee (₹)',
                  hint: 'e.g. 40',
                  controller: _feeCtrl,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 20),

                // Estimated Delivery Time Field
                AppTextField(
                  label: 'Estimated Delivery Time (Customizable)',
                  hint: 'e.g. 20 to 30 minutes',
                  controller: _etaCtrl,
                ),

                const SizedBox(height: 20),

                // Free Delivery Switch
                SwitchListTile(
                  title: const Text('Enable Free Delivery Threshold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Offer free delivery to platform customers when order exceeds minimum amount'),
                  value: _isFreeDeliveryEnabled,
                  activeThumbColor: const Color(0xFF6366F1),
                  onChanged: (val) => setState(() => _isFreeDeliveryEnabled = val),
                  contentPadding: EdgeInsets.zero,
                ),

                if (_isFreeDeliveryEnabled) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Platform Free Delivery Order Minimum (₹)',
                    hint: 'e.g. 500',
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 36),

                AppButton(
                  label: 'Save Global Settings',
                  isLoading: _isSaving,
                  icon: Icons.save_rounded,
                  onTap: _saveGlobalSettings,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
