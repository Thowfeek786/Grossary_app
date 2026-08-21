import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('products');

  Stream<List<ProductModel>> getProducts({
    String? categoryId,
    String? dealerId,
    bool activeOnly = true,
    bool featuredOnly = false,
    String? searchQuery,
  }) {
    Query q = _col;
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    if (dealerId != null) q = q.where('dealerId', isEqualTo: dealerId);
    if (featuredOnly) q = q.where('isFeatured', isEqualTo: true);
    
    return q.snapshots().map((s) {
      final list = s.docs.map(ProductModel.fromFirestore).toList();
      // Sort in memory by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<ProductModel>> getProductsOnce() async {
    final snap = await _col.where('isActive', isEqualTo: true).get();
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final snap = await _col.where('isActive', isEqualTo: true).get();
    final allProducts = snap.docs.map(ProductModel.fromFirestore).toList();

    final tokens = cleanQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return [];

    return allProducts.where((p) {
      final name = p.name.toLowerCase();
      final category = p.categoryName.toLowerCase();
      final description = p.description.toLowerCase();
      final tags = p.tags.map((t) => t.toLowerCase()).join(' ');

      return tokens.every((token) =>
          name.contains(token) ||
          category.contains(token) ||
          description.contains(token) ||
          tags.contains(token));
    }).toList();
  }

  Future<String> addProduct(ProductModel product) async {
    final ref = _col.doc();
    final model = product.copyWith();
    await ref.set({...model.toFirestore(), 'id': ref.id, 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _col.doc(product.id).update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> toggleProductActive(String id, bool isActive) async {
    await _col.doc(id).update({'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateStock(String productId, double newQuantity) async {
    await _col.doc(productId).update({
      'stockQuantity': newQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> decrementStock(String productId, double amount) async {
    await _col.doc(productId).update({
      'stockQuantity': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reviews subcollection
  CollectionReference _reviews(String productId) =>
      _col.doc(productId).collection('reviews');

  Stream<List<ReviewModel>> getReviews(String productId) {
    return _reviews(productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReviewModel.fromFirestore).toList());
  }

  Future<void> addReview(ReviewModel review) async {
    final ref = _reviews(review.productId).doc(review.userId);
    final batch = _db.batch();
    
    // Add/Update user review
    batch.set(ref, {...review.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
    
    // Recalculate rating with the new value
    final existingReviews = await _reviews(review.productId).get();
    final reviewsMap = { for (var d in existingReviews.docs) d.id : (d.data() as Map<String, dynamic>)['rating'] as num };
    
    // Update or add the new rating in our map
    reviewsMap[review.userId] = review.rating;
    
    final allRatings = reviewsMap.values.toList();
    final avg = allRatings.reduce((a, b) => a + b) / allRatings.length;
    
    batch.update(_col.doc(review.productId), {
      'rating': avg,
      'reviewCount': allRatings.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }
}
