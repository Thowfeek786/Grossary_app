import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class WaterSubscriptionRepository {
  final FirebaseFirestore _firestore;

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

  /// Stream subscriptions assigned to a dealer for upcoming manifests
  Stream<List<WaterSubscriptionModel>> getDealerSubscriptions(String dealerId) {
    return _subsRef
        .where('dealerId', isEqualTo: dealerId)
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WaterSubscriptionModel.fromFirestore(d)).toList());
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

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    await _subsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.cancelled.name,
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
