import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'About Us'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.local_grocery_store_rounded, color: AppColors.primary, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('GroceryGo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
            const Text('Version 1.0.0 (Building #42)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 40),
            const Text(
              'GroceryGo is your all-in-one platform for fresh groceries delivered right to your doorstep. We partner with local dealers and dedicated delivery partners to ensure you get the best quality items in the shortest time possible.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 48),
            _LinkTile(label: 'Terms of Service', onTap: () {}),
            _LinkTile(label: 'Privacy Policy', onTap: () {}),
            _LinkTile(label: 'Licenses', onTap: () {}),
            const SizedBox(height: 60),
            const Text('© 2026 GroceryGo. All rights reserved.', style: TextStyle(color: AppColors.grey400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
        onTap: onTap,
      ),
    );
  }

}
