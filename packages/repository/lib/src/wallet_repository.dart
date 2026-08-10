import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class WalletRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _walletsCol => _db.collection('wallets');

  Stream<WalletModel> streamWallet(String userId) {
    return _walletsCol.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return WalletModel(
          userId: userId,
          balance: 0.0,
          transactions: [],
          updatedAt: DateTime.now(),
        );
      }
      return WalletModel.fromFirestore(doc);
    });
  }

  Stream<WalletModel> getWallet(String userId) => streamWallet(userId);

  Stream<List<WalletTransaction>> getTransactions(String userId) {
    return streamWallet(userId).map((w) => w.transactions);
  }

  Future<bool> addFunds({
    required String userId,
    required double amount,
    required String description,
    String? orderId,
    TransactionType type = TransactionType.credit,
  }) async {
    try {
      final docRef = _walletsCol.doc(userId);
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        type: type,
        description: description,
        orderId: orderId,
        createdAt: DateTime.now(),
      );

      await _db.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        double currentBalance = 0.0;
        List<dynamic> existingTx = [];

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
          existingTx = data['transactions'] as List<dynamic>? ?? [];
        }

        final newBalance = currentBalance + amount;
        existingTx.insert(0, transaction.toMap());

        tx.set(
          docRef,
          {
            'balance': newBalance,
            'transactions': existingTx,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
      return true;
    } catch (e) {
      debugPrint('Error adding funds: $e');
      return false;
    }
  }

  Future<bool> deductBalance({
    required String userId,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    try {
      final docRef = _walletsCol.doc(userId);
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        type: TransactionType.debit,
        description: description,
        orderId: orderId,
        createdAt: DateTime.now(),
      );

      await _db.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        if (!doc.exists) throw Exception('Wallet does not exist');

        final data = doc.data() as Map<String, dynamic>;
        final currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        if (currentBalance < amount) throw Exception('Insufficient wallet balance');

        final existingTx = data['transactions'] as List<dynamic>? ?? [];
        existingTx.insert(0, transaction.toMap());

        tx.update(docRef, {
          'balance': currentBalance - amount,
          'transactions': existingTx,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('Error deducting balance: $e');
      return false;
    }
  }
}
