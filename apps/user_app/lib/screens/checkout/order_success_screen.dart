import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success animation container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (_, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 72),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Order Placed! 🎉',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'Your order has been successfully placed and will be processed soon.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text('Order ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('#${orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Track My Order',
                icon: Icons.local_shipping_rounded,
                onTap: () => context.go('/orders/$orderId'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continue Shopping',
                variant: AppButtonVariant.outlined,
                onTap: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
