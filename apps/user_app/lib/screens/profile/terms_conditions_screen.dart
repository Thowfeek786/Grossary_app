import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = SettingsRepository();

    return StreamBuilder<StoreSettingsModel>(
      stream: settingsRepo.getGlobalSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const StoreSettingsModel(id: 'global');

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: '${settings.appName} Terms & Conditions',
            backgroundColor: const Color(0xFF0B3C26),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emerald Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.gavel_rounded, color: Color(0xFF34D399), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${settings.appName} User Agreement',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const Text(
                                  'Effective Date: August 2026 • Version 1.0',
                                  style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Please read these terms and conditions carefully before creating an account or placing orders on our ultra-fast grocery delivery platform.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Main Terms Content Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin Custom Terms Box
                      if (settings.termsOfService.trim().isNotEmpty) ...[
                        _buildSectionHeader('1. Primary Platform Terms', Icons.article_rounded),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            settings.termsOfService,
                            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildSectionHeader('2. Account Security & User Obligations', Icons.shield_outlined),
                      const SizedBox(height: 8),
                      const _TermCard(
                        text:
                            'You must be at least 18 years old or under parental supervision to register on GroceryGo. Users are solely responsible for keeping account credentials secure and providing accurate mobile numbers and delivery address coordinates.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionHeader('3. Ordering, Pricing & Delivery Guarantees', Icons.bolt_rounded),
                      const SizedBox(height: 8),
                      _TermCard(
                        text:
                            'We strive for 10-15 minute delivery turnaround from local dark stores and partner dealers. Minimum order values apply (₹${settings.minOrderValue.toStringAsFixed(0)}). Prices displayed include applicable taxes and are locked upon checkout confirmation.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionHeader('4. Payment Methods & Wallet Credits', Icons.payments_outlined),
                      const SizedBox(height: 8),
                      const _TermCard(
                        text:
                            'GroceryGo supports UPI, Debit/Credit Cards, Netbanking, Cash on Delivery, and GroceryGo Wallet. Wallet cashbacks or promotional credits cannot be transferred to bank accounts.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionHeader('5. Instant Refunds & Damaged Goods Policy', Icons.assignment_return_outlined),
                      const SizedBox(height: 8),
                      const _TermCard(
                        text:
                            'If any delivered item is damaged, expired, or missing, submit a refund claim within 24 hours of delivery. Refunds are credited instantly to your GroceryGo Wallet or original payment method.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionHeader('6. Privacy & Data Rights', Icons.lock_outline_rounded),
                      const SizedBox(height: 8),
                      const _TermCard(
                        text:
                            'Your personal data and GPS location coordinates are protected under strict security encryption. Read our full Privacy Policy for details on how we collect and safeguard your information.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionHeader('7. Support & Inquiries', Icons.headset_mic_outlined),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'For any queries or legal notices regarding ${settings.appName}:',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 8),
                            SelectableText('📞 Customer Care: ${settings.supportPhone}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                            const SizedBox(height: 4),
                            SelectableText('✉️ Support Email: ${settings.supportEmail}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF059669)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _TermCard extends StatelessWidget {
  final String text;
  const _TermCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
      ),
    );
  }
}
