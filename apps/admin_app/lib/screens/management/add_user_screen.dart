import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final management = context.read<AdminManagementProvider>();
    
    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      createdAt: DateTime.now(),
      isActive: true,
      isApproved: true,
    );

    final success = await management.addUser(newUser);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('User added successfully'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminManagementProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Add New User'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a new platform account manually.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Full Name',
                controller: _nameController,
                hint: 'Enter full name',
                validator: (v) => v?.trim().isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email Address',
                controller: _emailController,
                hint: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v != null && v.contains('@')) ? null : 'Invalid email',
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                controller: _phoneController,
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                validator: (v) => (v != null && v.trim().length == 10) ? null : 'Enter 10-digit phone',
              ),
              const SizedBox(height: 24),
              const Text('Select User Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  children: UserRole.values.map((role) {
                    final isLast = role == UserRole.values.last;
                    return Column(
                      children: [
                        RadioListTile<UserRole>(
                          title: Text(
                            role.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(_roleDesc(role), style: const TextStyle(fontSize: 11)),
                          value: role,
                          groupValue: _selectedRole,
                          onChanged: (v) => setState(() => _selectedRole = v!),
                          activeColor: AppColors.primary,
                        ),
                        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),
              AppButton(
                label: 'Create User',
                isLoading: isLoading,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleDesc(UserRole role) {
    switch (role) {
      case UserRole.customer: return 'Standard user who can browse and buy products';
      case UserRole.dealer: return 'Stock owner/Wholesaler who manages inventory';
      case UserRole.deliveryPartner: return 'Logistics personnel who delivers orders';
      case UserRole.admin: return 'Platform manager with full access to settings';
    }
  }
}
