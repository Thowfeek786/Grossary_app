import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Notifications'),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationRepository().getUserNotifications(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications Yet',
              subtitle: 'We will notify you about your orders and offers!',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _NotifyTile(notify: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotifyTile extends StatelessWidget {
  final NotificationModel notify;
  const _NotifyTile({required this.notify});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (notify.type == 'order' ? AppColors.primary : AppColors.secondary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notify.type == 'order' ? Icons.shopping_bag_outlined : Icons.local_offer_outlined,
              color: notify.type == 'order' ? AppColors.primary : AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notify.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(AppHelpers.formatDateTime(notify.createdAt), style: const TextStyle(color: AppColors.grey400, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notify.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
