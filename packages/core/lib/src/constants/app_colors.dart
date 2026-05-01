import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Fresh Green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // Secondary - Warm Orange
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryLight = Color(0xFFFF9F40);
  static const Color secondaryDark = Color(0xFFC43E00);

  // Accent
  static const Color accent = Color(0xFF00ACC1);
  static const Color accentLight = Color(0xFF5DDEF4);
  static const Color accentDark = Color(0xFF007C91);

  // Semantic
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Background
  static const Color background = Color(0xFFF9FBF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color statusPending = Color(0xFFFFA000);
  static const Color statusProcessing = Color(0xFF1976D2);
  static const Color statusShipped = Color(0xFF7B1FA2);
  static const Color statusDelivered = Color(0xFF388E3C);
  static const Color statusCancelled = Color(0xFFD32F2F);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
