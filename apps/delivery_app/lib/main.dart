import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
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
