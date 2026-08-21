import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'admin_order_detail_screen.dart';

class PartnerDetailsScreen extends StatefulWidget {
  final UserModel user;

  const PartnerDetailsScreen({super.key, required this.user});

  @override
  State<PartnerDetailsScreen> createState() => _PartnerDetailsScreenState();
}

class _PartnerDetailsScreenState extends State<PartnerDetailsScreen> {
  final UserRepository _userRepo = UserRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();

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

  Future<void> _toggleApprovalStatus(UserModel user) async {
    try {
      final newStatus = !user.isApproved;
      await _userRepo.setUserApproval(user.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? '🎉 Partner approved and verified!' : '⚠️ Partner suspended.'),
            backgroundColor: newStatus ? const Color(0xFF059669) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _toggleActiveStatus(UserModel user) async {
    try {
      final newStatus = !user.isActive;
      await _userRepo.setUserActive(user.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Account activated' : 'Account blocked'),
            backgroundColor: newStatus ? const Color(0xFF059669) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.id).snapshots(),
      builder: (context, snapshot) {
        UserModel user = widget.user;
        if (snapshot.hasData && snapshot.data!.exists) {
          try {
            user = UserModel.fromFirestore(snapshot.data!);
          } catch (_) {}
        }

        final isDealer = user.role == UserRole.dealer;
        final isDelivery = user.role == UserRole.deliveryPartner;
        final hasImage = user.photoUrl != null && user.photoUrl!.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: isDealer ? 'Dealer & Vendor Profile' : 'Delivery Partner Profile',
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => _showSendNotificationDialog(context, user),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                tooltip: 'Send Push Notification',
              ),
              IconButton(
                onPressed: () => _showEditPartnerDialog(context, user),
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Profile Card
                _buildHeroCard(user, isDealer, hasImage),

                const SizedBox(height: 20),

                // Realtime Metrics Grid
                _buildMetricsGrid(user, isDealer),

                const SizedBox(height: 24),

                // Payout Information Card
                _buildSectionHeader('Payout Accounts & Banking'),
                const SizedBox(height: 10),
                _buildPayoutCard(user),

                const SizedBox(height: 24),

                // Vehicle or Store Details Card
                if (isDealer) ...[
                  _buildSectionHeader('Store & Logistics Profile'),
                  const SizedBox(height: 10),
                  _buildDealerStoreCard(user),
                ] else if (isDelivery) ...[
                  _buildSectionHeader('Vehicle & Fleet Profile'),
                  const SizedBox(height: 10),
                  _buildDeliveryVehicleCard(user),
                ],

                const SizedBox(height: 24),

                // Quick Admin Controls
                _buildSectionHeader('Account Controls & Privileges'),
                const SizedBox(height: 10),
                _buildAdminControlsCard(user),

                const SizedBox(height: 24),

                // Recent Orders Activity Stream
                _buildSectionHeader(isDealer ? 'Recent Store Orders' : 'Recent Trip Deliveries'),
                const SizedBox(height: 10),
                _buildRecentOrdersStream(user, isDealer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(UserModel user, bool isDealer, bool hasImage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDealer
              ? [const Color(0xFF0B3C26), const Color(0xFF13653F), const Color(0xFF0A2B1C)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
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
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: user.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              errorWidget: (_, _, _) => _buildInitialsAvatar(user),
                            )
                          : _buildInitialsAvatar(user),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: user.isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
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
                            user.name.isNotEmpty ? user.name : 'Grocery Partner',
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
                            color: user.isApproved
                                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                : const Color(0xFFEF4444).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: user.isApproved ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Text(
                            user.isApproved ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              color: user.isApproved ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
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
                          ? (user.shopName ?? 'Store Partner')
                          : 'Fleet Driver • ${user.vehicleType ?? "Bike"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone.isNotEmpty ? user.phone : user.email,
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
                  onPressed: user.phone.isNotEmpty ? () => _makeCall(user.phone) : null,
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
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: user.phone.isNotEmpty ? () => _openWhatsApp(user.phone, user.name) : null,
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
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _toggleApprovalStatus(user),
                style: OutlinedButton.styleFrom(
                  foregroundColor: user.isApproved ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  side: BorderSide(
                    color: user.isApproved ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Text(
                  user.isApproved ? 'Suspend' : 'Approve',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(UserModel user, bool isDealer) {
    final stream = isDealer
        ? _orderRepo.getOrdersByDealer(user.id)
        : _orderRepo.getOrdersByDeliveryPartner(user.id);

    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();

        double computedTotal = 0.0;
        if (isDealer) {
          for (final o in deliveredOrders) {
            computedTotal += o.total;
          }
        } else {
          for (final o in deliveredOrders) {
            computedTotal += o.deliveryFee > 0 ? o.deliveryFee : 45.0;
          }
        }

        final earningsDisplay = computedTotal > 0 ? computedTotal : user.totalEarnings;
        final ordersDisplay = deliveredOrders.isNotEmpty ? deliveredOrders.length : (user.totalDeliveries > 0 ? user.totalDeliveries : orders.length);

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: isDealer ? 'Gross Sales' : 'Trip Earnings',
                value: '₹${earningsDisplay.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: isDealer ? 'Orders Done' : 'Trips Done',
                value: '$ordersDisplay',
                icon: isDealer ? Icons.receipt_long_rounded : Icons.two_wheeler_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Rating',
                value: user.rating != null && user.rating! > 0 ? '${user.rating!.toStringAsFixed(1)} ★' : '5.0 ★',
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPayoutCard(UserModel user) {
    final hasBank = user.bankName != null && user.bankName!.isNotEmpty && user.accountNumber != null && user.accountNumber!.isNotEmpty;
    final hasUpi = user.upiId != null && user.upiId!.isNotEmpty;

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UPI ID (Virtual Payment Address)', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text(user.upiId!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(user.upiId!, 'UPI ID'),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ],
            ),
            if (hasBank) const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ],
          if (hasBank) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user.bankName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                      Text(
                        'A/C: ${user.accountNumber} • IFSC: ${user.ifscCode ?? "N/A"}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      if (user.accountHolder != null && user.accountHolder!.isNotEmpty)
                        Text('Holder: ${user.accountHolder}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(user.accountNumber ?? '', 'Account Number'),
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

  Widget _buildDealerStoreCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Store Name', user.shopName ?? 'GroceryGo Darkstore', Icons.storefront_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Store Address', user.shopAddress ?? 'Main Commercial Market', Icons.location_on_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Registered Email', user.email, Icons.email_rounded),
        ],
      ),
    );
  }

  Widget _buildDeliveryVehicleCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Vehicle Type', user.vehicleType ?? 'Two-Wheeler (Motorcycle/Scooter)', Icons.two_wheeler_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Vehicle Registration (RC)', user.rcNumber ?? 'TN 07 AB 1234', Icons.badge_rounded),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Driving License (DL)', user.dlNumber ?? 'DL-1420110012345', Icons.credit_card_rounded),
        ],
      ),
    );
  }

  Widget _buildAdminControlsCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('Toggle account activation/login access', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Switch(
                value: user.isActive,
                onChanged: (_) => _toggleActiveStatus(user),
                activeTrackColor: const Color(0xFF10B981),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verification Badge', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('Grant verified partner status', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Switch(
                value: user.isApproved,
                onChanged: (_) => _toggleApprovalStatus(user),
                activeTrackColor: const Color(0xFF10B981),
              ),
            ],
          ),
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

  Widget _buildRecentOrdersStream(UserModel user, bool isDealer) {
    final stream = isDealer
        ? _orderRepo.getOrdersByDealer(user.id)
        : _orderRepo.getOrdersByDeliveryPartner(user.id);

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
          itemCount: orders.length > 8 ? 8 : orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final o = orders[i];
            final shortId = o.id.length >= 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase();
            final dateStr = DateFormat('dd MMM, hh:mm a').format(o.createdAt);

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: o.id)),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
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
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 18),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${o.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInitialsAvatar(UserModel user) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P';
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

  void _showSendNotificationDialog(BuildContext context, UserModel user) {
    final titleCtrl = TextEditingController(text: 'Message from GroceryGo Operations');
    final bodyCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Text('Notify ${user.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notification Body', hintText: 'Enter dispatch notice or instructions...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final body = bodyCtrl.text.trim();
                      if (body.isEmpty) return;

                      setDialogState(() => isSending = true);
                      await _notificationRepo.sendNotification(
                        NotificationModel(
                          id: '',
                          userId: user.id,
                          title: titleCtrl.text.trim(),
                          body: body,
                          type: 'admin_broadcast',
                          createdAt: DateTime.now(),
                        ),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Push notification dispatched to partner!'), backgroundColor: Color(0xFF059669)),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              child: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Alert'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPartnerDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final shopNameCtrl = TextEditingController(text: user.shopName ?? '');
    final shopAddrCtrl = TextEditingController(text: user.shopAddress ?? '');
    final vehicleCtrl = TextEditingController(text: user.vehicleType ?? '');
    final rcCtrl = TextEditingController(text: user.rcNumber ?? '');
    final dlCtrl = TextEditingController(text: user.dlNumber ?? '');
    final upiCtrl = TextEditingController(text: user.upiId ?? '');
    final bankCtrl = TextEditingController(text: user.bankName ?? '');
    final accCtrl = TextEditingController(text: user.accountNumber ?? '');
    final ifscCtrl = TextEditingController(text: user.ifscCode ?? '');

    final isDealer = user.role == UserRole.dealer;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF0F172A)),
              SizedBox(width: 10),
              Text('Edit Partner Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  if (isDealer) ...[
                    TextField(controller: shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop / Darkstore Name', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: shopAddrCtrl, decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                  ] else ...[
                    TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type (Bike/Scooter)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: rcCtrl, decoration: const InputDecoration(labelText: 'RC Plate Number', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: dlCtrl, decoration: const InputDecoration(labelText: 'Driving License (DL)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                  ],
                  TextField(controller: upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID (VPA)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'shopName': shopNameCtrl.text.trim(),
                          'shopAddress': shopAddrCtrl.text.trim(),
                          'vehicleType': vehicleCtrl.text.trim(),
                          'rcNumber': rcCtrl.text.trim().toUpperCase(),
                          'dlNumber': dlCtrl.text.trim().toUpperCase(),
                          'upiId': upiCtrl.text.trim(),
                          'bankName': bankCtrl.text.trim(),
                          'accountNumber': accCtrl.text.trim(),
                          'ifscCode': ifscCtrl.text.trim().toUpperCase(),
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🎉 Partner profile updated successfully!'), backgroundColor: Color(0xFF059669)),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
