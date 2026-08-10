import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PaymentGateway { razorpay, stripe, cod, wallet }

class PaymentTransaction {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentGateway gateway;
  final String status; // 'pending', 'success', 'failed', 'refunded'
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.gateway,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
        'gateway': gateway.name,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class PaymentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _paymentsCol => _db.collection('payments');

  Future<PaymentTransaction> createPaymentIntent({
    required String orderId,
    required double amount,
    required PaymentGateway gateway,
    String currency = 'INR',
  }) async {
    final docRef = _paymentsCol.doc();
    final transaction = PaymentTransaction(
      id: docRef.id,
      orderId: orderId,
      amount: amount,
      currency: currency,
      gateway: gateway,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(transaction.toMap());
    return transaction;
  }

  Future<bool> verifyAndCompletePayment({
    required String paymentId,
    required String orderId,
    required String transactionId,
    required PaymentGateway gateway,
  }) async {
    try {
      final paymentRef = _paymentsCol.doc(paymentId);
      final orderRef = _db.collection('orders').doc(orderId);

      await _db.runTransaction((tx) async {
        tx.update(paymentRef, {
          'status': 'success',
          'transactionId': transactionId,
          'completedAt': FieldValue.serverTimestamp(),
        });
        tx.update(orderRef, {
          'isPaid': true,
          'paymentId': paymentId,
          'paymentGateway': gateway.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('Error completing payment: $e');
      return false;
    }
  }

  Future<bool> processRefund({
    required String orderId,
    required double amount,
    required String reason,
  }) async {
    try {
      final refundRef = _db.collection('refunds').doc();
      await refundRef.set({
        'id': refundRef.id,
        'orderId': orderId,
        'amount': amount,
        'reason': reason,
        'status': 'processed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      return false;
    }
  }
}
