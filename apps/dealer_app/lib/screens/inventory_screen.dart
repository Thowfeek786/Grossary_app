import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'My Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => context.push('/add-product'),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductRepository().getProducts(dealerId: user.id, activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Empty Inventory',
              subtitle: 'You haven\'t added any products yet.',
              actionLabel: 'Add Product',
              onAction: () => context.push('/add-product'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final p = products[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.inStock ? AppColors.grey200 : AppColors.error.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: p.imageUrls.isNotEmpty
                          ? Image.network(p.imageUrls.first, width: 60, height: 60, fit: BoxFit.cover)
                          : Container(width: 60, height: 60, color: AppColors.grey100, child: const Icon(Icons.image_outlined)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('₹${p.price.toStringAsFixed(0)} / ${p.unit}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.inStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.inStock ? 'Stock: ${p.stockQuantity}' : 'Out of Stock',
                              style: TextStyle(color: p.inStock ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          )
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          value: p.isActive,
                          onChanged: (v) => ProductRepository().toggleProductActive(p.id, v),
                          activeColor: AppColors.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.grey500),
                          onPressed: () => context.push('/add-product', extra: p),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
