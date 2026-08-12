import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:repository/repository.dart';

class ProductReviewsScreen extends StatelessWidget {
  final ProductModel product;
  const ProductReviewsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reviews for ${product.name}',
          style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: ProductRepository().getReviews(product.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_rounded,
              title: 'No Reviews Yet',
              subtitle: 'Be the first one to rate and review this product!',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: reviews.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeader();
              return _ReviewTile(review: reviews[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < product.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on ${product.reviewCount} customer reviews',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                backgroundImage: review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty ? NetworkImage(review.userPhotoUrl!) : null,
                child: review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669), fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827))),
                    Text(AppHelpers.formatDateTime(review.createdAt), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(color: Color(0xFF4B5563), height: 1.5, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
