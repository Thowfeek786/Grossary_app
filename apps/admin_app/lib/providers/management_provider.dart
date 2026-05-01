import 'package:flutter/material.dart';
import 'package:repository/repository.dart';
import 'package:models/models.dart';

class AdminManagementProvider extends ChangeNotifier {
  final _productRepo = ProductRepository();
  final _categoryRepo = CategoryRepository();
  final _orderRepo = OrderRepository();
  final _userRepo = UserRepository();
  final _bannerRepo = BannerRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Common error handling
  String? _error;
  String? get error => _error;

  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  // Dashboard Stats — fetched from Firestore
  Future<Map<String, String>> getDashboardStats() async {
    try {
      final stats = await _orderRepo.getDashboardStats();
      final userCount = await _userRepo.getAllUsers().first.then((u) => u.length);
      final productCount = await _productRepo.getProducts(activeOnly: false).first.then((p) => p.length);
      final revenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      final activeOrders = (stats['todayOrders'] as num?)?.toInt() ?? 0;
      return {
        'Total Users': userCount.toString(),
        'Active Orders': activeOrders.toString(),
        'Total Revenue': '₹${(revenue / 1000).toStringAsFixed(1)}K',
        'Products': productCount.toString(),
      };
    } catch (e) {
      return {
        'Total Users': '-',
        'Active Orders': '-',
        'Total Revenue': '-',
        'Products': '-',
      };
    }
  }

  // Stream methods for real-time lists
  Stream<List<ProductModel>> getProducts() => _productRepo.getProducts(activeOnly: false);
  Stream<List<CategoryModel>> getCategories() => _categoryRepo.getCategories();
  Stream<List<OrderModel>> getOrders({OrderStatus? status}) => _orderRepo.getAllOrders(status: status);
  Stream<List<UserModel>> getUsers() => _userRepo.getAllUsers();
  Stream<List<BannerModel>> getBanners() => _bannerRepo.getBanners();

  // Management methods
  Future<void> toggleProductStatus(String id, bool isActive) async {
    try {
      await _productRepo.toggleProductActive(id, isActive);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _orderRepo.updateOrderStatus(orderId, status);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> assignDeliveryPartner({
    required String orderId,
    required String partnerId,
    required String partnerName,
    required String partnerPhone,
  }) async {
    try {
      setLoading(true);
      await _orderRepo.assignDeliveryPartner(
        orderId: orderId,
        partnerId: partnerId,
        partnerName: partnerName,
        partnerPhone: partnerPhone,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getRealDashboardStats() async {
    try {
      return await _orderRepo.getDashboardStats();
    } catch (e) {
      setError(e.toString());
      return {};
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _categoryRepo.deleteCategory(id);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _bannerRepo.deleteBanner(id);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<bool> addCategory(CategoryModel category) async {
    try {
      setLoading(true);
      await _categoryRepo.addCategory(category);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      setLoading(true);
      await _categoryRepo.updateCategory(category);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> addBanner(BannerModel banner) async {
    try {
      setLoading(true);
      await _bannerRepo.addBanner(banner);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateBanner(BannerModel banner) async {
    try {
      setLoading(true);
      await _bannerRepo.updateBanner(banner);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      setLoading(true);
      await _userRepo.updateUserRole(userId, role);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      setLoading(true);
      await _productRepo.addProduct(product);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      setLoading(true);
      await _productRepo.updateProduct(product);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productRepo.deleteProduct(id);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> setUserApproval(String userId, bool approved) async {
    try {
      setLoading(true);
      await _userRepo.setUserApproval(userId, approved);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> setUserActive(String userId, bool active) async {
    try {
      setLoading(true);
      await _userRepo.setUserActive(userId, active);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  Future<bool> addUser(UserModel user) async {
    try {
      setLoading(true);
      await _userRepo.createUser(user);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }
}
