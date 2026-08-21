import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Partner Support & Safety'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency SOS Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('1-Tap Roadside Assistance & Emergency Hotline', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => launchUrl(Uri.parse('tel:112')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CALL SOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'How can we help you, Partner?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our dedicated rider support desk is active 24/7.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            _buildContactChannel(
              Icons.support_agent_rounded,
              'Live WhatsApp Dispatch Desk',
              'Quick resolution for delivery & address issues',
              () => launchUrl(Uri.parse('https://wa.me/919876543210?text=Partner%20Support%20Request'), mode: LaunchMode.externalApplication),
            ),
            _buildContactChannel(
              Icons.call_outlined,
              'Admin Helpline',
              'Direct line to store manager & dispatch center',
              () => launchUrl(Uri.parse('tel:+919876543210')),
            ),
            _buildContactChannel(
              Icons.mail_outline_rounded,
              'Payouts & Bank Support',
              'Assistance with wallet withdrawals & incentives',
              () => launchUrl(Uri.parse('mailto:support@grocerygo.com?subject=Partner%20Earnings%20Inquiry')),
            ),

            const SizedBox(height: 28),
            const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 12),
            _buildFaqItem('How do I complete delivery with customer OTP?', 'When you reach the doorstep, ask the customer for the 4-digit OTP shown in their app and enter it in the verification screen.'),
            _buildFaqItem('What if customer selected "Leave at door"?', 'Take a quick photo proof of delivery at the doorstep and ensure the package is safely positioned.'),
            _buildFaqItem('When are weekly payouts processed?', 'Payouts are automatically credited to your linked bank account every Monday.'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactChannel(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey400),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
