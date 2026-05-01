import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();
  final CategoryRepository _catRepo = CategoryRepository();

  List<ProductModel> _featured = [];
  List<ProductModel> _allProducts = [];
  List<CategoryModel> _categories = [];
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  List<ProductModel> get featured => _featured;
  List<ProductModel> get allProducts => _allProducts;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get error => _error;

  Stream<List<ProductModel>> getProducts({String? categoryId}) =>
      _repo.getProducts(categoryId: categoryId);

  Stream<List<CategoryModel>> getCategories() => _catRepo.getCategories();

  Stream<List<ProductModel>> getFeatured() =>
      _repo.getProducts(featuredOnly: true);

  Future<void> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      final all = await _repo.getProductsOnce();
      _searchResults = all.where((p) => 
        p.name.toLowerCase().contains(q) || 
        p.categoryName.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q)
      ).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> getProductById(String id) => _repo.getProductById(id);
}
