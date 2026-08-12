import 'package:admin_app/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
// import '../../widgets/admin_drawer.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final _settingsRepo = SettingsRepository();

  bool _isInitialized = false;
  bool _isSaving = false;

  bool _isCodEnabled = true;
  bool _isOnlinePaymentEnabled = true;
  bool _isWalletEnabled = true;
  bool _isMaintenanceMode = false;
  bool _requireDriverDocVerification = true;

  late TextEditingController _appNameCtrl;
  late TextEditingController _supportEmailCtrl;
  late TextEditingController _supportPhoneCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _appVersionCtrl;
  late TextEditingController _termsCtrl;
  late TextEditingController _privacyCtrl;
  late TextEditingController _adminUpiCtrl;
  late TextEditingController _adminPayeeCtrl;
  late TextEditingController _adminAccountCtrl;
  late TextEditingController _adminIfscCtrl;
  late TextEditingController _adminBankCtrl;

  @override
  void initState() {
    super.initState();
    _appNameCtrl = TextEditingController();
    _supportEmailCtrl = TextEditingController();
    _supportPhoneCtrl = TextEditingController();
    _minOrderCtrl = TextEditingController();
    _appVersionCtrl = TextEditingController();
    _termsCtrl = TextEditingController();
    _privacyCtrl = TextEditingController();
    _adminUpiCtrl = TextEditingController();
    _adminPayeeCtrl = TextEditingController();
    _adminAccountCtrl = TextEditingController();
    _adminIfscCtrl = TextEditingController();
    _adminBankCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _minOrderCtrl.dispose();
    _appVersionCtrl.dispose();
    _termsCtrl.dispose();
    _privacyCtrl.dispose();
    _adminUpiCtrl.dispose();
    _adminPayeeCtrl.dispose();
    _adminAccountCtrl.dispose();
    _adminIfscCtrl.dispose();
    _adminBankCtrl.dispose();
    super.dispose();
  }

  void _populateFields(StoreSettingsModel settings) {
    if (_isInitialized) return;
    _appNameCtrl.text = settings.appName;
    _supportEmailCtrl.text = settings.supportEmail;
    _supportPhoneCtrl.text = settings.supportPhone;
    _minOrderCtrl.text = settings.minOrderValue.toStringAsFixed(0);
    _appVersionCtrl.text = settings.appVersion;
    _termsCtrl.text = settings.termsOfService;
    _privacyCtrl.text = settings.privacyPolicy;
    _adminUpiCtrl.text = settings.adminUpiId;
    _adminPayeeCtrl.text = settings.adminPayeeName;
    _adminAccountCtrl.text = settings.adminAccountNumber;
    _adminIfscCtrl.text = settings.adminIfscCode;
    _adminBankCtrl.text = settings.adminBankName;
    _isCodEnabled = settings.isCodEnabled;
    _isOnlinePaymentEnabled = settings.isOnlinePaymentEnabled;
    _isWalletEnabled = settings.isWalletEnabled;
    _isMaintenanceMode = settings.isMaintenanceMode;
    _requireDriverDocVerification = settings.requireDriverDocVerification;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Platform Settings',
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
        stream: _settingsRepo.getGlobalSettings(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !_isInitialized) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final settings = snap.data ?? const StoreSettingsModel(id: 'global');
          _populateFields(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General Settings
                _sectionHeader('General Platform Details', Icons.store_rounded),
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
                        decoration: _inputDeco('Support Email Address', Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _supportPhoneCtrl,
                        decoration: _inputDeco('Support Helpline Phone', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minOrderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('Minimum Order Value (₹)', Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _appVersionCtrl,
                        decoration: _inputDeco('App Release Version', Icons.verified_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal & Policy Content
                _sectionHeader('Customer Policies & Legal Content', Icons.gavel_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Terms of Service:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _termsCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Privacy Policy:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _privacyCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
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
                        title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Allow customers to pay cash on delivery', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _isOnlinePaymentEnabled,
                        onChanged: (val) => setState(() => _isOnlinePaymentEnabled = val),
                        title: const Text('Online Payment (UPI / Cards)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Accept UPI, Debit/Credit cards & Netbanking', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _isWalletEnabled,
                        onChanged: (val) => setState(() => _isWalletEnabled = val),
                        title: const Text('In-App Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Allow payment using wallet balance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Admin Bank & UPI Accounts
                _sectionHeader('Admin Official Payment & UPI Account', Icons.account_balance_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _adminUpiCtrl,
                        decoration: _inputDeco('Admin Official UPI ID (VPA)', Icons.qr_code_2_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminPayeeCtrl,
                        decoration: _inputDeco('Payee / Account Name', Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminBankCtrl,
                        decoration: _inputDeco('Bank Name', Icons.account_balance_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminAccountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('Account Number', Icons.numbers_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminIfscCtrl,
                        decoration: _inputDeco('IFSC Code', Icons.code_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // System Control
                _sectionHeader('System Control', Icons.build_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isMaintenanceMode,
                        onChanged: (val) => setState(() => _isMaintenanceMode = val),
                        title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Temporarily block user orders for system updates', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFFEF4444),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _requireDriverDocVerification,
                        onChanged: (val) => setState(() => _requireDriverDocVerification = val),
                        title: const Text('Require Driver Document Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Require drivers to have approved DL & RC before going online', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveSettings(settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Save All Platform Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

  Future<void> _saveSettings(StoreSettingsModel current) async {
    setState(() => _isSaving = true);

    final updated = current.copyWith(
      appName: _appNameCtrl.text.trim(),
      supportEmail: _supportEmailCtrl.text.trim(),
      supportPhone: _supportPhoneCtrl.text.trim(),
      minOrderValue: double.tryParse(_minOrderCtrl.text.trim()) ?? current.minOrderValue,
      appVersion: _appVersionCtrl.text.trim(),
      termsOfService: _termsCtrl.text.trim(),
      privacyPolicy: _privacyCtrl.text.trim(),
      isCodEnabled: _isCodEnabled,
      isOnlinePaymentEnabled: _isOnlinePaymentEnabled,
      isWalletEnabled: _isWalletEnabled,
      isMaintenanceMode: _isMaintenanceMode,
      requireDriverDocVerification: _requireDriverDocVerification,
      adminUpiId: _adminUpiCtrl.text.trim(),
      adminPayeeName: _adminPayeeCtrl.text.trim(),
      adminAccountNumber: _adminAccountCtrl.text.trim(),
      adminIfscCode: _adminIfscCtrl.text.trim(),
      adminBankName: _adminBankCtrl.text.trim(),
    );

    final success = await _settingsRepo.updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Platform settings updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update platform settings.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _sectionHeader(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
