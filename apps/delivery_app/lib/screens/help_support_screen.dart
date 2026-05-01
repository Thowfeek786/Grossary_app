import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Partner Support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you, Partner?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our support team is available 24/7 to assist you.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildContactChannel(
              Icons.support_agent_rounded,
              'Live Chat Support',
              'Quick assistance with active deliveries',
              () {},
            ),
            _buildContactChannel(
              Icons.call_outlined,
              'Emergency Call',
              'For accidents or major delivery issues',
              () {},
            ),
            _buildContactChannel(
              Icons.mail_outline_rounded,
              'Email Support',
              'For earnings or account-related queries',
              () {},
            ),
            const SizedBox(height: 32),
            const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 13, letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildFaqItem('My order status is not updating, what should I do?', 'Try checking your internet connection first or restarting the app.'),
            _buildFaqItem('When will I receive my weekly earnings?', 'All payments are processed on Monday and reflect in your bank account.'),
            _buildFaqItem('How do I update my profile details?', 'You can change your name and photo from the Profile tab.'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactChannel(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey400),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }
}
