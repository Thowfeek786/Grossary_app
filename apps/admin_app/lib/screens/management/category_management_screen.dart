import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';

import 'add_edit_category_screen.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final management = context.watch<AdminManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Category Management',
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: management.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final categories = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final c = categories[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    CircleAvatar(
                      radius: 28, backgroundColor: AppColors.primarySurface,
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 20)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary), onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditCategoryScreen(category: c)));
                         }),
                         IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), onPressed: () => management.deleteCategory(c.id)),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}
