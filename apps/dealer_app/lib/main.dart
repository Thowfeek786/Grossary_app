import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

/// Must be top-level — runs in a separate isolate for background/terminated FCM messages.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background message received — Android OS will display it automatically
  // if the FCM payload contains a 'notification' key.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background handler BEFORE runApp — required by Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  // Initialize Push Notifications
  await NotificationService.initialize();
  await NotificationService.subscribeToTopic(NotificationTopics.dealers);
  await NotificationService.subscribeToTopic(NotificationTopics.all);

  runApp(const DealerApp());
}

class DealerApp extends StatelessWidget {
  const DealerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DealerAuthProvider()),
      ],
      child: Consumer<DealerAuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: AppStrings.dealerAppName,
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
