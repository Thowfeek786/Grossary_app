import 'dart:async';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';

class DealerOrderAlertService with ChangeNotifier {
  static final DealerOrderAlertService _instance = DealerOrderAlertService._internal();
  factory DealerOrderAlertService() => _instance;
  DealerOrderAlertService._internal();

  final OrderRepository _orderRepo = OrderRepository();
  final AudioService _audioService = AudioService();

  StreamSubscription<List<OrderModel>>? _ordersSub;
  final Set<String> _knownOrderIds = {};
  bool _isInitialized = false;

  OrderModel? _currentAlertOrder;
  OrderModel? get currentAlertOrder => _currentAlertOrder;

  bool _isRinging = false;
  bool get isRinging => _isRinging;

  void startListening(String dealerId) {
    if (dealerId.isEmpty) return;
    _ordersSub?.cancel();
    _knownOrderIds.clear();
    _isInitialized = false;

    debugPrint('🎧 [DealerOrderAlertService] Starting real-time order listener for dealer: $dealerId');

    _ordersSub = _orderRepo.getOrdersByDealer(dealerId).listen((orders) {
      if (!_isInitialized) {
        // Populate initial existing order IDs so we don't alarm on app launch
        for (final o in orders) {
          _knownOrderIds.add(o.id);
        }
        _isInitialized = true;
        return;
      }

      // Check for incoming new pending orders
      for (final order in orders) {
        if (!_knownOrderIds.contains(order.id)) {
          _knownOrderIds.add(order.id);

          if (order.status == OrderStatus.pending) {
            _triggerNewOrderAlarm(order);
            break;
          }
        }
      }
    }, onError: (e) {
      debugPrint('⚠️ [DealerOrderAlertService] Stream error: $e');
    });
  }

  void _triggerNewOrderAlarm(OrderModel order) {
    _currentAlertOrder = order;
    _isRinging = true;
    notifyListeners();

    // 1. Play looping audio chime
    _audioService.playNewOrderAlert(loop: true);

    // 2. Trigger high-priority out-of-app background notification
    final orderCode = order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase();
    final customer = order.userName.isNotEmpty ? order.userName : 'Shopper';

    NotificationService.showLocalNotification(
      title: '🔔 NEW ORDER RECEIVED! #$orderCode',
      body: '$customer placed an order for ₹${order.total.toStringAsFixed(0)} (${order.itemCount} items). Tap to accept!',
      payload: '/orders',
    );
  }

  /// Stops ringing and clears the active alert
  void dismissAlert() {
    _audioService.stop();
    _isRinging = false;
    _currentAlertOrder = null;
    notifyListeners();
  }

  /// Accept order and stop alarm
  Future<void> acceptAndPack(OrderModel order) async {
    dismissAlert();
    await _orderRepo.updateOrderStatus(order.id, OrderStatus.processing);
  }

  /// Reject order and stop alarm
  Future<void> rejectOrder(OrderModel order, {String reason = 'Store busy / Out of stock'}) async {
    dismissAlert();
    await _orderRepo.updateOrderStatus(order.id, OrderStatus.cancelled);
  }

  void stopListening() {
    _ordersSub?.cancel();
    _ordersSub = null;
    dismissAlert();
    _knownOrderIds.clear();
    _isInitialized = false;
  }
}
