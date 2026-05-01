import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Help & Support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _SupportCard(
              title: 'Contact Us',
              icon: Icons.headset_mic_rounded,
              subtitle: 'Our team is here to help 24/7',
              actionLabel: 'Call Now',
              onAction: () {},
            ),
            const SizedBox(height: 16),
            _SupportCard(
              title: 'Email Support',
              icon: Icons.email_outlined,
              subtitle: 'Response within 24 hours',
              actionLabel: 'Send Email',
              onAction: () {},
            ),
            const SizedBox(height: 32),
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _FAQItem(
              question: 'How to track my order?',
              answer: 'Go to the Orders tab, select your ongoing order, and you can see real-time updates of your delivery status.',
            ),
            _FAQItem(
              question: 'What is the refund policy?',
              answer: 'We offer full refunds for missing or damaged items within 24 hours of delivery. Contact our support team for help.',
            ),
            _FAQItem(
              question: 'How to change delivery address?',
              answer: 'You can manage your saved addresses in Profile -> My Addresses section.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final String title, subtitle, actionLabel;
  final IconData icon;
  final VoidCallback onAction;

  const _SupportCard({required this.title, required this.subtitle, required this.actionLabel, required this.icon, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(label: actionLabel, onTap: onAction, variant: AppButtonVariant.outlined),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question, answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        children: [
           Padding(
             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
             child: Text(answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
           ),
        ],
      ),
    );
  }
}
