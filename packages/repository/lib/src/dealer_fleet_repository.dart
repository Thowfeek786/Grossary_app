import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class DealerFleetRepository {
  final FirebaseFirestore _firestore;

  DealerFleetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _fleetRef => _firestore.collection('dealer_fleet');

  /// Stream dedicated fleet for a dealer
  Stream<List<DealerDriverModel>> streamDealerFleet(String dealerId) {
    return _fleetRef
        .where('dealerId', isEqualTo: dealerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => DealerDriverModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.hiredAt.compareTo(a.hiredAt));
          return list;
        })
        .handleError((_) => <DealerDriverModel>[]);
  }

  /// Stream all store fleet drivers (for Admin)
  Stream<List<DealerDriverModel>> streamAllFleets() {
    return _fleetRef
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => DealerDriverModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.hiredAt.compareTo(a.hiredAt));
          return list;
        })
        .handleError((_) => <DealerDriverModel>[]);
  }

  /// Check if a driver is dedicated to a specific dealer
  Stream<DealerDriverModel?> streamDriverAffiliation(String driverId) {
    return _fleetRef
        .where('driverId', isEqualTo: driverId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return DealerDriverModel.fromFirestore(snap.docs.first);
        })
        .handleError((_) => null);
  }

  /// Hire / Register a new dedicated delivery partner
  Future<String> hireDriver(DealerDriverModel driver) async {
    final docRef = _fleetRef.doc();
    final newDriver = driver.copyWith(id: docRef.id);
    await docRef.set(newDriver.toFirestore());
    return docRef.id;
  }

  /// Update driver duty status (Available, On Route, Off Duty)
  Future<void> updateDriverWorkStatus(String id, DriverWorkStatus status) async {
    await _fleetRef.doc(id).update({
      'workStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record completed drop & credit pending payout
  Future<void> recordDropCompleted(String id, {int cans = 1, double earnings = 25.0}) async {
    await _fleetRef.doc(id).update({
      'totalDropsCompleted': FieldValue.increment(1),
      'totalCansDelivered': FieldValue.increment(cans),
      'pendingPayout': FieldValue.increment(earnings),
      'workStatus': DriverWorkStatus.availableAtStore.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Settle driver payout
  Future<void> settlePayout(String id, double amount) async {
    await _fleetRef.doc(id).update({
      'pendingPayout': 0.0,
      'lastPayoutAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove driver from dedicated fleet
  Future<void> removeDriver(String id) async {
    await _fleetRef.doc(id).update({
      'isActive': false,
      'workStatus': DriverWorkStatus.offDuty.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
