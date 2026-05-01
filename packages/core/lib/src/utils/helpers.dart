import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  AppHelpers._();

  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFFA000);
      case 'accepted': return const Color(0xFF1976D2);
      case 'processing': return const Color(0xFF7B1FA2);
      case 'shipped': return const Color(0xFF0097A7);
      case 'delivered': return const Color(0xFF388E3C);
      case 'cancelled': return const Color(0xFFD32F2F);
      default: return const Color(0xFF9E9E9E);
    }
  }

  static IconData getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'accepted': return Icons.check_circle_outline_rounded;
      case 'processing': return Icons.settings_rounded;
      case 'shipped': return Icons.local_shipping_rounded;
      case 'delivered': return Icons.done_all_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  static String sanitizeUrl(String url) {
    if (url.contains('unsplash.com') && !url.contains('fm=')) {
      return url.contains('?') ? '$url&fm=jpg' : '$url?fm=jpg';
    }
    return url;
  }
}
