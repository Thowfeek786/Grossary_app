import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class PayoutRepository {
  final FirebaseFirestore _db;

  PayoutRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _payouts => _db.collection('payout_requests');

  /// Delivery Partner submits manual payout request
  Future<void> requestPayout(PayoutRequestModel request) async {
    await _payouts.add(request.toFirestore());
  }

  /// Stream of payout requests for admin app
  Stream<List<PayoutRequestModel>> getPayoutRequestsStream() {
    return _payouts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PayoutRequestModel.fromFirestore(doc)).toList());
  }

  /// Stream of payout requests for a specific partner
  Stream<List<PayoutRequestModel>> getPartnerPayoutRequests(String partnerId) {
    return _payouts
        .where('partnerId', isEqualTo: partnerId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PayoutRequestModel.fromFirestore(doc)).toList());
  }

  /// Admin approves or rejects payout request
  Future<void> updatePayoutStatus({
    required String requestId,
    required String status, // 'approved' or 'rejected'
  }) async {
    await _payouts.doc(requestId).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}
