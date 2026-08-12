import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/admin_drawer.dart';

class PayoutRequestsScreen extends StatefulWidget {
  const PayoutRequestsScreen({super.key});

  @override
  State<PayoutRequestsScreen> createState() => _PayoutRequestsScreenState();
}

class _PayoutRequestsScreenState extends State<PayoutRequestsScreen> {
  String _filter = 'All';

  List<PayoutRequestModel> _filterRequests(List<PayoutRequestModel> requests) {
    switch (_filter) {
      case 'Pending':
        return requests.where((r) => r.status == 'pending').toList();
      case 'Approved':
        return requests.where((r) => r.status == 'approved').toList();
      case 'Rejected':
        return requests.where((r) => r.status == 'rejected').toList();
      default:
        return requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Partner Payout Requests',
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
      body: StreamBuilder<List<PayoutRequestModel>>(
        stream: PayoutRepository().getPayoutRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          final rawRequests = snapshot.data ?? [];
          final requests = _filterRequests(rawRequests);

          return Column(
            children: [
              // Filter Chips Row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'Pending', 'Approved', 'Rejected'].map((cat) {
                      final isSelected = _filter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _filter = cat);
                          },
                          selectedColor: const Color(0xFF0F172A),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                          side: BorderSide(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Requests List
              Expanded(
                child: requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_outlined, size: 48, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Payout Requests ($_filter)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Manual partner withdrawal requests will appear here for admin review.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final req = requests[index];
                          return _PayoutAdminCard(request: req);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PayoutAdminCard extends StatelessWidget {
  final PayoutRequestModel request;
  const _PayoutAdminCard({required this.request});

  Future<void> _launchUpiPaymentApp(BuildContext context) async {
    final upiVpa = request.upiId != null && request.upiId!.isNotEmpty ? request.upiId! : '${request.partnerPhone}@paytm';
    final name = Uri.encodeComponent(request.partnerName);
    final amt = request.amount.toStringAsFixed(2);
    final note = Uri.encodeComponent('GroceryGo Partner Payout');

    final upiUrl = 'upi://pay?pa=$upiVpa&pn=$name&am=$amt&cu=INR&tn=$note';
    final uri = Uri.parse(upiUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback launch attempt
        final launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        if (!launched && context.mounted) {
          _showError(context, 'No installed UPI app found. Please install GPay, PhonePe, or Paytm.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Could not launch payment app: $e');
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusText;

    if (request.status == 'approved') {
      statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
      statusText = const Color(0xFF059669);
    } else if (request.status == 'rejected') {
      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      statusText = const Color(0xFFEF4444);
    } else {
      statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      statusText = const Color(0xFFD97706);
    }

    final isUpi = request.payoutMethod == 'upi' || (request.upiId != null && request.upiId!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF0F172A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.partnerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                      Text(request.partnerPhone.isNotEmpty ? request.partnerPhone : 'Delivery Partner', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Text(
                '₹${request.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF059669)),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),

          // Payment Destination Info
          Row(
            children: [
              Icon(isUpi ? Icons.qr_code_2_rounded : Icons.account_balance_rounded, size: 18, color: const Color(0xFF059669)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUpi
                      ? 'UPI ID: ${request.upiId ?? "${request.partnerPhone}@paytm"}'
                      : '${request.bankName} • A/C: ${request.accountNumber} • IFSC: ${request.ifscCode}',
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Status & Action Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
            ],
          ),

          if (request.status == 'pending') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Open Installed UPI App Button
                ElevatedButton.icon(
                  onPressed: () => _launchUpiPaymentApp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Pay via App', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),

                // Approve & Mark Paid Button
                ElevatedButton(
                  onPressed: () async {
                    await PayoutRepository().updatePayoutStatus(requestId: request.id, status: 'approved');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Payout request approved & marked paid!'), backgroundColor: Color(0xFF059669)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 1,
                  ),
                  child: const Text('Mark Paid ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),

                // Reject Button
                OutlinedButton(
                  onPressed: () async {
                    await PayoutRepository().updatePayoutStatus(requestId: request.id, status: 'rejected');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payout request rejected.'), backgroundColor: Color(0xFFEF4444)),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
