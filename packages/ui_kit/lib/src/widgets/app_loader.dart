import 'package:flutter/material.dart';
import 'package:core/core.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  const AppLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

class AppFullScreenLoader extends StatelessWidget {
  final String? message;
  const AppFullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20)],
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'Loading...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
