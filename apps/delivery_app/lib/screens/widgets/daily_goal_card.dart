import 'package:flutter/material.dart';

class DailyGoalCard extends StatelessWidget {
  final double currentEarnings;
  final int completedOrders;
  final double targetGoal;

  const DailyGoalCard({
    super.key,
    required this.currentEarnings,
    required this.completedOrders,
    this.targetGoal = 500.0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentEarnings / targetGoal).clamp(0.0, 1.0);
    final isGoalAchieved = currentEarnings >= targetGoal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: Color(0xFF059669), size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'DAILY TARGET',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 13),
                    SizedBox(width: 3),
                    Text(
                      '1.2x Surge',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${currentEarnings.toStringAsFixed(0)} / ₹${targetGoal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
              ),
              Text(
                isGoalAchieved ? '🎉 Target Achieved!' : '${(progress * 100).toStringAsFixed(0)}% Completed',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isGoalAchieved ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                isGoalAchieved ? const Color(0xFF10B981) : const Color(0xFF059669),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedOrders Trips Completed Today',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Estimated ~₹45 / trip',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
