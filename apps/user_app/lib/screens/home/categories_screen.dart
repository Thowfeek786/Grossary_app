import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'All Categories', showBackButton: false),
      body: StreamBuilder<List<CategoryModel>>(
        stream: CategoryRepository().getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          if (snapshot.hasError) {
            return AppErrorWidget(message: snapshot.error.toString());
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'No Categories Found',
              subtitle: 'Check back later for fresh categories!',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return _CategoryGridItem(
                category: cat,
                onTap: () => context.push(
                  '/home/category/${cat.id}',
                  extra: {'name': cat.name},
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  const _CategoryGridItem({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
                boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 4)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: category.imageUrl != null
                    ? Image.network(
                        category.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.category_rounded, color: AppColors.primary, size: 32),
                      )
                    : const Icon(Icons.category_rounded, color: AppColors.primary, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
