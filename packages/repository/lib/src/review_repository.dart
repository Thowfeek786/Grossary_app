import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('reviews');

  /// Get all reviews for admin moderation
  Stream<List<ReviewModel>> getAllReviews() {
    return _col.snapshots().map((s) {
      final list = s.docs.map(ReviewModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Get reviews for a specific product
  Stream<List<ReviewModel>> getReviewsByProduct(String productId) {
    return _col
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ReviewModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Add review
  Future<void> addReview(ReviewModel review) async {
    final docRef = _col.doc();
    await docRef.set(review.toFirestore());
  }

  /// Delete review (Admin moderation)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _col.doc(reviewId).delete();
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }
}
