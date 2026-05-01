import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';
import 'add_edit_product_screen.dart';

class ProductsManagementScreen extends StatelessWidget {
  const ProductsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final management = context.watch<AdminManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Products Management',
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: management.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final products = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                        child: const Row(children: [Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary), SizedBox(width: 12), Text('Search products...', style: TextStyle(color: AppColors.textSecondary))]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(product: p)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(color: p.isActive ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      if (p.isFeatured) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Featured', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800)),
                                        )
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Switch(
                              value: p.isActive,
                              onChanged: (v) => management.toggleProductStatus(p.id, v),
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}
