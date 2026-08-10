import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class SettingsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('store_settings');

  // Stream global store delivery settings (Admin)
  Stream<StoreSettingsModel> getGlobalSettings() {
    return _col.doc('global').snapshots().map((snap) {
      if (!snap.exists) return const StoreSettingsModel(id: 'global');
      return StoreSettingsModel.fromFirestore(snap);
    });
  }

  // Stream dealer custom delivery settings
  Stream<StoreSettingsModel> getDealerSettings(String dealerId) {
    return _col.doc(dealerId).snapshots().map((snap) {
      if (!snap.exists) return StoreSettingsModel(id: dealerId);
      return StoreSettingsModel.fromFirestore(snap);
    });
  }

  // Update store settings (Admin or Dealer)
  Future<bool> updateSettings(StoreSettingsModel settings) async {
    try {
      await _col.doc(settings.id).set(settings.toFirestore(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      return false;
    }
  }
}
