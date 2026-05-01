import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/cart_provider.dart';

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
      backgroundColor: AppColors.background,
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
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppColors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: AppColors.white,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 20, color: AppColors.textPrimary),
              onPressed: () => context.push('/cart'),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.white,
          child: p.imageUrls.isEmpty
              ? const Icon(Icons.image_outlined, size: 100, color: AppColors.grey300)
              : PageView.builder(
                  itemCount: p.imageUrls.length,
                  onPageChanged: (i) => setState(() => _selectedImage = i),
                  itemBuilder: (_, i) => Image.network(p.imageUrls[i], fit: BoxFit.contain),
                ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, ProductModel p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image dots
          if (p.imageUrls.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                p.imageUrls.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _selectedImage ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _selectedImage ? AppColors.primary : AppColors.grey300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              if (p.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                  child: Text('${p.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(p.unit, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('₹${p.effectivePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(width: 10),
              if (p.hasDiscount)
                Text('₹${p.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16, decoration: TextDecoration.lineThrough, color: AppColors.grey500)),
            ],
          ),
          const SizedBox(height: 12),
          // Rating
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < p.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 20,
              )),
              const SizedBox(width: 6),
              Text('${p.rating.toStringAsFixed(1)} (${p.reviewCount} reviews)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          // Stock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.inStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.inStock ? '✓ In Stock (${p.stockQuantity.toStringAsFixed(0)} available)' : '✗ Out of Stock',
              style: TextStyle(
                color: p.inStock ? AppColors.success : AppColors.error,
                fontSize: 12, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(p.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 24),
          // Quantity selector
          Row(
            children: [
              const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              _QuantitySelector(
                quantity: _quantity,
                onDecrement: () => setState(() { if (_quantity > 1) _quantity--; }),
                onIncrement: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Reviews Section
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
                      const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('${reviews.length} reviews', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOverallRatingSummary(p),
                  const SizedBox(height: 20),
                  ...reviews.take(3).map((r) => _ReviewTile(review: r)),
                  if (reviews.length > 3)
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/home/product/${p.id}/reviews', extra: p),
                        child: const Text('Read all reviews', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRatingSummary(ProductModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(p.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: List.generate(5, (i) => Icon(
                i < p.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 20,
              ))),
              Text('Overall Rating by Customers', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductModel p) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Add to Cart',
                variant: AppButtonVariant.outlined,
                icon: Icons.shopping_cart_outlined,
                onTap: p.inStock
                    ? () {
                        for (int i = 0; i < _quantity; i++) {
                          context.read<CartProvider>().addItem(p);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p.name} added to cart'), backgroundColor: AppColors.primary),
                        );
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Buy Now',
                onTap: p.inStock
                    ? () {
                        for (int i = 0; i < _quantity; i++) {
                          context.read<CartProvider>().addItem(p);
                        }
                        context.push('/cart');
                      }
                    : null,
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
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Btn(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.primary),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: AppColors.primarySurface,
                backgroundImage: review.userPhotoUrl != null ? NetworkImage(review.userPhotoUrl!) : null,
                child: review.userPhotoUrl == null
                    ? Text(review.userName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))
                    : null),
              const SizedBox(width: 8),
              Expanded(child: Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w600))),
              Row(children: List.generate(5, (i) => Icon(
                i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 14,
              ))),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
