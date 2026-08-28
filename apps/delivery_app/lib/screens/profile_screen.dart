import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null && context.mounted) {
      await context.read<DeliveryAuthProvider>().updateProfileImage(File(img.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Partner Profile',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(context, auth, user),
            const SizedBox(height: 24),
            _buildStatGrid(context, user),
            const SizedBox(height: 24),
            _buildActionSection(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, DeliveryAuthProvider auth, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage(context),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2), width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 40),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name.isNotEmpty ? user.name : 'Delivery Partner',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (user.isApproved) const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 20),
            ],
          ),
          Text(
            user.email.isNotEmpty ? user.email : (user.phone.isNotEmpty ? user.phone : 'Delivery Partner Account'),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (user.phone.isNotEmpty && user.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '📞 ${user.phone}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isApproved ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user.isApproved ? 'VERIFIED PARTNER' : 'PENDING APPROVAL',
                  style: TextStyle(
                    color: user.isApproved ? const Color(0xFF059669) : const Color(0xFFD97706),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (user.vehicleType != null && user.vehicleType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 12, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text(
                        user.vehicleType!.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Text(
                      user.rating != null && user.rating! > 0 ? user.rating!.toStringAsFixed(1) : '4.9',
                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, UserModel user) {
    final delivery = context.watch<DeliveryProvider>();

    return StreamBuilder<List<OrderModel>>(
      stream: delivery.getDeliveryHistory(user.id),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final completed = history.length > user.totalDeliveries ? history.length : user.totalDeliveries;
        final earnings = user.totalEarnings > 0 ? user.totalEarnings : (completed * 45.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat('Deliveries', '$completed', Icons.local_shipping_rounded, const Color(0xFF059669)),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _ProfileStat('Earned', '₹${earnings.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _ProfileStat('Rating', '${user.rating ?? 4.9} ★', Icons.star_rounded, const Color(0xFFF59E0B)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSection(BuildContext context, DeliveryAuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PARTNER SETTINGS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          Icons.account_balance_wallet_rounded,
          'Withdraw Funds',
          'Request payout to your bank',
          () => context.push('/withdraw'),
        ),
        _buildMenuCard(
          Icons.payment_rounded,
          'Bank Details',
          'View payout account info',
          () => context.push('/bank-details'),
        ),
        _buildMenuCard(
          Icons.analytics_rounded,
          'Earnings History',
          'Detailed payout breakdown',
          () => context.push('/earnings'),
        ),
        StreamBuilder<DealerDriverModel?>(
          stream: DealerFleetRepository().streamDriverAffiliation(auth.user?.phone.replaceAll(RegExp(r'[^0-9]'), '') ?? ''),
          builder: (context, affilSnap) {
            final affil = affilSnap.data;
            return _buildMenuCard(
              Icons.storefront_rounded,
              'Dark Store Fleet Affiliation',
              affil != null ? 'Dedicated Partner for ${affil.dealerName}' : 'Enter dealer invite code to join fleet',
              () => context.push('/joined-stores'),
            );
          },
        ),
        _buildMenuCard(
          Icons.two_wheeler_rounded,
          'Vehicle & Documents',
          'Manage vehicle type & DL/RC verification',
          () => context.push('/vehicle-documents'),
        ),
        _buildMenuCard(
          Icons.headset_mic_rounded,
          'Partner Support Desk',
          'Contact 24/7 dispatch helpline',
          () => _showSupportModal(context),
        ),
        _buildMenuCard(
          Icons.gavel_rounded,
          'Terms of Service',
          'Read partner terms & safety guidelines',
          () => context.push('/terms'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => auth.logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout Partner Account', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteConfirmation(context, auth),
            child: const Text('Delete Account', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partner Support Desk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Need assistance with active deliveries or payout issues?', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 16),
            const SelectableText('📞 Hotline: 1800-476-2379', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669))),
            const SizedBox(height: 4),
            const SelectableText('✉️ Email: partner-support@grocerygo.com', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DeliveryAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This action is irreversible. All your delivery history and earnings records will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 18),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color, letterSpacing: -0.5)),
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
  }
}
