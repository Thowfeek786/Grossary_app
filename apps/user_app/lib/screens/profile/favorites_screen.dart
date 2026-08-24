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
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _EmptyFavoritesView(
              isGuest: true,
              onAction: () => context.push('/login'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: _EmptyFavoritesView(
                  isGuest: false,
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

// ─────────────────────────────────────────────
// Beautiful Redesigned Empty Favorites View
// ─────────────────────────────────────────────
class _EmptyFavoritesView extends StatelessWidget {
  final bool isGuest;
  final VoidCallback onAction;

  const _EmptyFavoritesView({
    required this.isGuest,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'emoji': '🍎', 'name': 'Fresh Fruits'},
      {'emoji': '🥦', 'name': 'Vegetables'},
      {'emoji': '🥛', 'name': 'Dairy & Eggs'},
      {'emoji': '🍪', 'name': 'Snacks & Munchies'},
      {'emoji': '🍞', 'name': 'Bakery'},
      {'emoji': '🥤', 'name': 'Beverages'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Visual Hero Icon with Multi-Layer Glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Soft Ambient Glow
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              ),
            ),
            // Middle Concentric Ring
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            // Core Elevated Card with Gradient Heart
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isGuest ? Icons.lock_outline_rounded : Icons.favorite_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
            // Floating Mini Sparkle Badge
            Positioned(
              top: 14,
              right: 18,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Heading
        Text(
          isGuest ? 'Sign In to View Favorites' : 'Your Wishlist is Empty',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isGuest
                ? 'Sign in to access your saved groceries, track price drops, and quickly reorder your favorite items anytime.'
                : 'Explore thousands of fresh farm produce, dairy, and grocery essentials. Tap the ❤️ icon on any product to save it here!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Primary Action CTA
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: const Color(0xFF059669).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isGuest ? Icons.login_rounded : Icons.shopping_bag_outlined,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  isGuest ? 'Sign In / Register' : 'Explore Fresh Groceries',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ),
          ),
        ),

        if (!isGuest) ...[
          const SizedBox(height: 32),

          // Quick Category Explorer Title
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Browse by Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Discovery Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              return InkWell(
                onTap: () => context.go('/categories'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        cat['name']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Benefit Highlights Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF059669), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Items in your wishlist can be ordered with 1-tap from your home screen!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

