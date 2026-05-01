import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Admin Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50, backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.admin_panel_settings_rounded, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('SUPER ADMIN', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
            const SizedBox(height: 40),
            _buildActionTile(Icons.security_rounded, 'Security Settings', (){}),
            _buildActionTile(Icons.notifications_active_rounded, 'System Notifications', (){}),
            _buildActionTile(Icons.backup_rounded, 'Database Backup', (){}),
            _buildActionTile(Icons.settings_rounded, 'Platform Settings', (){}),
            const SizedBox(height: 40),
            AppButton(
              label: 'Sign Out',
              variant: AppButtonVariant.outlined,
              onTap: () => auth.logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
