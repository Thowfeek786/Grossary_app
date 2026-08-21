import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
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

class UserApp extends StatefulWidget {
  const UserApp({super.key});

  @override
  State<UserApp> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  late final AuthProvider _authProvider;
  late final CartProvider _cartProvider;
  late final ProductProvider _productProvider;
  late final OrderProvider _orderProvider;
  late final ThemeProvider _themeProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _cartProvider = CartProvider();
    _productProvider = ProductProvider();
    _orderProvider = OrderProvider();
    _themeProvider = ThemeProvider();
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _cartProvider.dispose();
    _productProvider.dispose();
    _orderProvider.dispose();
    _themeProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _cartProvider),
        ChangeNotifierProvider.value(value: _productProvider),
        ChangeNotifierProvider.value(value: _orderProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: ListenableBuilder(
        listenable: _themeProvider,
        builder: (context, _) {
          return MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            builder: (context, child) => NetworkWrapper(child: child),
          );
        },
      ),
    );
  }
}
