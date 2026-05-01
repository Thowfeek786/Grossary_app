import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'providers/auth_provider.dart';
import 'providers/management_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Push Notifications
  await NotificationService.initialize();

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminManagementProvider()),
      ],
      child: Consumer<AdminAuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: AppStrings.adminAppName,
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
