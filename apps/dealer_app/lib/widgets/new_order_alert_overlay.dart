import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/dealer_order_alert_service.dart';

class NewOrderAlertOverlay extends StatelessWidget {
  final Widget child;

  const NewOrderAlertOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DealerOrderAlertService(),
      builder: (context, _) {
        final alertService = DealerOrderAlertService();
        final order = alertService.currentAlertOrder;

        return Stack(
          children: [
            child,
            if (alertService.isRinging && order != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF10B981), width: 2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF34D399), size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Text(
                                            'NEW ORDER RECEIVED!',
                                            style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '#${order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()} • ₹${order.total.toStringAsFixed(0)} • ${order.itemCount} items',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => alertService.dismissAlert(),
                                  icon: const Icon(Icons.volume_off_rounded, color: Color(0xFF94A3B8), size: 20),
                                  tooltip: 'Mute Sound',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final orderId = order.id;
                                      alertService.dismissAlert();
                                      context.push('/order/$orderId');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF475569)),
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('View Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await alertService.acceptAndPack(order);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Order accepted and packing started!'),
                                            backgroundColor: const Color(0xFF059669),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('Accept & Pack', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
