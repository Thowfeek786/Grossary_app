import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _repo = ProductRepository();
  int _quantity = 1;
  int _selectedImage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<ProductModel?>(
        future: _repo.getProductById(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppFullScreenLoader();
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const AppErrorWidget(message: 'Product not found');
          }
          final p = snapshot.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildImageSliver(p),
                  SliverToBoxAdapter(child: _buildDetails(context, p)),
                ],
              ),
              _buildBottomBar(context, p),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSliver(ProductModel p) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF111827)),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: Builder(
              builder: (context) {
                final user = context.watch<AuthProvider>().user;
                final favRepo = FavoriteRepository();

                if (user == null) {
                  return AnimatedHeartButton(
                    isFavorite: false,
                    size: 20,
                    onTap: () => context.push('/login'),
                  );
                }

                return StreamBuilder<bool>(
                  stream: favRepo.isFavorite(user.id, p.id),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return AnimatedHeartButton(
                      isFavorite: isFav,
                      size: 20,
                      onTap: () async {
                        final nowFav = await favRepo.toggleFavorite(user.id, p.id);
                        if (context.mounted) {
                          AppSnackBar.show(
                            context,
                            message: nowFav
                                ? '${p.name} added to favorites ❤️'
                                : '${p.name} removed from favorites',
                            backgroundColor: nowFav
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                            icon: Icon(
                              nowFav ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 20, color: Color(0xFF111827)),
              onPressed: () => context.go('/cart'),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              p.imageUrls.isEmpty
                  ? const Center(child: Icon(Icons.shopping_basket_outlined, size: 100, color: Color(0xFFD1D5DB)))
                  : PageView.builder(
                      itemCount: p.imageUrls.length,
                      onPageChanged: (i) => setState(() => _selectedImage = i),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: CachedNetworkImage(
                          imageUrl: p.imageUrls[i],
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.local_grocery_store_rounded, size: 80, color: Color(0xFF10B981)),
                          ),
                        ),
                      ),
                    ),
              if (p.imageUrls.length > 1)
                Positioned(
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      p.imageUrls.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _selectedImage ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _selectedImage ? const Color(0xFF059669) : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, ProductModel p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Admin Delivery Banner Badge
          StreamBuilder<StoreSettingsModel>(
            stream: SettingsRepository().getGlobalSettings(),
            builder: (context, settingsSnap) {
              final timingLabel = settingsSnap.data?.estimatedDeliveryTime ?? '20 to 30 minutes';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFF047857), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Superfast $timingLabel Delivery',
                      style: const TextStyle(color: Color(0xFF047857), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Product Name & Discount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.4),
                ),
              ),
              if (p.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${p.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Unit & Rating Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
                child: Text(p.unit, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${p.rating.toStringAsFixed(1)} ',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                  ),
                  Text('(${p.reviewCount} reviews)', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price & In Stock Row
          Row(
            children: [
              Text(
                '₹${p.effectivePrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: -0.5),
              ),
              const SizedBox(width: 10),
              if (p.hasDiscount)
                Text(
                  '₹${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, decoration: TextDecoration.lineThrough, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: p.inStock ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.inStock ? 'In Stock (${p.stockQuantity.toStringAsFixed(0)})' : 'Out of Stock',
                  style: TextStyle(
                    color: p.inStock ? const Color(0xFF047857) : const Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Feature Highlights Grid
          Row(
            children: [
              _buildFeatureTile(Icons.verified_outlined, '100% Fresh', 'Guaranteed Quality'),
              const SizedBox(width: 10),
              _buildFeatureTile(Icons.local_shipping_outlined, 'Fast Shipping', 'Delivered in Mins'),
              const SizedBox(width: 10),
              _buildFeatureTile(Icons.security_outlined, 'Safe Payment', 'Protected Checkout'),
            ],
          ),
          const SizedBox(height: 24),

          // Description Section
          const Text('Product Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(
            p.description,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, height: 1.6, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 24),

          // Quantity Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    Text('Select pack size', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const Spacer(),
                _QuantitySelector(
                  quantity: _quantity,
                  onDecrement: () => setState(() { if (_quantity > 1) _quantity--; }),
                  onIncrement: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Reviews Stream Section
          StreamBuilder<List<ReviewModel>>(
            stream: ProductRepository().getReviews(p.id),
            builder: (ctx, snap) {
              final reviews = snap.data ?? [];
              if (reviews.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                      GestureDetector(
                        onTap: () => context.push('/home/product/${p.id}/reviews', extra: p),
                        child: const Text('View All', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOverallRatingSummary(p),
                  const SizedBox(height: 16),
                  ...reviews.take(3).map((r) => _ReviewTile(review: r)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF059669), size: 20),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingSummary(ProductModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            p.rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < p.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text('Overall Customer Rating', style: TextStyle(color: Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductModel p) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset > 0 ? bottomInset + 10 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: p.inStock
                      ? () {
                          for (int i = 0; i < _quantity; i++) {
                            context.read<CartProvider>().addItem(p);
                          }
                          AppSnackBar.show(
                            context,
                            message: '${p.name} added to cart',
                            backgroundColor: const Color(0xFF059669),
                            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF059669), size: 20),
                  label: const Text('Add to Cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF059669), width: 1.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: p.inStock
                      ? () {
                          for (int i = 0; i < _quantity; i++) {
                            context.read<CartProvider>().addItem(p);
                          }
                          context.push('/checkout');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Buy Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QuantitySelector({required this.quantity, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          ),
          _Btn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF059669)),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                backgroundImage: review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty ? NetworkImage(review.userPhotoUrl!) : null,
                child: review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
