import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PaymentGateway { razorpay, stripe, cod, wallet, upi }

class PaymentTransaction {
  final String id;
  final String orderId;
  final String? userId;
  final String? userName;
  final double amount;
  final double walletAmountUsed;
  final String currency;
  final PaymentGateway gateway;
  final String status; // 'pending', 'success', 'failed', 'refunded'
  final String? transactionId;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    this.userId,
    this.userName,
    required this.amount,
    this.walletAmountUsed = 0.0,
    required this.currency,
    required this.gateway,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  factory PaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaymentTransaction(
      id: doc.id,
      orderId: d['orderId'] ?? '',
      userId: d['userId'],
      userName: d['userName'],
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      walletAmountUsed: (d['walletAmountUsed'] as num?)?.toDouble() ?? 0.0,
      currency: d['currency'] ?? 'INR',
      gateway: PaymentGateway.values.firstWhere(
        (g) => g.name == (d['gateway'] ?? 'cod'),
        orElse: () => PaymentGateway.cod,
      ),
      status: d['status'] ?? 'pending',
      transactionId: d['transactionId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'userId': userId,
        'userName': userName,
        'amount': amount,
        'walletAmountUsed': walletAmountUsed,
        'currency': currency,
        'gateway': gateway.name,
        'status': status,
        'transactionId': transactionId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AdminPaymentSettings {
  final String upiId;
  final String merchantName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final bool enableCod;
  final bool enableUpi;
  final bool enableWallet;

  const AdminPaymentSettings({
    this.upiId = 'sthowfeek65@okaxis',
    this.merchantName = 'GroceryGo Official Store',
    this.bankName = 'HDFC Bank',
    this.accountNumber = '998877665544',
    this.ifscCode = 'HDFC0001234',
    this.enableCod = true,
    this.enableUpi = true,
    this.enableWallet = true,
  });

  factory AdminPaymentSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const AdminPaymentSettings();
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AdminPaymentSettings(
      upiId: (d['upiId'] ?? d['adminUpiId'])?.toString() ?? 'sthowfeek65@okaxis',
      merchantName: (d['merchantName'] ?? d['adminPayeeName'])?.toString() ?? 'GroceryGo Official Store',
      bankName: (d['bankName'] ?? d['adminBankName'])?.toString() ?? 'HDFC Bank',
      accountNumber: (d['accountNumber'] ?? d['adminAccountNumber'])?.toString() ?? '998877665544',
      ifscCode: (d['ifscCode'] ?? d['adminIfscCode'])?.toString() ?? 'HDFC0001234',
      enableCod: d['enableCod'] ?? d['isCodEnabled'] ?? true,
      enableUpi: d['enableUpi'] ?? d['isOnlinePaymentEnabled'] ?? true,
      enableWallet: d['enableWallet'] ?? d['isWalletEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'upiId': upiId,
        'adminUpiId': upiId,
        'merchantName': merchantName,
        'adminPayeeName': merchantName,
        'bankName': bankName,
        'adminBankName': bankName,
        'accountNumber': accountNumber,
        'adminAccountNumber': accountNumber,
        'ifscCode': ifscCode,
        'adminIfscCode': ifscCode,
        'enableCod': enableCod,
        'isCodEnabled': enableCod,
        'enableUpi': enableUpi,
        'isOnlinePaymentEnabled': enableUpi,
        'enableWallet': enableWallet,
        'isWalletEnabled': enableWallet,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class PaymentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _paymentsCol => _db.collection('payments');
  DocumentReference get _globalSettingsDoc =>
      _db.collection('store_settings').doc('global');
  DocumentReference get _configSettingsDoc =>
      _db.collection('store_settings').doc('payment_config');

  Stream<List<PaymentTransaction>> streamAllTransactions() {
    return _paymentsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PaymentTransaction.fromFirestore).toList());
  }

  Future<AdminPaymentSettings> getPaymentSettings() async {
    try {
      final snap = await _configSettingsDoc.get();
      if (snap.exists) return AdminPaymentSettings.fromFirestore(snap);
      final globalSnap = await _globalSettingsDoc.get();
      if (globalSnap.exists) return AdminPaymentSettings.fromFirestore(globalSnap);
    } catch (e) {
      debugPrint('Error getting payment settings: $e');
    }
    return const AdminPaymentSettings();
  }

  Stream<AdminPaymentSettings> streamPaymentSettings() {
    return _configSettingsDoc.snapshots().map((snap) {
      if (snap.exists) return AdminPaymentSettings.fromFirestore(snap);
      return const AdminPaymentSettings();
    });
  }

  Future<void> updatePaymentSettings(AdminPaymentSettings settings) async {
    final batch = _db.batch();
    batch.set(_globalSettingsDoc, settings.toFirestore(), SetOptions(merge: true));
    batch.set(_configSettingsDoc, settings.toFirestore(), SetOptions(merge: true));
    await batch.commit();
  }

  Future<PaymentTransaction> createPaymentIntent({
    required String orderId,
    String? userId,
    String? userName,
    required double amount,
    double walletAmountUsed = 0.0,
    required PaymentGateway gateway,
    String currency = 'INR',
  }) async {
    final docRef = _paymentsCol.doc();
    final transaction = PaymentTransaction(
      id: docRef.id,
      orderId: orderId,
      userId: userId,
      userName: userName,
      amount: amount,
      walletAmountUsed: walletAmountUsed,
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

  /// Admin refund directly to user wallet
  Future<bool> refundToUserWallet({
    required String transactionId,
    required String userId,
    required String orderId,
    required double amount,
    required String reason,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Update payment status to refunded
      if (transactionId.isNotEmpty) {
        batch.update(_paymentsCol.doc(transactionId), {
          'status': 'refunded',
          'refundedAt': FieldValue.serverTimestamp(),
          'refundReason': reason,
        });
      }

      // 2. Add refund credit to user wallet
      final walletRef = _db.collection('wallets').doc(userId);
      batch.set(
        walletRef,
        {
          'balance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Add wallet history entry
      final historyRef = walletRef.collection('history').doc();
      batch.set(historyRef, {
        'id': historyRef.id,
        'amount': amount,
        'type': 'credit',
        'description': 'Refund for Order #$orderId: $reason',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error refunding to wallet: $e');
      return false;
    }
  }
}
