import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminMainShell extends StatelessWidget {
  final Widget child;
  const AdminMainShell({super.key, required this.child});

  int _getSelectedIndex(String location) {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/users')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // /dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/users');
        break;
      case 3:
        context.go('/settings');
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
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.white.withValues(alpha: 0.5)),
              selectedIcon: const Icon(Icons.dashboard_rounded, color: Color(0xFF818CF8)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Colors.white.withValues(alpha: 0.5)),
              selectedIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF818CF8)),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded, color: Colors.white.withValues(alpha: 0.5)),
              selectedIcon: const Icon(Icons.people_rounded, color: Color(0xFF818CF8)),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.5)),
              selectedIcon: const Icon(Icons.settings_rounded, color: Color(0xFF818CF8)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
