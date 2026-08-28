import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';
import 'wallet_repository.dart';

class WaterSubscriptionRepository {
  final FirebaseFirestore _firestore;
  final WalletRepository _walletRepo = WalletRepository();

  WaterSubscriptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _subsRef => _firestore.collection('water_subscriptions');

  /// Stream all active subscriptions for a customer
  Stream<List<WaterSubscriptionModel>> getUserSubscriptions(String userId) {
    return _subsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WaterSubscriptionModel.fromFirestore(d)).toList());
  }

  /// Stream all subscriptions across all dealers (for Admin)
  Stream<List<WaterSubscriptionModel>> getAllSubscriptions() {
    return _subsRef
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => WaterSubscriptionModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((_) => <WaterSubscriptionModel>[]);
  }

  /// Stream subscriptions assigned to a dealer for upcoming manifests (Active only)
  Stream<List<WaterSubscriptionModel>> getDealerSubscriptions(String dealerId) {
    return _subsRef
        .where('dealerId', isEqualTo: dealerId)
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WaterSubscriptionModel.fromFirestore(d)).toList())
        .handleError((_) => <WaterSubscriptionModel>[]);
  }

  /// Stream all subscriptions for a dealer (Active, Paused, Cancelled)
  Stream<List<WaterSubscriptionModel>> getDealerAllSubscriptions(String dealerId) {
    return _subsRef
        .where('dealerId', isEqualTo: dealerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => WaterSubscriptionModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((_) => <WaterSubscriptionModel>[]);
  }

  /// Create a new water subscription
  Future<String> createSubscription(WaterSubscriptionModel sub) async {
    final docRef = _subsRef.doc();
    final newSub = sub.copyWith(id: docRef.id);
    await docRef.set(newSub.toMap());
    return docRef.id;
  }

  /// Pause subscription during vacation/holiday
  Future<void> pauseSubscription({
    required String subscriptionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _subsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.paused.name,
      'pauseStartDate': Timestamp.fromDate(startDate),
      'pauseEndDate': Timestamp.fromDate(endDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Resume a paused subscription
  Future<void> resumeSubscription(String subscriptionId, DateTime nextDeliveryDate) async {
    await _subsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.active.name,
      'pauseStartDate': null,
      'pauseEndDate': null,
      'nextScheduledDelivery': Timestamp.fromDate(nextDeliveryDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel subscription with reason tracking and safety metadata
  Future<void> cancelSubscription(
    String subscriptionId, {
    String? reason,
    String cancelledBy = 'customer',
  }) async {
    await _subsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.cancelled.name,
      'cancellationReason': reason ?? 'Cancelled by $cancelledBy',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': cancelledBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update subscription parameters (cadence, quantity, delivery address, time slot)
  Future<void> updateSubscriptionPlan({
    required String subscriptionId,
    SubscriptionCadence? cadence,
    List<int>? customDays,
    int? quantityPerDelivery,
    String? timeSlot,
    String? deliveryAddress,
    String? deliveryInstructions,
    double? newPricePerCan,
    DateTime? nextScheduledDelivery,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (cadence != null) updates['cadence'] = cadence.name;
    if (customDays != null) updates['customDays'] = customDays;
    if (quantityPerDelivery != null) updates['quantityPerDelivery'] = quantityPerDelivery;
    if (timeSlot != null) updates['timeSlot'] = timeSlot;
    if (deliveryAddress != null) updates['deliveryAddress'] = deliveryAddress;
    if (deliveryInstructions != null) updates['deliveryInstructions'] = deliveryInstructions;
    if (newPricePerCan != null) updates['pricePerCan'] = newPricePerCan;
    if (nextScheduledDelivery != null) {
      updates['nextScheduledDelivery'] = Timestamp.fromDate(nextScheduledDelivery);
    }

    await _subsRef.doc(subscriptionId).update(updates);
  }

  /// Complete morning drop-off: auto-advance schedule, update counters, record jar swap, & debit wallet
  Future<void> completeMorningDrop(WaterSubscriptionModel sub) async {
    final now = DateTime.now();
    final nextDate = calculateNextDelivery(sub.cadence, customDays: sub.customDays, fromDate: now);

    // 1. Advance Subscription next delivery and delivery counter
    await _subsRef.doc(sub.id).update({
      'totalDeliveriesCompleted': sub.totalDeliveriesCompleted + 1,
      'nextScheduledDelivery': Timestamp.fromDate(nextDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Record can exchange transaction
    if (sub.autoExchangeCan) {
      final canTxRef = _firestore.collection('can_transactions').doc();
      final tx = CanTransactionModel(
        id: canTxRef.id,
        orderId: 'SUB-${sub.id}',
        userId: sub.userId,
        userName: sub.userName,
        userPhone: sub.userPhone,
        dealerId: sub.dealerId,
        dealerName: sub.dealerName,
        fullDelivered: sub.quantityPerDelivery,
        emptyCollected: sub.quantityPerDelivery,
        depositAmount: 0.0,
        exchangeType: CanExchangeType.refill,
        notes: 'Recurring Morning Subscription Drop',
        createdAt: now,
      );
      await canTxRef.set(tx.toFirestore());
    }

    // 3. Auto-debit wallet if payment is configured for wallet
    if (sub.paymentType == 'wallet_auto_debit') {
      final totalCost = sub.pricePerCan * sub.quantityPerDelivery;
      await _walletRepo.deductBalance(
        userId: sub.userId,
        amount: totalCost,
        description: 'Auto-Debit: ${sub.quantityPerDelivery}x Pure 20L Water Can Morning Drop',
      );
    }
  }

  /// Update subscription frequency and parameters
  Future<void> updateSubscriptionCadence({
    required String subscriptionId,
    required SubscriptionCadence cadence,
    required int quantity,
    required List<int> customDays,
  }) async {
    final nextDate = calculateNextDelivery(cadence, customDays: customDays);
    await _subsRef.doc(subscriptionId).update({
      'cadence': cadence.name,
      'quantityPerDelivery': quantity,
      'customDays': customDays,
      'nextScheduledDelivery': Timestamp.fromDate(nextDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Compute next scheduled delivery date based on cadence
  DateTime calculateNextDelivery(SubscriptionCadence cadence, {List<int>? customDays, DateTime? fromDate}) {
    final base = fromDate ?? DateTime.now();
    switch (cadence) {
      case SubscriptionCadence.daily:
        return base.add(const Duration(days: 1));
      case SubscriptionCadence.alternateDays:
        return base.add(const Duration(days: 2));
      case SubscriptionCadence.every3Days:
        return base.add(const Duration(days: 3));
      case SubscriptionCadence.weekly:
        return base.add(const Duration(days: 7));
      case SubscriptionCadence.customDays:
        if (customDays == null || customDays.isEmpty) {
          return base.add(const Duration(days: 2));
        }
        DateTime next = base.add(const Duration(days: 1));
        for (int i = 0; i < 7; i++) {
          if (customDays.contains(next.weekday)) {
            return next;
          }
          next = next.add(const Duration(days: 1));
        }
        return base.add(const Duration(days: 2));
    }
  }
}
