import 'package:admin_app/widgets/admin_drawer.dart';
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
  late TextEditingController _vendorHelplineCtrl;
  late TextEditingController _whatsappSupportCtrl;
  late TextEditingController _vendorEmailCtrl;
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
    _vendorHelplineCtrl = TextEditingController();
    _whatsappSupportCtrl = TextEditingController();
    _vendorEmailCtrl = TextEditingController();
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
    _vendorHelplineCtrl.dispose();
    _whatsappSupportCtrl.dispose();
    _vendorEmailCtrl.dispose();
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
    _vendorHelplineCtrl.text = settings.vendorHelplinePhone;
    _whatsappSupportCtrl.text = settings.whatsappSupportPhone;
    _vendorEmailCtrl.text = settings.vendorSupportEmail;
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: StreamBuilder<StoreSettingsModel>(
        stream: _settingsRepo.streamSettings('global'),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snap.data ?? const StoreSettingsModel(id: 'global');
          _populateFields(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General Platform Settings
                _sectionHeader('General Platform Details', Icons.tune_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _appNameCtrl,
                        decoration: _inputDeco('Application Name', Icons.apps_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _supportEmailCtrl,
                        decoration: _inputDeco('Customer Support Email', Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _supportPhoneCtrl,
                        decoration: _inputDeco('Customer Support Phone', Icons.phone_outlined),
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

                // Vendor Partner Helpline & Support Contacts
                _sectionHeader('Vendor & Partner Helpline Contacts', Icons.support_agent_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _vendorHelplineCtrl,
                        decoration: _inputDeco('Vendor Toll-Free / Phone Helpline', Icons.phone_in_talk_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _whatsappSupportCtrl,
                        decoration: _inputDeco('WhatsApp Dispatch Desk Number (with country code)', Icons.chat_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vendorEmailCtrl,
                        decoration: _inputDeco('Partner Relations Support Email', Icons.mark_email_read_outlined),
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
                        title: const Text('Online UPI / QR Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Accept UPI, Google Pay, PhonePe, Paytm', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _isWalletEnabled,
                        onChanged: (val) => setState(() => _isWalletEnabled = val),
                        title: const Text('GroceryGo Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Allow wallet balance top-up & payments', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Official Admin Bank & UPI Details
                _sectionHeader('Official Admin Bank & UPI Details', Icons.account_balance_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _adminUpiCtrl,
                        decoration: _inputDeco('Admin Official UPI VPA', Icons.qr_code_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminPayeeCtrl,
                        decoration: _inputDeco('Payee Merchant Name', Icons.badge_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminBankCtrl,
                        decoration: _inputDeco('Admin Bank Name', Icons.account_balance_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminAccountCtrl,
                        decoration: _inputDeco('Admin Bank Account Number', Icons.numbers_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminIfscCtrl,
                        decoration: _inputDeco('Bank IFSC Code', Icons.password_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // System Security & Compliance Controls
                _sectionHeader('System Security & Operations', Icons.security_rounded),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _requireDriverDocVerification,
                        onChanged: (val) => setState(() => _requireDriverDocVerification = val),
                        title: const Text('Mandatory Driver Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        subtitle: const Text('Require Driving License & RC approval before driver dispatch', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _isMaintenanceMode,
                        onChanged: (val) => setState(() => _isMaintenanceMode = val),
                        title: const Text('System Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFEF4444))),
                        subtitle: const Text('Temporarily pause customer orders for emergency maintenance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        activeThumbColor: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Changes CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveSettings(settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Save Platform Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
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
      vendorHelplinePhone: _vendorHelplineCtrl.text.trim(),
      whatsappSupportPhone: _whatsappSupportCtrl.text.trim(),
      vendorSupportEmail: _vendorEmailCtrl.text.trim(),
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

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
