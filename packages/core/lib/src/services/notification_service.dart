import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      // Request permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      }

      // Foreground messaging handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message: ${message.messageId}');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
      });

      // Handle background → foreground tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification opened app: ${message.messageId}');
      });

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM token refreshed');
      });
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// Save FCM token to user document in Firestore
  static Future<void> saveFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && userId.isNotEmpty) {
        await _db.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved for user $userId');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Remove FCM token when user logs out
  static Future<void> removeFcmToken(String userId) async {
    try {
      if (userId.isNotEmpty) {
        await _db.collection('users').doc(userId).update({
          'fcmToken': null,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token removed for user $userId');
      }
    } catch (e) {
      debugPrint('Failed to remove FCM token: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
