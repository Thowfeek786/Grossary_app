import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

}

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

extension DoubleExtensions on double {
  String get toCurrency => '₹${toStringAsFixed(2)}';
}

extension IntExtensions on int {
  String get toCurrency => '₹${toStringAsFixed(2)}';
  String toStringAsFixed(int fractionDigits) => toDouble().toStringAsFixed(fractionDigits);
}

extension DateTimeExtensions on DateTime {
  String get formatted {
    return '$day/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedWithTime {
    final hour = this.hour > 12 ? this.hour - 12 : this.hour;
    final period = this.hour >= 12 ? 'PM' : 'AM';
    return '$formatted ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
