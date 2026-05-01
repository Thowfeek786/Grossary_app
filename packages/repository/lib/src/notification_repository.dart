import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('notifications');

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> sendNotification(NotificationModel notification) async {
    final ref = _col.doc();
    await ref.set({...notification.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final unread = await _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<int> getUnreadCount(String userId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    required String topic,
    String? type,
  }) async {
    // 1. In a real app, you'd call a Cloud Function or FCM REST API here
    // For this implementation, we log and save to a 'broadcast_notifications' collection
    // so individual apps can also pull from there if needed.
    
    final ref = _db.collection('notifications').doc();
    await ref.set({
      'title': title,
      'body': body,
      'topic': topic,
      'type': type ?? 'broadcast',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'userId': 'broadcast_$topic', // Special ID for filtering
    });
  }
}
