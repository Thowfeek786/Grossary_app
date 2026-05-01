import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primarySurface,
                    child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'Enter your name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: 'Enter your phone',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 48),
            AppButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    // Simulate update
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
    setState(() => _isLoading = false);
  }
}
