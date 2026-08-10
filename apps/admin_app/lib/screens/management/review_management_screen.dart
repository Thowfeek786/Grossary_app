import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  final _reviewRepo = ReviewRepository();
  double? _filterRating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Review Moderation'),
      body: Column(
        children: [
          // Rating filter bar
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<ReviewModel>>(
              stream: _reviewRepo.getAllReviews(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                var reviews = snap.data ?? [];
                if (_filterRating != null) {
                  reviews = reviews.where((r) => r.rating == _filterRating).toList();
                }

                if (reviews.isEmpty) {
                  return const EmptyState(
                    icon: Icons.rate_review_outlined,
                    title: 'No Reviews Found',
                    subtitle: 'Customer reviews will appear here for moderation.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final r = reviews[i];
                    return _ReviewCard(
                      review: r,
                      onDelete: () => _confirmDelete(r),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All Ratings', null),
            ...[5.0, 4.0, 3.0, 2.0, 1.0].map((rating) => _filterChip('★ ${rating.toInt()}', rating)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, double? rating) {
    final selected = _filterRating == rating;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textPrimary)),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.grey100,
        onSelected: (val) => setState(() => _filterRating = val ? rating : null),
      ),
    );
  }

  void _confirmDelete(ReviewModel review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Remove this review from the platform?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _reviewRepo.deleteReview(review.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Review removed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onDelete;

  const _ReviewCard({required this.review, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySurface,
                child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(_formatDate(review.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (starI) {
                  return Icon(
                    starI < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Moderate Review',
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${review.comment}"',
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
