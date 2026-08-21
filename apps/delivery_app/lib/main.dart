import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'router/app_router.dart';

/// Must be top-level — runs in a separate isolate for background/terminated FCM messages.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("🛵 [DeliveryApp] Background message received: ${message.messageId}");
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '🛵 NEW DELIVERY ALERT!';
    final body = notification?.body ?? message.data['body'] ?? 'A new grocery order is packed and ready for pickup!';
    
    await NotificationService.showLocalNotification(
      title: title,
      body: body,
      payload: '/home',
    );
  } catch (e) {
    debugPrint("⚠️ Background message handling error: $e");
  }
}

// Delivery App Main Entry
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background handler BEFORE runApp — required by Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  // Initialize Push Notifications
  await NotificationService.initialize();
  await NotificationService.subscribeToTopic(NotificationTopics.deliveryPartners);
  await NotificationService.subscribeToTopic(NotificationTopics.all);

  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeliveryAuthProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
      ],
      child: Consumer<DeliveryAuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: AppStrings.deliveryAppName,
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router(auth),
            builder: (context, child) => NetworkWrapper(child: child),
          );
        },
      ),
    );
  }
}
