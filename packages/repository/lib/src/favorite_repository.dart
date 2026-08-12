import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'product_repository.dart';

class FavoriteRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _favCol(String userId) =>
      _db.collection('users').doc(userId).collection('favorites');

  // Stream list of favorite product IDs for a user
  Stream<List<String>> getFavoriteProductIds(String userId) {
    return _favCol(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Stream products favorited by a user
  Stream<List<ProductModel>> getFavoriteProducts(String userId) {
    return getFavoriteProductIds(userId).asyncMap((favIds) async {
      if (favIds.isEmpty) return <ProductModel>[];

      final products = <ProductModel>[];
      final productRepo = ProductRepository();
      for (final id in favIds) {
        final p = await productRepo.getProductById(id);
        if (p != null) {
          products.add(p);
        }
      }
      return products;
    });
  }

  // Check if a product is favorited
  Stream<bool> isFavorite(String userId, String productId) {
    return _favCol(userId).doc(productId).snapshots().map((doc) => doc.exists);
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String userId, String productId) async {
    try {
      final docRef = _favCol(userId).doc(productId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        return false; // Now unfavorited
      } else {
        await docRef.set({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        return true; // Now favorited
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }
}
