import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class OrderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('orders');

  Future<String> placeOrder(OrderModel order) async {
    // 0. Idempotency Protection against duplicate checkouts
    if (order.idempotencyKey != null && order.idempotencyKey!.trim().isNotEmpty) {
      final existing = await _col
          .where('userId', isEqualTo: order.userId)
          .where('idempotencyKey', isEqualTo: order.idempotencyKey!.trim())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }
    }

    final orderRef = _col.doc();
    final String generatedOtp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

    await _db.runTransaction((transaction) async {
      // 1. Check & Decrement Stock atomically
      for (final item in order.items) {
        final productRef = _db.collection('products').doc(item.productId);
        final productDoc = await transaction.get(productRef);
        
        if (productDoc.exists) {
          final currentStock = (productDoc.data()?['stockQuantity'] as num?)?.toDouble() ?? 0.0;
          if (currentStock < item.quantity) {
            throw Exception('Insufficient stock for ${item.productName}. Please adjust quantity.');
          }
          transaction.update(productRef, {
            'stockQuantity': currentStock - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // 2. Save Order with OTP
      final orderData = order.toFirestore();
      if (orderData['deliveryOtp'] == null || (orderData['deliveryOtp'] as String).isEmpty) {
        orderData['deliveryOtp'] = generatedOtp;
      }

      transaction.set(orderRef, {
        ...orderData,
        'id': orderRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    
    return orderRef.id;
  }


  Stream<List<OrderModel>> getOrdersByUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<OrderModel>> getAllOrders({OrderStatus? status}) {
    Query q = _col;
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) {
      final list = s.docs.map(OrderModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OrderModel>> getOrdersByDealer(String dealerId) {
    return _col
        .where('dealerId', isEqualTo: dealerId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<OrderModel>> getOrdersByDeliveryPartner(String partnerId) {
    return _col
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<OrderModel>> getPendingOrdersForDelivery() {
    return _col
        .where('status', isEqualTo: OrderStatus.accepted.name)
        .where('deliveryPartnerId', isNull: true)
        .snapshots()
        .map((s) {
          final list = s.docs.map(OrderModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  Stream<OrderModel?> getOrderStream(String id) {
    return _col.doc(id).snapshots().map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final Map<String, dynamic> update = {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == OrderStatus.delivered) {
      update['deliveredAt'] = FieldValue.serverTimestamp();
    }
    await _col.doc(orderId).update(update);
  }

  Future<void> assignDeliveryPartner({
    required String orderId,
    required String partnerId,
    required String partnerName,
    required String partnerPhone,
  }) async {
    await _col.doc(orderId).update({
      'deliveryPartnerId': partnerId,
      'deliveryPartnerName': partnerName,
      'deliveryPartnerPhone': partnerPhone,
      'status': OrderStatus.shipped.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      final doc = await _col.doc(orderId).get();
      if (!doc.exists) return;
      final order = OrderModel.fromFirestore(doc);

      await _db.runTransaction((transaction) async {
        // 1. Restock Product Quantities
        for (final item in order.items) {
          final productRef = _db.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);
          if (productDoc.exists) {
            final currentStock =
                (productDoc.data()?['stockQuantity'] as num?)?.toDouble() ?? 0.0;
            transaction.update(productRef, {
              'stockQuantity': currentStock + item.quantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // 2. Auto-Refund to Customer Wallet if order was paid or paid via wallet
        if (order.isPaid || order.paymentMethod == 'GroceryGo Wallet') {
          final walletRef = _db.collection('wallets').doc(order.userId);
          transaction.set(
            walletRef,
            {
              'balance': FieldValue.increment(order.total),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          final historyRef = walletRef.collection('history').doc();
          transaction.set(historyRef, {
            'id': historyRef.id,
            'amount': order.total,
            'type': 'credit',
            'description':
                'Refund for Cancelled Order #${order.id.substring(0, order.id.length > 6 ? 6 : order.id.length).toUpperCase()}',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Mark Order Status & Payment Status as Cancelled / Refunded
        transaction.update(_col.doc(orderId), {
          'status': OrderStatus.cancelled.name,
          'cancellationReason': reason,
          'paymentStatus': (order.isPaid || order.paymentMethod == 'GroceryGo Wallet')
              ? 'refunded'
              : 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error cancelling order: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final allOrders = await _col.get();
    final todayOrders = await _col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    final monthOrders = await _col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    double totalRevenue = 0;
    double todayRevenue = 0;
    double monthRevenue = 0;

    for (final doc in allOrders.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == OrderStatus.delivered.name) {
        totalRevenue += (data['total'] as num?)?.toDouble() ?? 0;
      }
    }
    for (final doc in todayOrders.docs) {
      final data = doc.data() as Map<String, dynamic>;
      todayRevenue += (data['total'] as num?)?.toDouble() ?? 0;
    }
    for (final doc in monthOrders.docs) {
      final data = doc.data() as Map<String, dynamic>;
      monthRevenue += (data['total'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalOrders': allOrders.size,
      'todayOrders': todayOrders.size,
      'monthOrders': monthOrders.size,
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'monthRevenue': monthRevenue,
    };
  }

  Future<void> updatePaymentStatus(String orderId, bool isPaid) async {
    await _col.doc(orderId).update({
      'isPaid': isPaid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDriverLocation({
    required String orderId,
    required double latitude,
    required double longitude,
    double? heading,
  }) async {
    await _col.doc(orderId).update({
      'driverLocation': {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>?> streamDriverLocation(String orderId) {
    return _col.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['driverLocation'] as Map<String, dynamic>?;
    });
  }

  Future<bool> verifyDeliveryOtp({
    required String orderId,
    required String inputOtp,
  }) async {
    final doc = await _col.doc(orderId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    final expectedOtp = data['deliveryOtp'] as String?;

    final cleanInput = inputOtp.trim();
    if (expectedOtp == null || expectedOtp.isEmpty || expectedOtp == cleanInput) {
      await updateOrderStatus(orderId, OrderStatus.delivered);
      return true;
    }
    return false;
  }

}

