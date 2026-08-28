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
  final _quickFeeCtrl = TextEditingController();
  final _scheduledFeeCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  final _etaCtrl = TextEditingController();
  final _maxRadiusCtrl = TextEditingController();
  final _surgeFeeCtrl = TextEditingController();
  final _surgeReasonCtrl = TextEditingController();

  bool _isFreeDeliveryEnabled = true;
  bool _isSurgeActive = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _quickFeeCtrl.dispose();
    _scheduledFeeCtrl.dispose();
    _thresholdCtrl.dispose();
    _etaCtrl.dispose();
    _maxRadiusCtrl.dispose();
    _surgeFeeCtrl.dispose();
    _surgeReasonCtrl.dispose();
    super.dispose();
  }

  void _initFields(StoreSettingsModel settings) {
    if (_quickFeeCtrl.text.isEmpty && _scheduledFeeCtrl.text.isEmpty && _thresholdCtrl.text.isEmpty && _etaCtrl.text.isEmpty) {
      _quickFeeCtrl.text = settings.quickDeliveryFee.toStringAsFixed(0);
      _scheduledFeeCtrl.text = settings.scheduledDeliveryFee.toStringAsFixed(0);
      _thresholdCtrl.text = settings.freeDeliveryThreshold.toStringAsFixed(0);
      _etaCtrl.text = settings.estimatedDeliveryTime;
      _maxRadiusCtrl.text = settings.maxDeliveryRadiusKm.toStringAsFixed(0);
      _surgeFeeCtrl.text = settings.surgeFee > 0 ? settings.surgeFee.toStringAsFixed(0) : '25';
      _surgeReasonCtrl.text = settings.surgeReason;
      _isFreeDeliveryEnabled = settings.isFreeDeliveryEnabled;
      _isSurgeActive = settings.isSurgeActive;
    }
  }

  Future<void> _saveGlobalSettings() async {
    final quickFee = double.tryParse(_quickFeeCtrl.text.trim());
    final scheduledFee = double.tryParse(_scheduledFeeCtrl.text.trim());
    final threshold = double.tryParse(_thresholdCtrl.text.trim());
    final maxRadius = double.tryParse(_maxRadiusCtrl.text.trim()) ?? 15.0;
    final surgeFee = double.tryParse(_surgeFeeCtrl.text.trim()) ?? 0.0;
    final surgeReason = _surgeReasonCtrl.text.trim().isNotEmpty ? _surgeReasonCtrl.text.trim() : 'Heavy rain / peak demand';
    final eta = _etaCtrl.text.trim().isNotEmpty ? _etaCtrl.text.trim() : '20 to 30 minutes';

    if (quickFee == null || quickFee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quick delivery fee'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (scheduledFee == null || scheduledFee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid scheduled delivery fee (e.g. 0 for FREE)'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = await SettingsRepository().getGlobalSettings().first;
      final settings = existing.copyWith(
        id: 'global',
        baseDeliveryFee: quickFee,
        quickDeliveryFee: quickFee,
        scheduledDeliveryFee: scheduledFee,
        freeDeliveryThreshold: threshold ?? 500.0,
        isFreeDeliveryEnabled: _isFreeDeliveryEnabled,
        estimatedDeliveryTime: eta,
        maxDeliveryRadiusKm: maxRadius,
        surgeFee: surgeFee,
        isSurgeActive: _isSurgeActive,
        surgeReason: surgeReason,
      );

      final ok = await SettingsRepository().updateSettings(settings);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Delivery & surge pricing settings updated!'), backgroundColor: Color(0xFF059669)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Delivery & Surge Pricing',
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
                // 1. Dynamic Surge Pricing Card (Weather / Peak Demand)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _isSurgeActive ? const Color(0xFFFFFBEB) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSurgeActive ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                      width: _isSurgeActive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isSurgeActive ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.bolt_rounded, color: _isSurgeActive ? const Color(0xFFD97706) : const Color(0xFF64748B), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Surge Pricing Engine',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  _isSurgeActive ? '⚡ Surge is currently ACTIVE on customer checkouts' : 'Inactive (Normal platform rates apply)',
                                  style: TextStyle(fontSize: 12, color: _isSurgeActive ? const Color(0xFFD97706) : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isSurgeActive,
                            activeThumbColor: const Color(0xFFD97706),
                            onChanged: (val) => setState(() => _isSurgeActive = val),
                          ),
                        ],
                      ),
                      if (_isSurgeActive) ...[
                        const Divider(height: 24, color: Color(0xFFFDE68A)),
                        AppTextField(
                          label: 'Additional Surge Fee (₹)',
                          hint: 'e.g. 25',
                          controller: _surgeFeeCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Customer-facing Surge Notice Reason',
                          hint: 'e.g. Heavy rainfall in your area / High demand surge',
                          controller: _surgeReasonCtrl,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Base & Scheduled Delivery Rates
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669), size: 20),
                          SizedBox(width: 8),
                          Text('Standard Delivery Rates', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Instant / Quick Delivery Fee (₹)',
                        hint: 'e.g. 40',
                        controller: _quickFeeCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Scheduled Slot Delivery Fee (₹)',
                        hint: '0 for FREE scheduled slot',
                        controller: _scheduledFeeCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Estimated Delivery Time Label',
                        hint: 'e.g. 20 to 30 minutes',
                        controller: _etaCtrl,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Maximum Delivery Service Radius (KM)',
                        hint: 'e.g. 15',
                        controller: _maxRadiusCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Free Delivery Threshold
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Free Delivery Threshold', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Automatically waive delivery fee when order subtotal exceeds limit', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: _isFreeDeliveryEnabled,
                        activeThumbColor: const Color(0xFF059669),
                        onChanged: (val) => setState(() => _isFreeDeliveryEnabled = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isFreeDeliveryEnabled) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Minimum Order Value for Free Delivery (₹)',
                          hint: 'e.g. 500',
                          controller: _thresholdCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                AppButton(
                  label: 'Save Delivery Settings',
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
