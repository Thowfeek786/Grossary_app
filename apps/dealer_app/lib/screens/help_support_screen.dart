import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class DealerHelpSupportScreen extends StatefulWidget {
  const DealerHelpSupportScreen({super.key});

  @override
  State<DealerHelpSupportScreen> createState() => _DealerHelpSupportScreenState();
}

class _DealerHelpSupportScreenState extends State<DealerHelpSupportScreen> {
  final _msgCtrl = TextEditingController();
  String _selectedCategory = 'Payout & Settlement';
  String _selectedPriority = 'Normal';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Payout & Settlement',
    'Order & Rider Dispatch',
    'Product Catalog & Stock',
    'Store Radius & Timings',
    'Account & Verification',
    'Other Technical Inquiry',
  ];

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  Future<void> _openWhatsApp(String phone, String storeName) async {
    final text = Uri.encodeComponent('Hello GroceryGo Vendor Support Team,\n\nI need assistance for my store *$storeName*.');
    final uri = Uri.parse('https://wa.me/$phone?text=$text');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp error: $e');
    }
  }

  Future<void> _sendEmail(String email, String storeName, String storeEmail) async {
    final subject = Uri.encodeComponent('GroceryGo Vendor Partner Support - $storeName');
    final body = Uri.encodeComponent('Store Name: $storeName\nRegistered Email: $storeEmail\n\nPlease describe your query here:');
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Email error: $e');
    }
  }

  Future<void> _submitTicket(String userId, String storeName, String storeEmail) async {
    final message = _msgCtrl.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a brief description of your issue.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ticketRef = FirebaseFirestore.instance.collection('support_tickets').doc();
      await ticketRef.set({
        'id': ticketRef.id,
        'userId': userId,
        'userRole': 'dealer',
        'storeName': storeName,
        'storeEmail': storeEmail,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also send notification into queue
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Support Ticket Logged #${ticketRef.id.substring(0, 6).toUpperCase()}',
        'body': 'Your inquiry for "$_selectedCategory" has been submitted. Our partner team will reach out within 30 minutes.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'support',
      });

      if (!mounted) return;

      _msgCtrl.clear();
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Support Request Sent!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Ticket ID: #${ticketRef.id.substring(0, 8).toUpperCase()}\nOur vendor operations desk will review and contact you shortly.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit ticket: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final storeName = user.shopName ?? user.name;
    const helplineNumber = '+919876543210';
    const helplineTollFree = '1800889988';
    const supportEmail = 'partners@grocerygo.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Vendor Partner Helpline',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Emerald Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                          color: const Color(0xFF34D399).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF34D399), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '24/7 Merchant Support Desk',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34D399),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Live Dispatch Agents Online',
                                  style: TextStyle(color: Color(0xFF86EFAC), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Need urgent assistance with order dispatch, rider assignment, or settlements? Reach out to our dedicated merchant priority team.',
                    style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 1-Tap Quick Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Direct Partner Contacts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ContactActionCard(
                          title: 'Call Priority Desk',
                          subtitle: 'Toll-Free $helplineTollFree',
                          icon: Icons.phone_in_talk_rounded,
                          color: const Color(0xFF059669),
                          onTap: () => _makeCall(helplineTollFree),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContactActionCard(
                          title: 'WhatsApp Dispatch',
                          subtitle: 'Instant chat support',
                          icon: Icons.chat_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => _openWhatsApp(helplineNumber.replaceAll('+', ''), storeName),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _ContactActionCard(
                    title: 'Email Partner Relations',
                    subtitle: supportEmail,
                    icon: Icons.mail_outline_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _sendEmail(supportEmail, storeName, user.email),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Support Request Ticket Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined, color: Color(0xFF059669), size: 22),
                        SizedBox(width: 8),
                        Text('Create Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Submit an issue to have our technical team investigate and resolve it.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    const SizedBox(height: 16),

                    // Issue Category Dropdown
                    const Text('Issue Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Priority Selector
                    const Text('Urgency Level', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Normal', 'High', 'Critical'].map((p) {
                        final isSel = _selectedPriority == p;
                        Color pColor = const Color(0xFF059669);
                        if (p == 'High') pColor = const Color(0xFFF59E0B);
                        if (p == 'Critical') pColor = const Color(0xFFEF4444);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: isSel,
                            onSelected: (_) => setState(() => _selectedPriority = p),
                            selectedColor: pColor,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 11.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Issue Message Text Field
                    const Text('Describe Your Issue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _msgCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'e.g. Rider not assigned for Order #ORD1234 or Payout query...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitTicket(user.id, storeName, user.email),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Submit Priority Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Vendor FAQs Accordion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),

                  _FaqTile(
                    question: 'How do dealer payout settlements work?',
                    answer: 'Payouts are computed from delivered orders. You can request instant settlement to your linked Bank Account or UPI VPA from the Payment & Payout Accounts screen. Standard processing takes under 15 minutes.',
                  ),
                  _FaqTile(
                    question: 'What if a delivery partner does not arrive on time?',
                    answer: 'If an order has been accepted and prepared but no delivery partner arrives within 10 minutes, tap WhatsApp Dispatch or Toll-Free Helpline to have our dispatch team assign an emergency backup rider.',
                  ),
                  _FaqTile(
                    question: 'How do I temporarily pause incoming store orders?',
                    answer: 'Toggle the Store OPEN / CLOSED switch at the top right of your Vendor Controls dashboard anytime you need to pause new incoming orders.',
                  ),
                  _FaqTile(
                    question: 'How do promotional discounts & BOGO affect my payout?',
                    answer: 'Promotions you configure in the Add/Edit Product screen apply directly to the customer price. Your net payout reflects the final payable item amount.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
        children: [
          Text(answer, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
