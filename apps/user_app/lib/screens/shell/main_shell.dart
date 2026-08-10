import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/cart_provider.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isVisible = true;
  String? _lastLocation;

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/categories')) return 1;
    if (loc.startsWith('/orders')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final currentIndex = _currentIndex(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final bool isMainTab = currentLocation == '/home' ||
                           currentLocation == '/categories' ||
                           currentLocation == '/orders' ||
                           currentLocation == '/profile';

    if (_lastLocation != currentLocation) {
      _lastLocation = currentLocation;
      _isVisible = true;
    }

    final bool showNavBar = _isVisible && isMainTab;

    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isVisible) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isVisible) setState(() => _isVisible = false);
              });
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isVisible) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_isVisible) setState(() => _isVisible = true);
              });
            }
          }
          return false;
        },
        child: widget.child,
      ),
      bottomNavigationBar: !isMainTab
          ? null
          : AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutQuint,
              offset: showNavBar ? Offset.zero : const Offset(0, 1.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: showNavBar ? 1.0 : 0.0,
                child: CustomBottomNav(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    switch (index) {
                      case 0: context.go('/home'); break;
                      case 1: context.go('/categories'); break;
                      case 2: context.go('/orders'); break;
                      case 3: context.go('/profile'); break;
                    }
                  },
                  items: const [
                    BottomNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    BottomNavItem(
                      icon: Icons.category_outlined,
                      activeIcon: Icons.category_rounded,
                      label: 'Categories',
                    ),
                    BottomNavItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'Orders',
                    ),
                    BottomNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cartProvider.itemCount > 0 && currentIndex == 0
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isVisible ? Offset.zero : const Offset(0, 2),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: GestureDetector(
                  onTap: () => context.push('/cart'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? "ITEM" : "ITEMS"} IN CART',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '₹${cartProvider.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Row(
                          children: [
                            Text(
                              'View Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,

    );
  }
}
