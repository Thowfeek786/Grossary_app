import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class BannerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('banners');

  Stream<List<BannerModel>> getBanners({bool activeOnly = true}) {
    Query q = _col;
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    
    return q.snapshots().map((s) {
      final list = s.docs.map(BannerModel.fromFirestore).toList();
      // Sort in memory to avoid needing composite index for where + orderBy
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<String> addBanner(BannerModel banner) async {
    final ref = _col.doc();
    await ref.set({...banner.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _col.doc(banner.id).update(banner.toFirestore());
  }

  Future<void> deleteBanner(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> toggleBannerActive(String id, bool isActive) async {
    await _col.doc(id).update({'isActive': isActive});
  }
}
