import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    const _OnboardingData(
      title: 'Fresh Organic Groceries',
      subtitle: 'Handpicked farm-fresh fruits, vegetables & daily essentials delivered straight to your doorstep.',
      imagePath: 'assets/images/onboarding_fresh.png',
      accentColor: Color(0xFF1B5E20),
    ),
    const _OnboardingData(
      title: 'Super-Fast Delivery',
      subtitle: 'Express 15-minute delivery from local trusted grocery partners near you.',
      imagePath: 'assets/images/onboarding_delivery.png',
      accentColor: Color(0xFF2E7D32),
    ),
    const _OnboardingData(
      title: 'Unbeatable Deals & Cashback',
      subtitle: 'Save big every day with exclusive promo codes, instant wallet cashback & wholesale prices.',
      imagePath: 'assets/images/onboarding_deals.png',
      accentColor: Color(0xFF388E3C),
    ),
  ];

  void _onFinish() async {
    await OnboardingService.setOnboardingCompleted('user');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F381E),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Skip button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_grocery_store_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text('GroceryGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _onFinish,
                      child: const Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, i) {
                  final data = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Hero Image Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: MediaQuery.of(context).size.height * 0.38,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              data.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white.withValues(alpha: 0.1),
                                child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 80),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
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

            // Bottom Controls Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == idx ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx ? Colors.greenAccent : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Action Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
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
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
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

class _OnboardingData {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accentColor;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accentColor,
  });
}
