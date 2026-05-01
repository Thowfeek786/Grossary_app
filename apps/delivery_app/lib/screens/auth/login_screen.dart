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
    final auth = context.read<DeliveryAuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DeliveryAuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Partner Portal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const Text('Login to start accepting deliveries', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              AppTextField(label: 'Partner Email', controller: _emailCtrl, prefixIcon: Icons.email_outlined),
              const SizedBox(height: 16),
              AppTextField(label: 'Password', controller: _passCtrl, obscureText: true, prefixIcon: Icons.lock_outline_rounded),
              const SizedBox(height: 32),
              AppButton(label: 'Login', isLoading: isLoading, onTap: _login),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New partner?'),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
