import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/auth_provider.dart';

class ReviewScreen extends StatefulWidget {
  final CartItemModel item;
  const ReviewScreen({super.key, required this.item});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Write a Review',
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.item.imageUrl != null
                  ? Image.network(widget.item.imageUrl!, width: 120, height: 120, fit: BoxFit.cover)
                  : Container(width: 120, height: 120, color: AppColors.grey100, child: const Icon(Icons.image_outlined, size: 40, color: AppColors.grey400)),
            ),
            const SizedBox(height: 16),
            Text(widget.item.productName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('How was your experience with this product?', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1.0),
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 44,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text('${_rating.toInt()} Stars', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.amber)),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about the product quality, delivery, etc...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.grey200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.grey200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 48),
            AppButton(
              label: 'Submit Review',
              isLoading: _isLoading,
              onTap: _submitReview,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a comment')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user!;
      final review = ReviewModel(
        id: '',
        productId: widget.item.productId,
        userId: user.id,
        userName: user.name,
        userPhotoUrl: user.photoUrl,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ProductRepository().addReview(review);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted! Thank you.'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
