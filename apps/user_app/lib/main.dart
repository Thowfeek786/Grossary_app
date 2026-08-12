import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

/// Must be top-level — runs in a separate isolate for background/terminated FCM messages.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background FCM message: ${message.messageId}");
  final notification = message.notification;
  if (notification != null) {
    await NotificationService.showLocalNotification(
      title: notification.title ?? 'GroceryGo Notification',
      body: notification.body ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background handler BEFORE runApp — required by Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  // Initialize Push Notifications
  await NotificationService.initialize();
  await NotificationService.subscribeToTopic(NotificationTopics.users);
  await NotificationService.subscribeToTopic(NotificationTopics.all);

  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          return MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router(auth),
            builder: (context, child) => NetworkWrapper(child: child),
          );
        },
      ),
    );
  }
}
