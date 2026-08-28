import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';
import 'wallet_repository.dart';

class WaterCanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletRepository _walletRepo = WalletRepository();

  CollectionReference get _canTransactions =>
      _firestore.collection('can_transactions');
  CollectionReference get _orders => _firestore.collection('orders');
  CollectionReference get _users => _firestore.collection('users');
  DocumentReference get _configDoc =>
      _firestore.collection('platform_settings').doc('water_can_config');

  // ─────────────────────────────────────────────
  // Customer Methods
  // ─────────────────────────────────────────────

  /// Stream user's can summary (delivered, collected, active balance, deposit held)
  Stream<UserCanSummaryModel> getUserCanSummary(String userId) {
    return _canTransactions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          int fullDelivered = 0;
          int emptyCollected = 0;
          double depositHeld = 0.0;

          for (final doc in snapshot.docs) {
            final tx = CanTransactionModel.fromFirestore(doc);
            fullDelivered += tx.fullDelivered;
            emptyCollected += tx.emptyCollected;
            depositHeld += tx.depositAmount;
          }

          final balance = fullDelivered - emptyCollected;

          return UserCanSummaryModel(
            userId: userId,
            fullDelivered: fullDelivered,
            emptyCollected: emptyCollected,
            canBalance: balance > 0 ? balance : 0,
            totalDepositHeld: depositHeld,
          );
        })
        .handleError((_) => UserCanSummaryModel(
              userId: userId,
              fullDelivered: 0,
              emptyCollected: 0,
              canBalance: 0,
              totalDepositHeld: 0.0,
            ));
  }

  /// Stream user's can transaction ledger history
  Stream<List<CanTransactionModel>> getUserCanLedger(String userId) {
    return _canTransactions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => CanTransactionModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((_) => <CanTransactionModel>[]);
  }

  // ─────────────────────────────────────────────
  // Vendor / Dealer Methods
  // ─────────────────────────────────────────────

  /// Stream dealer water products (refill, new can, 1L, pack of 6)
  Stream<List<ProductModel>> getDealerWaterProducts(String dealerId) {
    return _firestore
        .collection('products')
        .where('dealerId', isEqualTo: dealerId)
        .where('categoryId', isEqualTo: 'water_cans')
        .snapshots()
        .map((s) => s.docs.map(ProductModel.fromFirestore).toList())
        .handleError((_) => <ProductModel>[]);
  }

  /// Stream all approved dealers who offer water cans / beverages
  Stream<List<UserModel>> getAvailableWaterDealers() {
    return _users
        .where('role', isEqualTo: UserRole.dealer.name)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList())
        .handleError((_) => <UserModel>[]);
  }

  /// Stream dealer can return summary
  Stream<Map<String, dynamic>> getDealerCanSummary(String dealerId) {
    return _canTransactions
        .where('dealerId', isEqualTo: dealerId)
        .snapshots()
        .map((snapshot) {
          int totalDelivered = 0;
          int totalCollected = 0;
          int todayDelivered = 0;
          int todayCollected = 0;
          final Set<String> activeCustomers = {};

          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);

          for (final doc in snapshot.docs) {
            final tx = CanTransactionModel.fromFirestore(doc);
            totalDelivered += tx.fullDelivered;
            totalCollected += tx.emptyCollected;

            if (tx.fullDelivered > tx.emptyCollected) {
              activeCustomers.add(tx.userId);
            }

            if (tx.createdAt.isAfter(startOfToday)) {
              todayDelivered += tx.fullDelivered;
              todayCollected += tx.emptyCollected;
            }
          }

          final canBalance = totalDelivered - totalCollected;

          return {
            'totalDelivered': totalDelivered,
            'totalCollected': totalCollected,
            'todayDelivered': todayDelivered,
            'todayCollected': todayCollected,
            'canBalance': canBalance > 0 ? canBalance : 0,
            'activeCustomersCount': activeCustomers.length,
          };
        })
        .handleError((_) => {
              'totalDelivered': 0,
              'totalCollected': 0,
              'todayDelivered': 0,
              'todayCollected': 0,
              'canBalance': 0,
              'activeCustomersCount': 0,
            });
  }

  /// Stream dealer can transactions
  Stream<List<CanTransactionModel>> getDealerCanLedger(String dealerId) {
    return _canTransactions
        .where('dealerId', isEqualTo: dealerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => CanTransactionModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((_) => <CanTransactionModel>[]);
  }

  /// Record walk-in can return directly at dealer store
  Future<void> recordWalkInCanReturn({
    required String dealerId,
    required String? dealerName,
    required String userId,
    required String userName,
    String userPhone = '',
    required int emptyCollected,
    double refundDepositAmount = 0.0,
    String notes = '',
  }) async {
    final batch = _firestore.batch();

    final txRef = _canTransactions.doc();
    final transaction = CanTransactionModel(
      id: txRef.id,
      orderId: 'WALKIN-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      dealerId: dealerId,
      dealerName: dealerName,
      fullDelivered: 0,
      emptyCollected: emptyCollected,
      depositAmount: -refundDepositAmount,
      exchangeType: CanExchangeType.walkInReturn,
      notes: notes.isNotEmpty ? notes : 'Store Walk-in Empty Can Return',
      createdAt: DateTime.now(),
    );
    batch.set(txRef, transaction.toFirestore());

    if (userId.isNotEmpty) {
      final userRef = _users.doc(userId);
      batch.set(userRef, {
        'totalEmptyCansReturned': FieldValue.increment(emptyCollected),
        'canBalance': FieldValue.increment(-emptyCollected),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    // Auto-credit customer wallet balance instantly if refund is owed
    if (userId.isNotEmpty && refundDepositAmount > 0) {
      try {
        await _walletRepo.addFunds(
          userId: userId,
          amount: refundDepositAmount,
          description: 'Instant Refund: Deposit for $emptyCollected empty can(s) returned at store',
        );
      } catch (e) {
        // Log wallet refund error gracefully
      }
    }
  }

  // ─────────────────────────────────────────────
  // Delivery Partner Execution
  // ─────────────────────────────────────────────

  /// Record delivery & empty can collection in transaction ledger and update order
  Future<void> recordCanCollection({
    required String orderId,
    required String userId,
    required String userName,
    String userPhone = '',
    required String dealerId,
    String? dealerName,
    required String deliveryPartnerId,
    String? deliveryPartnerName,
    required int fullDelivered,
    required int emptyCollected,
    required double depositAmount,
    required CanExchangeType exchangeType,
    String notes = '',
  }) async {
    final batch = _firestore.batch();

    // 1. Create Can Transaction record
    final txRef = _canTransactions.doc();
    final transaction = CanTransactionModel(
      id: txRef.id,
      orderId: orderId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      dealerId: dealerId,
      dealerName: dealerName,
      deliveryPartnerId: deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName,
      fullDelivered: fullDelivered,
      emptyCollected: emptyCollected,
      depositAmount: depositAmount,
      exchangeType: exchangeType,
      notes: notes,
      createdAt: DateTime.now(),
    );
    batch.set(txRef, transaction.toFirestore());

    // 2. Update Order status
    final orderRef = _orders.doc(orderId);
    batch.update(orderRef, {
      'emptyCansCollected': emptyCollected,
      'canCollectionStatus': emptyCollected > 0 ? 'collected' : 'not_collected',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Increment User can balance
    if (userId.isNotEmpty) {
      final userRef = _users.doc(userId);
      batch.set(userRef, {
        'totalFullCans': FieldValue.increment(fullDelivered),
        'totalEmptyCansReturned': FieldValue.increment(emptyCollected),
        'canBalance': FieldValue.increment(fullDelivered - emptyCollected),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Admin App Methods
  // ─────────────────────────────────────────────

  /// Stream platform-wide can statistics
  Stream<PlatformCanSummaryModel> getPlatformCanSummary() {
    return _canTransactions.snapshots().map((snapshot) {
      int totalDelivered = 0;
      int totalCollected = 0;
      int todayDispatched = 0;
      int todayCollected = 0;
      double totalDeposit = 0.0;
      final Set<String> customersWithCans = {};

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      for (final doc in snapshot.docs) {
        final tx = CanTransactionModel.fromFirestore(doc);
        totalDelivered += tx.fullDelivered;
        totalCollected += tx.emptyCollected;
        totalDeposit += tx.depositAmount;

        if (tx.fullDelivered > tx.emptyCollected) {
          customersWithCans.add(tx.userId);
        }

        if (tx.createdAt.isAfter(startOfToday)) {
          todayDispatched += tx.fullDelivered;
          todayCollected += tx.emptyCollected;
        }
      }

      final inCirculation = totalDelivered - totalCollected;

      return PlatformCanSummaryModel(
        totalCansInCirculation: inCirculation > 0 ? inCirculation : 0,
        totalDispatchedToday: todayDispatched,
        totalCollectedToday: todayCollected,
        totalDepositLiability: totalDeposit > 0 ? totalDeposit : 0.0,
        activeCustomersWithCans: customersWithCans.length,
      );
    });
  }

  /// Stream all platform can transactions
  Stream<List<CanTransactionModel>> getAllCanTransactions() {
    return _canTransactions
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => CanTransactionModel.fromFirestore(d)).toList())
        .handleError((_) => <CanTransactionModel>[]);
  }

  /// Get platform pricing & deposit settings
  Stream<Map<String, dynamic>> getPlatformCanConfig() {
    return _configDoc.snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'refillPrice': 50.0,
          'refillOriginalPrice': 80.0,
          'exchangeDiscount': 30.0,
          'newCanPrice': 150.0,
          'refundableDeposit': 100.0,
          'bottlePackPrice': 90.0,
        };
      }
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return {
        'refillPrice': (data['refillPrice'] as num?)?.toDouble() ?? 50.0,
        'refillOriginalPrice': (data['refillOriginalPrice'] as num?)?.toDouble() ?? 80.0,
        'exchangeDiscount': (data['exchangeDiscount'] as num?)?.toDouble() ?? 30.0,
        'newCanPrice': (data['newCanPrice'] as num?)?.toDouble() ?? 150.0,
        'refundableDeposit': (data['refundableDeposit'] as num?)?.toDouble() ?? 100.0,
        'bottlePackPrice': (data['bottlePackPrice'] as num?)?.toDouble() ?? 90.0,
      };
    }).handleError((_) => {
      'refillPrice': 50.0,
      'refillOriginalPrice': 80.0,
      'exchangeDiscount': 30.0,
      'newCanPrice': 150.0,
      'refundableDeposit': 100.0,
      'bottlePackPrice': 90.0,
    });
  }

  /// Update platform pricing & deposit rules
  Future<void> updatePlatformCanConfig({
    required double refillPrice,
    required double refillOriginalPrice,
    required double exchangeDiscount,
    required double newCanPrice,
    required double refundableDeposit,
    required double bottlePackPrice,
  }) async {
    await _configDoc.set({
      'refillPrice': refillPrice,
      'refillOriginalPrice': refillOriginalPrice,
      'exchangeDiscount': exchangeDiscount,
      'newCanPrice': newCanPrice,
      'refundableDeposit': refundableDeposit,
      'bottlePackPrice': bottlePackPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Process deposit refund for customer who returned cans
  Future<void> processCanDepositRefund({
    required String userId,
    required String userName,
    required double refundAmount,
    required int cansReturned,
    String adminNotes = '',
  }) async {
    final batch = _firestore.batch();

    final txRef = _canTransactions.doc();
    final transaction = CanTransactionModel(
      id: txRef.id,
      orderId: 'REFUND-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      dealerId: 'ADMIN',
      dealerName: 'GroceryGo Platform',
      fullDelivered: 0,
      emptyCollected: cansReturned,
      depositAmount: -refundAmount,
      exchangeType: CanExchangeType.returnOnly,
      notes: 'Deposit Refund: ₹${refundAmount.toStringAsFixed(0)}. $adminNotes',
      createdAt: DateTime.now(),
    );
    batch.set(txRef, transaction.toFirestore());

    final userRef = _users.doc(userId);
    batch.set(userRef, {
      'canBalance': FieldValue.increment(-cansReturned),
      'totalRefundsReceived': FieldValue.increment(refundAmount),
    }, SetOptions(merge: true));

    await batch.commit();

    // Auto-credit customer wallet balance
    if (userId.isNotEmpty && refundAmount > 0) {
      try {
        await _walletRepo.addFunds(
          userId: userId,
          amount: refundAmount,
          description: 'Can Deposit Refund ($cansReturned returned): ₹${refundAmount.toStringAsFixed(0)}',
        );
      } catch (e) {
        // Log gracefully
      }
    }
  }
}
