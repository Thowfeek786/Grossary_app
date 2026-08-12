import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';

class AddEditUserScreen extends StatefulWidget {
  final UserModel user;
  const AddEditUserScreen({super.key, required this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  Future<void> _submit() async {
    final management = context.read<AdminManagementProvider>();
    try {
      await management.updateUserRole(widget.user.id, _selectedRole);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Manage User',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40, backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
              child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6366F1), fontSize: 32)),
            ),
            const SizedBox(height: 16),
            Text(widget.user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(widget.user.email, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Assign Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ...UserRole.values.map((role) => RadioListTile<UserRole>(
              title: Text(role.name.toUpperCase()),
              value: role,
              groupValue: _selectedRole,
              onChanged: (v) => setState(() => _selectedRole = v!),
              activeColor: const Color(0xFF6366F1),
            )),
            const SizedBox(height: 40),
            AppButton(
              label: 'Save Changes',
              onTap: _submit,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Block User',
              variant: AppButtonVariant.danger,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
