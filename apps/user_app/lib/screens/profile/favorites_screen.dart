import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final favRepo = FavoriteRepository();

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const CustomAppBar(
          title: 'My Favorites',
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Please Log In',
            subtitle: 'Log in to save and manage your favorite items.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: favRepo.getFavoriteProducts(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Favorites Saved Yet',
                  subtitle:
                      'Tap the heart icon on any product to quickly save your top choices here!',
                  actionLabel: 'Browse Products',
                  onAction: () => context.go('/home'),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${favorites.length} Saved Items',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Grid View of Favorite Product Cards
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (ctx, idx) {
                    final product = favorites[idx];
                    return _FavoriteProductCard(
                      product: product,
                      userId: user.id,
                      favRepo: favRepo,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  final ProductModel product;
  final String userId;
  final FavoriteRepository favRepo;

  const _FavoriteProductCard({
    required this.product,
    required this.userId,
    required this.favRepo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with Animated Heart Button
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: product.imageUrls.isNotEmpty &&
                              product.imageUrls.first.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedHeartButton(
                      isFavorite: true,
                      onTap: () async {
                        await favRepo.toggleFavorite(userId, product.id);
                        if (context.mounted) {
                          AppSnackBar.show(
                            context,
                            message: '${product.name} removed from favorites',
                            backgroundColor: const Color(0xFF64748B),
                            icon: const Icon(Icons.heart_broken_rounded, color: Colors.white, size: 18),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Product Details & Add Button
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.unit,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<CartProvider>().addItem(product);
                          AppSnackBar.show(
                            context,
                            message: '${product.name} added to cart!',
                            backgroundColor: const Color(0xFF059669),
                            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '+ ADD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
