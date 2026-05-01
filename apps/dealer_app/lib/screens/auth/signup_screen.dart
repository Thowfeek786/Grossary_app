import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/auth_provider.dart';

class DealerSignupScreen extends StatefulWidget {
  const DealerSignupScreen({super.key});

  @override
  State<DealerSignupScreen> createState() => _DealerSignupScreenState();
}

class _DealerSignupScreenState extends State<DealerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DealerAuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text('Dealer Registration', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const Text('Start selling your products on GroceryGo', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 48),
                AppTextField(label: 'Store/Dealer Name', controller: _nameCtrl, validator: Validators.required),
                const SizedBox(height: 16),
                AppTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: Validators.email),
                const SizedBox(height: 16),
                AppTextField(label: 'Phone Number', controller: _phoneCtrl, keyboardType: TextInputType.phone, validator: Validators.phone),
                const SizedBox(height: 16),
                AppTextField(label: 'Password', controller: _passCtrl, obscureText: true, validator: Validators.password),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Register My Store',
                  isLoading: auth.isLoading,
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await auth.signup(
                        name: _nameCtrl.text.trim(),
                        email: _emailCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim(),
                        password: _passCtrl.text.trim(),
                      );
                      if (success && mounted) context.go('/dashboard');
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(onPressed: () => context.go('/login'), child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
