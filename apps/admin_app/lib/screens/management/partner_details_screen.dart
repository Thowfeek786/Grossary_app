import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';

class PartnerDetailsScreen extends StatefulWidget {
  final UserModel user;

  const PartnerDetailsScreen({super.key, required this.user});

  @override
  State<PartnerDetailsScreen> createState() => _PartnerDetailsScreenState();
}

class _PartnerDetailsScreenState extends State<PartnerDetailsScreen> {
  final UserRepository _userRepo = UserRepository();
  final OrderRepository _orderRepo = OrderRepository();

  late UserModel _currentUser;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final text = Uri.encodeComponent('Hello $name, this is GroceryGo Admin operations.');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp error: $e');
    }
  }

  Future<void> _toggleApprovalStatus() async {
    setState(() => _isUpdatingStatus = true);
    try {
      final newStatus = !_currentUser.isApproved;
      await _userRepo.setUserApproval(_currentUser.id, newStatus);
      setState(() {
        _currentUser = _currentUser.copyWith(isApproved: newStatus);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Partner approved successfully!' : 'Partner suspended.'),
            backgroundColor: newStatus ? const Color(0xFF059669) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDealer = _currentUser.role == UserRole.dealer;
    final isDelivery = _currentUser.role == UserRole.deliveryPartner;
    final hasImage = _currentUser.photoUrl != null && _currentUser.photoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: isDealer ? 'Dealer & Vendor Details' : 'Delivery Partner Details',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDealer
                      ? [const Color(0xFF0B3C26), const Color(0xFF13653F)]
                      : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Profile Image / Avatar
                      Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: hasImage
                                  ? CachedNetworkImage(
                                      imageUrl: _currentUser.photoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                      errorWidget: (_, _, _) => _buildInitialsAvatar(),
                                    )
                                  : _buildInitialsAvatar(),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _currentUser.isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentUser.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _currentUser.isApproved
                                        ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _currentUser.isApproved ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Text(
                                    _currentUser.isApproved ? 'VERIFIED' : 'PENDING APPROVAL',
                                    style: TextStyle(
                                      color: _currentUser.isApproved ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDealer
                                  ? (_currentUser.shopName ?? 'Darkstore Partner')
                                  : 'Fleet Driver • ${_currentUser.vehicleType ?? "Bike"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentUser.phone.isNotEmpty ? _currentUser.phone : _currentUser.email,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentUser.phone.isNotEmpty ? () => _makeCall(_currentUser.phone) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF2563EB)),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentUser.phone.isNotEmpty ? () => _openWhatsApp(_currentUser.phone, _currentUser.name) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _isUpdatingStatus ? null : _toggleApprovalStatus,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _currentUser.isApproved ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          side: BorderSide(
                            color: _currentUser.isApproved ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: Text(
                          _currentUser.isApproved ? 'Suspend' : 'Approve',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: isDealer ? 'Total Sales' : 'Lifetime Earnings',
                    value: '₹${_currentUser.totalEarnings.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: isDealer ? 'Orders Fulfilled' : 'Total Trips',
                    value: '${_currentUser.totalDeliveries}',
                    icon: isDealer ? Icons.receipt_long_rounded : Icons.two_wheeler_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Partner Rating',
                    value: _currentUser.rating != null && _currentUser.rating! > 0
                        ? '${_currentUser.rating!.toStringAsFixed(1)} ★'
                        : '5.0 ★',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Payout Destination Information Card
            _buildSectionHeader('Payout Credentials'),
            const SizedBox(height: 10),
            _buildPayoutCard(),

            const SizedBox(height: 24),

            // Store / Vehicle Details Card
            if (isDealer) ...[
              _buildSectionHeader('Store & Location Profile'),
              const SizedBox(height: 10),
              _buildDealerStoreCard(),
            ] else if (isDelivery) ...[
              _buildSectionHeader('Vehicle & Fleet Profile'),
              const SizedBox(height: 10),
              _buildDeliveryVehicleCard(),
            ],

            const SizedBox(height: 24),

            // Recent Orders Stream
            _buildSectionHeader(isDealer ? 'Recent Store Orders' : 'Recent Trip Deliveries'),
            const SizedBox(height: 10),
            _buildRecentOrdersStream(isDealer),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initial = _currentUser.name.isNotEmpty ? _currentUser.name[0].toUpperCase() : 'P';
    return Container(
      color: const Color(0xFF3B82F6),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPayoutCard() {
    final hasBank = _currentUser.bankName != null && _currentUser.bankName!.isNotEmpty && _currentUser.accountNumber != null;
    final hasUpi = _currentUser.upiId != null && _currentUser.upiId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (hasUpi) ...[
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: Color(0xFF059669), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UPI ID (VPA)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text(_currentUser.upiId!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(_currentUser.upiId!, 'UPI ID'),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ],
            ),
            if (hasBank) const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ],
          if (hasBank) ...[
            Row(
              children: [
                const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_currentUser.bankName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                      Text(
                        'A/C: ${_currentUser.accountNumber} • IFSC: ${_currentUser.ifscCode ?? "N/A"}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      if (_currentUser.accountHolder != null && _currentUser.accountHolder!.isNotEmpty)
                        Text('Holder: ${_currentUser.accountHolder}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(_currentUser.accountNumber ?? '', 'Account Number'),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
          if (!hasBank && !hasUpi)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 10),
                  Text('No payout accounts linked yet by partner.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDealerStoreCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Store Name', _currentUser.shopName ?? 'GroceryGo Darkstore', Icons.storefront_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Store Address', _currentUser.shopAddress ?? '12/4 Cross Road, Sector 5', Icons.location_on_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Registered Email', _currentUser.email, Icons.email_rounded),
        ],
      ),
    );
  }

  Widget _buildDeliveryVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Vehicle Type', _currentUser.vehicleType ?? 'Two-Wheeler (Motorcycle/Scooter)', Icons.two_wheeler_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Vehicle Registration (RC)', _currentUser.rcNumber ?? 'TN 07 AB 1234', Icons.badge_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Driving License (DL)', _currentUser.dlNumber ?? 'DL-1420110012345', Icons.credit_card_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersStream(bool isDealer) {
    final stream = isDealer
        ? _orderRepo.getOrdersByDealer(_currentUser.id)
        : _orderRepo.getOrdersByDeliveryPartner(_currentUser.id);

    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF059669))));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 36),
                SizedBox(height: 8),
                Text('No order activity recorded yet', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length > 5 ? 5 : orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final o = orders[i];
            final shortId = o.id.length >= 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase();
            final dateStr = DateFormat('dd MMM, hh:mm a').format(o.createdAt);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#$shortId • ${o.deliveryAddress.fullAddress}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('$dateStr • ${o.status.name.toUpperCase()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    '₹${o.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
