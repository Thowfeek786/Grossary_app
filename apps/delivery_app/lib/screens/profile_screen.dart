import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      await context.read<DeliveryAuthProvider>().updateProfileImage(File(img.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Partner Profile'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(context, auth, user),
            const SizedBox(height: 32),
            _buildStatGrid(context, user),
            const SizedBox(height: 32),
            _buildActionSection(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, DeliveryAuthProvider auth, UserModel user) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.1), width: 4),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.grey100,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 48))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white))
                      : const Icon(Icons.camera_alt_rounded,
                          color: AppColors.white, size: 16),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5)),
            const SizedBox(width: 8),
            if (user.isApproved)
              const Icon(Icons.verified_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
        Text(user.email,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: user.isApproved
                ? AppColors.success.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            user.isApproved ? 'VERIFIED PARTNER' : 'PENDING APPROVAL',
            style: TextStyle(
              color: user.isApproved ? AppColors.success : AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(BuildContext context, UserModel user) {
    final delivery = context.watch<DeliveryProvider>();
    
    return StreamBuilder<List<OrderModel>>(
      stream: delivery.getDeliveryHistory(user.id),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final completed = history.length;
        final earnings = completed * 45.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.grey200),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat('Deliveries', '$completed',
                      Icons.local_shipping_rounded, AppColors.primary),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _ProfileStat('Earnings', '₹${earnings.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded, AppColors.success),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _ProfileStat('Rating', '${user.rating ?? 4.8}', 
                      Icons.star_rounded, AppColors.warning),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildActionSection(BuildContext context, DeliveryAuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GENERAL SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 16),
        _buildMenuCard(
          Icons.account_balance_wallet_rounded, 
          'Withdraw Funds', 
          'Request payout to your bank', 
          () => context.push('/withdraw'),
        ),
        _buildMenuCard(
          Icons.payment_rounded, 
          'Bank Details', 
          'View payout information', 
          () => context.push('/bank-details'),
        ),
        _buildMenuCard(
          Icons.analytics_rounded, 
          'Earnings History', 
          'Detailed payout breakdown', 
          () => context.push('/earnings'),
        ),
        _buildMenuCard(
          Icons.support_agent_rounded, 
          'Partner Support', 
          'Get help with deliveries', 
          () => context.push('/support'),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Logout Account',
          variant: AppButtonVariant.outlined,
          onTap: () => auth.logout(),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteConfirmation(context, auth),
            child: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, DeliveryAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is irreversible. All your delivery history and earnings records will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.deleteAccount();
              if (auth.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey400),
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
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.grey200);
  }
}
