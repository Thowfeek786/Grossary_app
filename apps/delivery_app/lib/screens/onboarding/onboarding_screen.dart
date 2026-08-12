import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class DeliveryOnboardingScreen extends StatefulWidget {
  const DeliveryOnboardingScreen({super.key});

  @override
  State<DeliveryOnboardingScreen> createState() => _DeliveryOnboardingScreenState();
}

class _DeliveryOnboardingScreenState extends State<DeliveryOnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<_DeliverySlideData> _slides = const [
    _DeliverySlideData(
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFF34D399),
      title: 'Ultra-Fast Grocery Delivery',
      subtitle: 'Deliver fresh groceries from nearby darkstores within minutes. Earn up to ₹45+ on every successful delivery trip.',
    ),
    _DeliverySlideData(
      icon: Icons.account_balance_wallet_rounded,
      accentColor: Color(0xFF60A5FA),
      title: 'Instant Payouts & Bonuses',
      subtitle: 'Track your daily earnings in real-time. Direct bank or UPI deposits with zero hidden fees and extra peak-hour incentives.',
    ),
    _DeliverySlideData(
      icon: Icons.schedule_rounded,
      accentColor: Color(0xFFFBBF24),
      title: 'Flexible On-Duty Schedule',
      subtitle: 'Be your own boss! Toggle your duty status Online whenever you are ready to deliver, supported by 24/7 dispatch helpline.',
    ),
  ];

  void _onFinish() async {
    await OnboardingService.setOnboardingCompleted('delivery');
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3C26),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with App Branding & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF34D399), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GroceryGo Partner',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: _onFinish,
                      child: const Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                ],
              ),
            ),

            // PageView Slides Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (ctx, i) {
                  final slide = _slides[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Glowing Hero Icon Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(color: slide.accentColor.withValues(alpha: 0.4), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: slide.accentColor.withValues(alpha: 0.3),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 76, color: slide.accentColor),
                        ),

                        const SizedBox(height: 44),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Subtitle Description
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Animated Page Indicator Dots
                  Row(
                    children: List.generate(_slides.length, (idx) {
                      final isSelected = _currentPage == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: isSelected ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF34D399) : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Continue / Finish Action Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _onFinish();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF34D399).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == _slides.length - 1 ? 'Start Delivering' : 'Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliverySlideData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _DeliverySlideData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });
}
