import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _login() async {
    final auth = context.read<AdminAuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminAuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Authenticate to manage the Grocery Platform',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Admin Email',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Master Password',
                  controller: _passCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Secure Login',
                  isLoading: isLoading,
                  onTap: _login,
                  variant: AppButtonVariant.danger,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
