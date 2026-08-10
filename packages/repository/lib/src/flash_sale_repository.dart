import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class FlashSaleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DocumentReference get _doc => _db.collection('flash_sale').doc('active');

  Stream<FlashSaleModel?> getFlashSale() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return FlashSaleModel(
          id: 'active',
          title: 'FLASH SALE ⚡',
          subtitle: 'Limited Time Offers & Big Savings',
          endTime: DateTime.now().add(const Duration(hours: 4)),
          isActive: true,
        );
      }
      return FlashSaleModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    });
  }

  Future<FlashSaleModel> getFlashSaleOnce() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return FlashSaleModel(
        id: 'active',
        title: 'FLASH SALE ⚡',
        subtitle: 'Limited Time Offers & Big Savings',
        endTime: DateTime.now().add(const Duration(hours: 4)),
        isActive: true,
      );
    }
    return FlashSaleModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

  Future<void> saveFlashSale(FlashSaleModel sale) async {
    await _doc.set(sale.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleFlashSale(bool isActive) async {
    await _doc.set({'isActive': isActive}, SetOptions(merge: true));
  }
}
