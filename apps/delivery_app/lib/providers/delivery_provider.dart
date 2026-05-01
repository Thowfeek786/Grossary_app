import 'package:flutter/material.dart';
import 'package:repository/repository.dart';
import 'package:models/models.dart';

class DeliveryProvider extends ChangeNotifier {
  final _orderRepo = OrderRepository();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  Stream<List<OrderModel>> getNewRequests() {
    return _orderRepo.getPendingOrdersForDelivery();
  }

  Stream<List<OrderModel>> getActiveDeliveries(String partnerId) {
    return _orderRepo.getOrdersByDeliveryPartner(partnerId);
  }

  Stream<List<OrderModel>> getDeliveryHistory(String partnerId) {
    return _orderRepo.getOrdersByDeliveryPartner(partnerId).map(
      (orders) => orders.where((o) => o.status == OrderStatus.delivered).toList(),
    );
  }

  Future<void> acceptDelivery({
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
    } finally {
      setLoading(false);
    }
  }

  Future<void> completeDelivery(String orderId, String partnerId, double amount) async {
    try {
      setLoading(true);
      // 1. Update order status to Delivered
      await _orderRepo.updateOrderStatus(orderId, OrderStatus.delivered);
      // 2. Increment partner lifetime stats in Database
      await UserRepository().updatePartnerStats(partnerId, deliveries: 1, earnings: amount);
    } finally {
      setLoading(false);
    }
  }

  Future<void> markPickedUp(String orderId) async {
    try {
      setLoading(true);
      await _orderRepo.updateOrderStatus(orderId, OrderStatus.outForDelivery);
    } finally {
      setLoading(false);
    }
  }

  Future<void> updatePaymentStatus(String orderId, bool isPaid) async {
    try {
      setLoading(true);
      await _orderRepo.updatePaymentStatus(orderId, isPaid);
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }
}
