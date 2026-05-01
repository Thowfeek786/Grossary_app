import 'package:flutter/material.dart';
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
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'Reviews for ${product.name}'),
      body: StreamBuilder<List<ReviewModel>>(
        stream: ProductRepository().getReviews(product.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final reviews = snapshot.data ?? [];
          
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No Reviews Yet',
              subtitle: 'Be the first one to rate this product!',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: reviews.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: List.generate(5, (i) => Icon(
                    i < product.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber, size: 24,
                  ))),
                  Text('Based on ${product.reviewCount} reviews', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: AppColors.primarySurface,
                backgroundImage: review.userPhotoUrl != null ? NetworkImage(review.userPhotoUrl!) : null,
                child: review.userPhotoUrl == null ? Text(review.userName[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)) : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(AppHelpers.formatDateTime(review.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Row(children: List.generate(5, (i) => Icon(
                i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 14,
              ))),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13)),
        ],
      ),
    );
  }
}
