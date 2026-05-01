import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthRepository().sendPasswordResetEmail(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Forgot Password'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_rounded,
                      size: 72, color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text('Reset Email Sent!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text('Check your inbox at ${_emailCtrl.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  AppButton(label: 'Back to Login', onTap: () => Navigator.pop(context)),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Reset Password',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                        'Enter your email and we\'ll send you a link to reset your password.',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Send Reset Link',
                      isLoading: _isLoading,
                      onTap: _send,
                      icon: Icons.send_rounded,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
