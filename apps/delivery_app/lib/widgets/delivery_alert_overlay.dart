import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/delivery_order_alert_service.dart';
import '../providers/auth_provider.dart';

class DeliveryAlertOverlay extends StatelessWidget {
  final Widget child;

  const DeliveryAlertOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DeliveryOrderAlertService(),
      builder: (context, _) {
        final alertService = DeliveryOrderAlertService();
        final order = alertService.currentAlertOrder;
        final partner = context.watch<DeliveryAuthProvider>().user;

        return Stack(
          children: [
            child,
            if (alertService.isAlerting && order != null && partner != null)
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
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF3B82F6), width: 2),
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
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF60A5FA), size: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'NEW DELIVERY AVAILABLE!',
                                        style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
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
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                                  tooltip: 'Dismiss',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => alertService.dismissAlert(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF475569)),
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await alertService.acceptDelivery(
                                        order,
                                        partner.id,
                                        partner.name,
                                        partner.phone,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('🛵 Order accepted for delivery!'),
                                            backgroundColor: const Color(0xFF3B82F6),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
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
