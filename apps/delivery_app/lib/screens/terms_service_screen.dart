import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class TermsServiceScreen extends StatelessWidget {
  const TermsServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Partner Terms of Service',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Welcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0B3C26).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFF34D399), size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Partner Agreement',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Terms & conditions governing fleet operations, payouts, and safety protocols.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSection(
              num: '1',
              title: 'Independent Delivery Partner Status',
              content:
                  'As a GroceryGo delivery partner, you operate as an independent contractor. You retain full flexibility to choose your active working hours by toggling your Duty status in the app.',
            ),
            _buildSection(
              num: '2',
              title: 'Order Handling & Package Safety',
              content:
                  'Partners must ensure grocery items, cold-storage dairy, and fragile perishables are handled with extreme care inside the designated thermal delivery bag during transit.',
            ),
            _buildSection(
              num: '3',
              title: 'Payouts, Earnings & Tips',
              content:
                  'Trip earnings (~₹45 base pay + peak hour surge bonuses) are calculated per completed delivery. 100% of customer tips go directly to the partner wallet without commission deductions.',
            ),
            _buildSection(
              num: '4',
              title: 'Road Safety & Traffic Compliance',
              content:
                  'Wearing a certified protective helmet, possessing a valid Driving License (DL), and adhering to local traffic regulations is mandatory at all times during delivery routes.',
            ),
            _buildSection(
              num: '5',
              title: 'Real-Time GPS Location Tracking',
              content:
                  'Background location permission is utilized exclusively during active delivery trips to provide customers and dark store dispatches with accurate live ETA tracking.',
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'GroceryGo Partner Agreement • Last Updated August 2026',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String num, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              num,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
