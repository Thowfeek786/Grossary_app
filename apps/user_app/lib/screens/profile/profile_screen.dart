import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Profile', showBackButton: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primarySurface,
                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ProfileItem(
                    icon: Icons.location_on_outlined,
                    title: 'My Addresses',
                    onTap: () => context.push('/profile/addresses'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ProfileItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () => context.push('/profile/notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => context.push('/profile/help'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ProfileItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => context.push('/profile/about'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ProfileItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    textColor: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: () => _confirmLogout(context, auth),
                    showChevron: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => _confirmDelete(context, auth),
                child: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is irreversible. All your order history and saved addresses will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Permanent'),
          ),
        ],
      ),
    );
    
    if (ok == true) {
      await auth.deleteAccount();
      if (auth.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) auth.logout();
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final bool showChevron;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor ?? AppColors.textPrimary)),
      trailing: showChevron ? const Icon(Icons.chevron_right_rounded, color: AppColors.grey400) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
