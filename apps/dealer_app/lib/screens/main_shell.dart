import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DealerMainShell extends StatelessWidget {
  final Widget child;
  const DealerMainShell({super.key, required this.child});

  int _getSelectedIndex(String location) {
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // /dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/inventory');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF059669).withValues(alpha: 0.15),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF059669)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: Color(0xFF059669)),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF059669)),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.storefront_rounded, color: Color(0xFF059669)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
