import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class EarningHistoryScreen extends StatelessWidget {
  const EarningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Earnings History'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildBalanceCard(context, user),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Payouts'),
            const SizedBox(height: 16),
            _buildPayoutTile(
              'May 22 - May 28',
              '₹${(user?.totalEarnings ?? 0) * 0.8 > 2000 ? 2450 : 0}',
              'Completed',
              true,
            ),
            _buildPayoutTile('May 15 - May 21', '₹1,980', 'Completed', true),
            const SizedBox(height: 32),
            _buildSectionHeader('Daily Breakdown (This Week)'),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              'Today',
              '${(user?.totalDeliveries ?? 0) > 5 ? 6 : user?.totalDeliveries} orders',
              '₹${(user?.totalDeliveries ?? 0) * 45}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, UserModel? user) {
    final balance = user?.totalEarnings ?? 0.0;
    final orders = user?.totalDeliveries ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat('Lifetime', '₹${balance.toStringAsFixed(0)}'),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              _buildMiniStat('Orders', '$orders'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('View All')),
      ],
    );
  }

  Widget _buildPayoutTile(
    String range,
    String amount,
    String status,
    bool completed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                range,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: completed ? AppColors.success : AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String day, String count, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
