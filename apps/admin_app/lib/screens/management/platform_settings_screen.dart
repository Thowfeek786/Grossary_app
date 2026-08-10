import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final _settingsRepo = SettingsRepository();

  bool _isCodEnabled = true;
  bool _isOnlinePaymentEnabled = true;
  bool _isWalletEnabled = true;
  bool _isMaintenanceMode = false;

  final _appNameCtrl = TextEditingController(text: 'GroceryGo');
  final _supportEmailCtrl = TextEditingController(text: 'support@grocerygo.com');
  final _supportPhoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _minOrderCtrl = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Platform Settings'),
      body: StreamBuilder<StoreSettingsModel>(
        stream: _settingsRepo.getGlobalSettings(),
        builder: (context, snap) {
          final settings = snap.data ?? const StoreSettingsModel(id: 'global');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General Settings
                _sectionHeader('General Settings', Icons.store_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _appNameCtrl,
                        decoration: _inputDeco('Platform Name', Icons.apps_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _supportEmailCtrl,
                        decoration: _inputDeco('Support Email', Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _supportPhoneCtrl,
                        decoration: _inputDeco('Support Phone', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minOrderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('Minimum Order Value (₹)', Icons.shopping_bag_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Gateways Toggle
                _sectionHeader('Payment Gateways', Icons.payments_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isCodEnabled,
                        onChanged: (val) => setState(() => _isCodEnabled = val),
                        title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Allow customers to pay cash on delivery', style: TextStyle(fontSize: 11)),
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _isOnlinePaymentEnabled,
                        onChanged: (val) => setState(() => _isOnlinePaymentEnabled = val),
                        title: const Text('Online Payment (Razorpay / Stripe)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Accept UPI, Debit/Credit cards & Netbanking', style: TextStyle(fontSize: 11)),
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _isWalletEnabled,
                        onChanged: (val) => setState(() => _isWalletEnabled = val),
                        title: const Text('In-App Wallet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Allow payment using wallet balance', style: TextStyle(fontSize: 11)),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // System Control
                _sectionHeader('System Control', Icons.build_rounded),
                const SizedBox(height: 12),
                _card(
                  child: SwitchListTile(
                    value: _isMaintenanceMode,
                    onChanged: (val) => setState(() => _isMaintenanceMode = val),
                    title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Temporarily block user orders for system updates', style: TextStyle(fontSize: 11)),
                    activeColor: AppColors.error,
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Platform settings saved successfully!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

  Widget _sectionHeader(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: child,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
