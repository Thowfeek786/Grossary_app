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

    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isVisible) setState(() => _isVisible = false);
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isVisible) setState(() => _isVisible = true);
          }
          return true;
        },
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuint,
        offset: _isVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _isVisible ? 1.0 : 0.0,
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
            items: [
              const BottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              const BottomNavItem(
                icon: Icons.category_outlined,
                activeIcon: Icons.category_rounded,
                label: 'Categories',
              ),
              const BottomNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Orders',
              ),
              const BottomNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: cartProvider.itemCount > 0 && currentIndex == 0
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isVisible ? Offset.zero : const Offset(0, 2),
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/cart'),
                backgroundColor: const Color(0xFF2E7D32),
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                label: Text(
                  'Cart (${cartProvider.itemCount})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }
}
