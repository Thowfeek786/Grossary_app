import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
    if (loc.startsWith('/cart')) return 2;
    if (loc.startsWith('/orders')) return 3;
    if (loc.startsWith('/profile')) return 4;
    return 0;
  }

  Future<void> _handlePop(BuildContext context, String currentLocation) async {
    if (currentLocation != '/home') {
      context.go('/home');
    } else {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF046A38).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.exit_to_app_rounded, color: Color(0xFF046A38), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Exit GroceryGo?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF111827))),
            ],
          ),
          content: const Text(
            'Are you sure you want to exit?',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046A38),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final currentIndex = _currentIndex(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final bool isMainTab = currentLocation == '/home' ||
                           currentLocation == '/categories' ||
                           currentLocation == '/cart' ||
                           currentLocation == '/orders' ||
                           currentLocation == '/profile';

    if (_lastLocation != currentLocation) {
      _lastLocation = currentLocation;
      _isVisible = true;
    }

    final bool showNavBar = _isVisible && isMainTab;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop(context, currentLocation);
      },
      child: Scaffold(
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
                        case 2: context.go('/cart'); break;
                        case 3: context.go('/orders'); break;
                        case 4: context.go('/profile'); break;
                      }
                    },
                    items: [
                      const BottomNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                      ),
                      const BottomNavItem(
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                        label: 'Categories',
                      ),
                      BottomNavItem(
                        icon: Icons.shopping_cart_outlined,
                        activeIcon: Icons.shopping_cart_rounded,
                        label: 'Cart',
                        badge: cartProvider.itemCount > 0 ? cartProvider.itemCount : null,
                      ),
                      const BottomNavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: 'Orders',
                      ),
                      const BottomNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Account',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
