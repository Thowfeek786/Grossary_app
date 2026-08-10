import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo = OrderRepository();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<OrderModel>> getUserOrders(String userId) =>
      _repo.getOrdersByUser(userId);

  Future<String?> placeOrder(OrderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final id = await _repo.placeOrder(order);
      return id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _repo.cancelOrder(orderId, reason);
  }

  Future<OrderModel?> getOrderById(String id) => _repo.getOrderById(id);
  Stream<OrderModel?> getOrderStream(String id) => _repo.getOrderStream(id);
  Stream<Map<String, dynamic>?> streamDriverLocation(String id) =>
      _repo.streamDriverLocation(id);
}

