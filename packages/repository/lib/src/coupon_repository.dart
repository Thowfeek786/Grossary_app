import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class CouponRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('coupons');

  Future<CouponModel?> getCouponByCode(String code) async {
    try {
      final query = await _col
          .where('code', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return CouponModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error fetching coupon: $e');
      return null;
    }
  }

  Stream<List<CouponModel>> getActiveCoupons() {
    return _col.where('isActive', isEqualTo: true).snapshots().map((s) {
      return s.docs
          .map(CouponModel.fromFirestore)
          .where((c) => c.isValid)
          .toList();
    });
  }

  /// Stream ALL coupons for admin management
  Stream<List<CouponModel>> getAllCoupons() {
    return _col.snapshots().map((s) {
      final list = s.docs.map(CouponModel.fromFirestore).toList();
      list.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
      return list;
    });
  }

  /// Add a new coupon
  Future<void> addCoupon(CouponModel coupon) async {
    final ref = _col.doc();
    await ref.set(coupon.toFirestore());
  }

  /// Update an existing coupon
  Future<void> updateCoupon(CouponModel coupon) async {
    await _col.doc(coupon.id).update(coupon.toFirestore());
  }

  /// Delete a coupon
  Future<void> deleteCoupon(String id) async {
    await _col.doc(id).delete();
  }

  /// Toggle coupon active/inactive
  Future<void> toggleCouponActive(String id, bool isActive) async {
    await _col.doc(id).update({'isActive': isActive});
  }

  Future<void> incrementUsage(String couponId) async {
    await _col.doc(couponId).update({
      'usageCount': FieldValue.increment(1),
    });
  }
}
