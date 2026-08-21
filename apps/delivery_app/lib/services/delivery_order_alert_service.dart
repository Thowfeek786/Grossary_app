import 'dart:async';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';

class DeliveryOrderAlertService with ChangeNotifier {
  static final DeliveryOrderAlertService _instance = DeliveryOrderAlertService._internal();
  factory DeliveryOrderAlertService() => _instance;
  DeliveryOrderAlertService._internal();

  final OrderRepository _orderRepo = OrderRepository();
  final AudioService _audioService = AudioService();

  StreamSubscription<List<OrderModel>>? _availableOrdersSub;
  final Set<String> _knownOrderIds = {};
  bool _isInitialized = false;
  String? _currentPartnerId;

  OrderModel? _currentAlertOrder;
  OrderModel? get currentAlertOrder => _currentAlertOrder;

  bool _isAlerting = false;
  bool get isAlerting => _isAlerting;

  void startListening(String partnerId) {
    if (partnerId.isEmpty) return;
    if (_currentPartnerId == partnerId && _availableOrdersSub != null) return;
    _currentPartnerId = partnerId;

    _availableOrdersSub?.cancel();
    _knownOrderIds.clear();
    _isInitialized = false;

    debugPrint('🛵 [DeliveryOrderAlertService] Listening for pending delivery orders for partner: $partnerId');

    _availableOrdersSub = _orderRepo.getPendingOrdersForDelivery().listen((orders) {
      if (!_isInitialized) {
        for (final o in orders) {
          _knownOrderIds.add(o.id);
        }
        _isInitialized = true;
        return;
      }

      for (final order in orders) {
        if (!_knownOrderIds.contains(order.id)) {
          _knownOrderIds.add(order.id);

          if (order.status == OrderStatus.accepted || order.status == OrderStatus.processing) {
            _triggerDeliveryAlert(order);
            break;
          }
        }
      }
    }, onError: (e) {
      debugPrint('⚠️ [DeliveryOrderAlertService] Error: $e');
    });
  }

  void _triggerDeliveryAlert(OrderModel order) {
    _currentAlertOrder = order;
    _isAlerting = true;
    notifyListeners();

    // 1. Play delivery pickup request chime
    _audioService.playDeliveryRequestAlert();

    // 2. High priority notification
    final orderCode = order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase();
    NotificationService.showLocalNotification(
      title: '🛵 NEW DELIVERY READY! #$orderCode',
      body: 'Order #$orderCode (₹${order.total.toStringAsFixed(0)}) is packed and ready for pickup!',
      payload: '/home',
    );
  }

  void dismissAlert() {
    _audioService.stop();
    _isAlerting = false;
    _currentAlertOrder = null;
    notifyListeners();
  }

  Future<void> acceptDelivery(OrderModel order, String partnerId, String partnerName, String partnerPhone) async {
    dismissAlert();
    await _orderRepo.assignDeliveryPartner(
      orderId: order.id,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
    );
  }

  void stopListening() {
    _currentPartnerId = null;
    _availableOrdersSub?.cancel();
    _availableOrdersSub = null;
    dismissAlert();
    _knownOrderIds.clear();
    _isInitialized = false;
  }
}
