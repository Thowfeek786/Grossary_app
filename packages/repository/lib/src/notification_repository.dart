import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('notifications');

  /// Stream notifications for a user including direct and broadcast notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId, {String? userRole}) {
    final targets = <String>[
      userId,
      'broadcast_all_notifications',
      if (userRole != null && userRole.isNotEmpty) 'broadcast_${userRole}_notifications',
      if (userRole == 'customer') 'broadcast_user_notifications',
      if (userRole == 'dealer') 'broadcast_dealer_notifications',
      if (userRole == 'deliveryPartner') 'broadcast_delivery_notifications',
    ];

    return _col
        .where('userId', whereIn: targets)
        .snapshots()
        .map((s) {
          final list = s.docs.map(NotificationModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Get broadcast notifications for a specific topic that the user should see
  Stream<List<NotificationModel>> getBroadcastNotifications(String topic) {
    return _col
        .where('userId', isEqualTo: 'broadcast_$topic')
        .snapshots()
        .map((s) {
          final list = s.docs.map(NotificationModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> sendNotification(NotificationModel notification) async {
    final ref = _col.doc();
    await ref.set({...notification.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _col.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification $notificationId: $e');
    }
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

  /// Send broadcast notification:
  /// 1. Saves main broadcast record to 'notifications' collection
  /// 2. Creates individual notification records for every targeted user
  /// 3. Collects FCM tokens from matching users
  /// 4. Writes to 'fcm_send_queue' for push delivery
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    required String topic,
    String? type,
    String? imageUrl,
  }) async {
    final batch = _db.batch();

    // 1. Save the main broadcast record
    final broadcastRef = _col.doc();
    batch.set(broadcastRef, {
      'title': title,
      'body': body,
      'topic': topic,
      'type': type ?? 'broadcast',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'userId': 'broadcast_$topic',
    });

    // 2. Query users and filter in Dart for maximum reliability
    List<String> fcmTokens = [];
    try {
      final allUsersSnap = await _db.collection('users').get();

      for (final doc in allUsersSnap.docs) {
        final data = doc.data();
        final role = data['role'] as String? ?? 'customer';
        final token = data['fcmToken'] as String?;
        final userId = doc.id;

        bool matchesTarget = false;
        if (topic == 'all_notifications') {
          matchesTarget = true;
        } else if (topic == 'user_notifications' && (role == 'customer' || role == 'user')) {
          matchesTarget = true;
        } else if (topic == 'dealer_notifications' && role == 'dealer') {
          matchesTarget = true;
        } else if (topic == 'delivery_notifications' && (role == 'deliveryPartner' || role == 'delivery')) {
          matchesTarget = true;
        }

        if (matchesTarget) {
          if (token != null && token.isNotEmpty) {
            fcmTokens.add(token);
          }

          // Create in-app notification doc for this user
          final notifRef = _col.doc();
          batch.set(notifRef, {
            'title': title,
            'body': body,
            'type': type ?? 'promo',
            'imageUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'userId': userId,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching users for broadcast: $e');
    }

    // 3. Queue FCM push messages for devices
    final queueRef = _db.collection('fcm_send_queue').doc();
    batch.set(queueRef, {
      'title': title,
      'body': body,
      'tokens': fcmTokens,
      'topic': topic,
      'imageUrl': imageUrl,
      'data': {
        'type': type ?? 'broadcast',
        'notificationId': broadcastRef.id,
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'tokenCount': fcmTokens.length,
    });

    await batch.commit();
    debugPrint('Broadcast notification sent successfully to topic $topic with ${fcmTokens.length} tokens.');
  }

  /// Send a targeted notification to a specific user
  Future<void> sendTargetedNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    final batch = _db.batch();

    // Save in-app notification
    final notifRef = _col.doc();
    batch.set(notifRef, {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Get user's FCM token
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final token = userData?['fcmToken'] as String?;

      if (token != null && token.isNotEmpty) {
        final queueRef = _db.collection('fcm_send_queue').doc();
        batch.set(queueRef, {
          'title': title,
          'body': body,
          'tokens': [token],
          'data': {
            'type': type,
            'notificationId': notifRef.id,
            ...?data,
          },
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'tokenCount': 1,
        });
      }
    } catch (e) {
      debugPrint('Error sending targeted notification: $e');
    }

    await batch.commit();
  }

  /// Get all broadcast notifications sent (for admin history)
  Stream<List<Map<String, dynamic>>> getBroadcastHistory() {
    return _db
        .collection('notifications')
        .where('type', isEqualTo: 'broadcast')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Get FCM send queue status for admin
  Stream<List<Map<String, dynamic>>> getFcmQueueStatus() {
    return _db
        .collection('fcm_send_queue')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }
}
