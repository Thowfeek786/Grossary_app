import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';

class FeatureFlagsScreen extends StatefulWidget {
  const FeatureFlagsScreen({super.key});

  @override
  State<FeatureFlagsScreen> createState() => _FeatureFlagsScreenState();
}

class _FeatureFlagsScreenState extends State<FeatureFlagsScreen> {
  final _settingsRepo = SettingsRepository();

  Future<void> _updateFlag(StoreSettingsModel current, String key, bool value) async {
    HapticFeedback.selectionClick();
    try {
      final updatedMap = current.toFirestore();
      updatedMap[key] = value;
      await _settingsRepo.updateGlobalSettings(updatedMap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Updated $key to ${value ? 'ACTIVE' : 'DISABLED'}'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Feature Flags & Controls',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<StoreSettingsModel>(
        stream: _settingsRepo.getGlobalSettings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          final settings = snapshot.data ?? const StoreSettingsModel(id: 'global');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Callout Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.toggle_on_rounded, color: Color(0xFF818CF8), size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Module Kill-Switches',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Toggle platform features ON or OFF in real-time across all customer, dealer, and driver apps.',
                              style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 1. Growth & Gamification Group
                _buildGroupHeader('Gamification & Discovery', Icons.card_giftcard_rounded, const Color(0xFF8B5CF6)),
                const SizedBox(height: 10),
                _FeatureToggleTile(
                  title: 'Mystery Scratch Cards & Rewards',
                  subtitle: 'Display post-checkout mystery scratch cards and cashback rewards to customers.',
                  icon: Icons.celebration_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  value: settings.isScratchCardEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isScratchCardEnabled', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'AI Voice Search Microphone',
                  subtitle: 'Enable speech recognition and multi-language voice search in User App.',
                  icon: Icons.mic_rounded,
                  iconColor: const Color(0xFF059669),
                  value: settings.isVoiceSearchEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isVoiceSearchEnabled', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'Flash Sale Countdown & Deals',
                  subtitle: 'Show the urgent flash sale banner and live discount timers on the customer homepage.',
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFEF4444),
                  value: settings.isFlashSaleEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isFlashSaleEnabled', val),
                ),

                const SizedBox(height: 24),

                // 2. Hydration & Specialized Modules
                _buildGroupHeader('Specialized Services & Commerce', Icons.water_drop_rounded, const Color(0xFF0284C7)),
                const SizedBox(height: 10),
                _FeatureToggleTile(
                  title: '20L Water Can Module & Jar Exchange',
                  subtitle: 'Allow ordering fresh 20L water cans with empty jar return deposits and ledger tracking.',
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF0284C7),
                  value: settings.isWaterCanEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isWaterCanEnabled', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'Hydration Recurring Subscriptions',
                  subtitle: 'Let customers setup automated daily / alternate-day recurring water deliveries.',
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFF059669),
                  value: settings.isWaterSubscriptionEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isWaterSubscriptionEnabled', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'Dark Store Walk-in POS Terminal',
                  subtitle: 'Enable barcode scanning, walk-in register billing, and cash sales in Dealer App.',
                  icon: Icons.point_of_sale_rounded,
                  iconColor: const Color(0xFF10B981),
                  value: settings.isPosEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isPosEnabled', val),
                ),

                const SizedBox(height: 24),

                // 3. Checkout & Payment Gateways
                _buildGroupHeader('Checkout & Payment Methods', Icons.payments_rounded, const Color(0xFF10B981)),
                const SizedBox(height: 10),
                _FeatureToggleTile(
                  title: 'Cash on Delivery (COD)',
                  subtitle: 'Accept pay on delivery cash collections across all customer orders.',
                  icon: Icons.money_rounded,
                  iconColor: const Color(0xFF059669),
                  value: settings.isCodEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isCodEnabled', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'Online UPI & Card Gateway',
                  subtitle: 'Accept instant digital payments and UPI QR codes during checkout.',
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  value: settings.isOnlinePaymentEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isOnlinePaymentEnabled', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'Customer Cashback Wallet',
                  subtitle: 'Enable in-app wallet balance usage and instant refund credits.',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF84CC16),
                  value: settings.isWalletEnabled,
                  onChanged: (val) => _updateFlag(settings, 'isWalletEnabled', val),
                ),

                const SizedBox(height: 24),

                // 4. Logistics & Security Guardrails
                _buildGroupHeader('Platform Guardrails & Compliance', Icons.security_rounded, const Color(0xFFEAB308)),
                const SizedBox(height: 10),
                _FeatureToggleTile(
                  title: 'Delivery Partner Document Verification',
                  subtitle: 'Mandate driving license and vehicle registration approvals before partners go on duty.',
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF6366F1),
                  value: settings.requireDriverDocVerification,
                  onChanged: (val) => _updateFlag(settings, 'requireDriverDocVerification', val),
                ),
                const SizedBox(height: 8),
                _FeatureToggleTile(
                  title: 'Platform Maintenance Mode',
                  subtitle: 'Temporarily pause new customer checkouts and show maintenance message.',
                  icon: Icons.construction_rounded,
                  iconColor: const Color(0xFFEF4444),
                  value: settings.isMaintenanceMode,
                  onChanged: (val) => _updateFlag(settings, 'isMaintenanceMode', val),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: -0.2),
        ),
      ],
    );
  }
}

class _FeatureToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FeatureToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: value ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: value ? 0.12 : 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: value ? iconColor : const Color(0xFF94A3B8), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: value ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: value ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFF94A3B8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: value ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}
