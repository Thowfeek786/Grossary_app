import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class WaterAssetRepository {
  final FirebaseFirestore _firestore;

  WaterAssetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _assetsRef => _firestore.collection('water_assets');
  CollectionReference get _qualityLogsRef => _firestore.collection('water_quality_logs');

  /// Stream all serialized assets for a specific dark store / dealer
  Stream<List<WaterAssetModel>> getDealerAssets(String dealerId) {
    return _assetsRef
        .where('dealerId', isEqualTo: dealerId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WaterAssetModel.fromFirestore(d)).toList());
  }

  /// Stream assets currently in custody of a customer
  Stream<List<WaterAssetModel>> getCustomerHeldAssets(String userId) {
    return _assetsRef
        .where('currentOwnerId', isEqualTo: userId)
        .where('status', isEqualTo: CanAssetStatus.withCustomer.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WaterAssetModel.fromFirestore(d)).toList());
  }

  /// Stream a single asset by its unique serial QR code ID (e.g. CAN-GG-20L-10928)
  Stream<WaterAssetModel?> getAssetBySerial(String serialId) {
    return _assetsRef.doc(serialId.trim().toUpperCase()).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WaterAssetModel.fromFirestore(doc);
    });
  }

  /// Get asset once by serial
  Future<WaterAssetModel?> fetchAsset(String serialId) async {
    final doc = await _assetsRef.doc(serialId.trim().toUpperCase()).get();
    if (!doc.exists) return null;
    return WaterAssetModel.fromFirestore(doc);
  }

  /// Register / Provision a batch of new serialized water cans for a dealer
  Future<List<String>> registerNewCanBatch({
    required String dealerId,
    required String dealerName,
    required int count,
    String? prefix,
  }) async {
    final batch = _firestore.batch();
    final List<String> generatedSerials = [];
    final pfx = prefix ?? 'CAN-GG-${dealerId.substring(0, dealerId.length > 4 ? 4 : dealerId.length).toUpperCase()}';

    for (int i = 0; i < count; i++) {
      final randSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7) + (100 + i).toString();
      final serialId = '$pfx-$randSuffix';
      generatedSerials.add(serialId);

      final newAsset = WaterAssetModel(
        canSerialId: serialId,
        currentOwnerId: dealerId,
        currentOwnerName: dealerName,
        dealerId: dealerId,
        status: CanAssetStatus.inStore,
        fillCount: 1,
        lastSanitizedAt: DateTime.now(),
        history: [
          CanEventLog(
            timestamp: DateTime.now(),
            eventType: 'registered_and_filled',
            actorId: dealerId,
            actorName: dealerName,
            notes: 'Batch initial registration and pure water filling',
          ),
        ],
      );

      batch.set(_assetsRef.doc(serialId), newAsset.toMap());
    }

    await batch.commit();
    return generatedSerials;
  }

  /// Scan & Dispatch from Dealer to Delivery Partner
  Future<void> scanDispatchToDriver({
    required String serialId,
    required String driverId,
    required String driverName,
    required String orderId,
  }) async {
    final docRef = _assetsRef.doc(serialId.trim().toUpperCase());
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        throw Exception('Water can #$serialId is not registered in system');
      }

      final asset = WaterAssetModel.fromFirestore(snap);
      final updatedHistory = List<CanEventLog>.from(asset.history)
        ..add(CanEventLog(
          timestamp: DateTime.now(),
          eventType: 'dispatched_to_driver',
          actorId: driverId,
          actorName: driverName,
          orderId: orderId,
          notes: 'Handed over for delivery route',
        ));

      transaction.update(docRef, {
        'status': CanAssetStatus.dispatched.name,
        'currentOwnerType': 'delivery_partner',
        'currentOwnerId': driverId,
        'currentOwnerName': driverName,
        'currentOrderId': orderId,
        'history': updatedHistory.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Scan & Handover to Customer at Doorstep
  Future<void> scanDeliverToCustomer({
    required String serialId,
    required String userId,
    required String userName,
    required String orderId,
    required String driverId,
    required String driverName,
  }) async {
    final docRef = _assetsRef.doc(serialId.trim().toUpperCase());
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        throw Exception('Water can #$serialId not found');
      }

      final asset = WaterAssetModel.fromFirestore(snap);
      final updatedHistory = List<CanEventLog>.from(asset.history)
        ..add(CanEventLog(
          timestamp: DateTime.now(),
          eventType: 'delivered',
          actorId: driverId,
          actorName: driverName,
          orderId: orderId,
          notes: 'Delivered to customer $userName',
        ));

      transaction.update(docRef, {
        'status': CanAssetStatus.withCustomer.name,
        'currentOwnerType': 'customer',
        'currentOwnerId': userId,
        'currentOwnerName': userName,
        'currentOrderId': orderId,
        'history': updatedHistory.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Scan Empty Can Return (by Driver at doorstep or Dealer at dark store)
  Future<void> scanReturnEmptyCan({
    required String serialId,
    required String collectorId,
    required String collectorName,
    required String collectorType, // delivery_partner or dealer
    required String dealerId,
    String? orderId,
  }) async {
    final docRef = _assetsRef.doc(serialId.trim().toUpperCase());
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        throw Exception('Water can #$serialId not found in asset registry');
      }

      final asset = WaterAssetModel.fromFirestore(snap);
      final updatedHistory = List<CanEventLog>.from(asset.history)
        ..add(CanEventLog(
          timestamp: DateTime.now(),
          eventType: 'collected',
          actorId: collectorId,
          actorName: collectorName,
          orderId: orderId,
          notes: 'Empty can collected & custody transferred to $collectorName',
        ));

      transaction.update(docRef, {
        'status': CanAssetStatus.returnedEmpty.name,
        'currentOwnerType': collectorType,
        'currentOwnerId': collectorId,
        'currentOwnerName': collectorName,
        'currentOrderId': orderId,
        'history': updatedHistory.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Sanitization & Refill complete (Ready for new circulation cycle)
  Future<void> completeSanitizationAndRefill({
    required String serialId,
    required String dealerId,
    required String dealerName,
    double testedTds = 95.0,
    double testedPh = 7.2,
  }) async {
    final docRef = _assetsRef.doc(serialId.trim().toUpperCase());
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) return;

      final asset = WaterAssetModel.fromFirestore(snap);
      final newFillCount = asset.fillCount + 1;
      final newStatus = newFillCount >= 50 ? CanAssetStatus.retired : CanAssetStatus.inStore;

      final updatedHistory = List<CanEventLog>.from(asset.history)
        ..add(CanEventLog(
          timestamp: DateTime.now(),
          eventType: newStatus == CanAssetStatus.retired ? 'retired' : 'sanitized_and_refilled',
          actorId: dealerId,
          actorName: dealerName,
          notes: 'Sanitized with UV/Ozone. Fill cycle #$newFillCount. TDS: $testedTds, pH: $testedPh',
        ));

      transaction.update(docRef, {
        'status': newStatus.name,
        'currentOwnerType': 'dealer',
        'currentOwnerId': dealerId,
        'currentOwnerName': dealerName,
        'currentOrderId': null,
        'fillCount': newFillCount,
        'lastSanitizedAt': FieldValue.serverTimestamp(),
        'lastTestedTds': testedTds,
        'lastTestedPh': testedPh,
        'history': updatedHistory.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Record daily water quality test batch
  Future<void> recordQualityBatch(WaterQualityModel quality) async {
    await _qualityLogsRef.doc(quality.id.isNotEmpty ? quality.id : null).set(quality.toMap());
  }

  /// Stream latest quality log for a dealer
  Stream<WaterQualityModel?> getLatestQualityLog(String dealerId) {
    return _qualityLogsRef
        .where('dealerId', isEqualTo: dealerId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final docs = snap.docs.map(WaterQualityModel.fromFirestore).toList();
      docs.sort((a, b) => b.testedAt.compareTo(a.testedAt));
      return docs.first;
    }).handleError((_) => null);
  }
}
