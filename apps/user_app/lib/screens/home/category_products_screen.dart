import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/cart_provider.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  const CategoryProductsScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: categoryName),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductRepository().getProducts(categoryId: categoryId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AppLoader();
          if (snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No products in this category',
              subtitle: 'Check back soon for new arrivals!',
            );
          }
          final products = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.88,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (ctx, i) => ProductCard(
                product: products[i],
                onTap: () => context.push('/home/product/${products[i].id}'),
                onAddToCart: () => context.read<CartProvider>().addItem(products[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}
