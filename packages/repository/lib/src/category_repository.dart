import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class CategoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('categories');

  Stream<List<CategoryModel>> getCategories({bool activeOnly = true}) {
    Query q = _col;
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    
    return q.snapshots().map((s) {
      final list = s.docs.map(CategoryModel.fromFirestore).toList();
      // Sort in memory to avoid needing composite index for where + orderBy
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc);
  }

  Future<String> addCategory(CategoryModel category) async {
    final ref = _col.doc();
    final model = CategoryModel(
      id: ref.id,
      name: category.name,
      imageUrl: category.imageUrl,
      description: category.description,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      createdAt: DateTime.now(),
    );
    await ref.set(model.toFirestore());
    return ref.id;
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _col.doc(category.id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> toggleCategoryActive(String id, bool isActive) async {
    await _col.doc(id).update({'isActive': isActive});
  }
}
