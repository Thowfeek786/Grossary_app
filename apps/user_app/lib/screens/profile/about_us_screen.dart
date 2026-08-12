import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = SettingsRepository();

    return StreamBuilder<StoreSettingsModel>(
      stream: settingsRepo.getGlobalSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const StoreSettingsModel(id: 'global');

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: 'About ${settings.appName}',
            backgroundColor: const Color(0xFF0B3C26),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Emerald Brand Showcase Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B3C26), Color(0xFF13653F), Color(0xFF052B1B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      // App Icon Container
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34D399).withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.local_grocery_store_rounded, color: Color(0xFF0B3C26), size: 48),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        settings.appName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ultra-Fast Farm-Fresh Groceries Delivered',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      // Release Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Version ${settings.appVersion}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Key Metrics / Impact Highlights
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Highlights',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _StatCard(
                            value: settings.estimatedDeliveryTime,
                            label: 'Average Delivery',
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFF10B981),
                          ),
                          const _StatCard(
                            value: '100%',
                            label: 'Farm Fresh & Organic',
                            icon: Icons.eco_rounded,
                            color: Color(0xFF059669),
                          ),
                          const _StatCard(
                            value: '4.9 ★',
                            label: 'Customer Rating',
                            icon: Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          const _StatCard(
                            value: '50,000+',
                            label: 'Happy Deliveries',
                            icon: Icons.local_shipping_rounded,
                            color: Color(0xFF3B82F6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Company Mission & Principles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Our Core Commitments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      const _ValueItemTile(
                        icon: Icons.nature_people_rounded,
                        title: 'Direct Farm Sourcing',
                        description: 'We partner directly with certified local farmers to eliminate middlemen and deliver produce within hours of harvesting.',
                      ),
                      const SizedBox(height: 10),
                      const _ValueItemTile(
                        icon: Icons.recycling_rounded,
                        title: 'Eco-Friendly Packaging',
                        description: 'All deliveries are fulfilled using 100% biodegradable and zero single-use plastic packaging material.',
                      ),
                      const SizedBox(height: 10),
                      const _ValueItemTile(
                        icon: Icons.shield_moon_rounded,
                        title: 'Instant Quality Guarantee',
                        description: 'If you are unsatisfied with any item quality, request an instant 100% refund in our app with zero questions asked.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Policy & Action Links Group
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Legal & App Info',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _LinkTile(
                              icon: Icons.gavel_rounded,
                              label: 'Terms of Service',
                              onTap: () => _showPolicyDialog(context, 'Terms of Service', settings.termsOfService),
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _LinkTile(
                              icon: Icons.security_rounded,
                              label: 'Privacy Policy & Data Rights',
                              onTap: () => _showPolicyDialog(context, 'Privacy Policy', settings.privacyPolicy),
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _LinkTile(
                              icon: Icons.code_rounded,
                              label: 'Open Source Software Licenses',
                              onTap: () => _showLicenses(context, settings),
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _LinkTile(
                              icon: Icons.star_rate_rounded,
                              label: 'Rate ${settings.appName} on App Store',
                              onTap: () => _showRatingModal(context, settings),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Footer Branding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialBadge(icon: Icons.language_rounded, onTap: () {}),
                          const SizedBox(width: 12),
                          _SocialBadge(icon: Icons.camera_alt_rounded, onTap: () {}),
                          const SizedBox(width: 12),
                          _SocialBadge(icon: Icons.share_rounded, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '© 2026 ${settings.appName} Technologies Inc.',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crafted with ❤️ for fresh food lovers worldwide',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context, StoreSettingsModel settings) {
    showLicensePage(
      context: context,
      applicationName: settings.appName,
      applicationVersion: settings.appVersion,
    );
  }

  void _showRatingModal(BuildContext context, StoreSettingsModel settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 56, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            Text('Enjoying ${settings.appName}?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'Your feedback helps us deliver fresh groceries even faster to your neighborhood.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.star_rounded, size: 36, color: Color(0xFFF59E0B)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Thank you for rating us 5 stars! ⭐'),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _ValueItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ValueItemTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF059669), size: 20),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}

class _SocialBadge extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialBadge({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: const Color(0xFF059669), size: 18),
      ),
    );
  }
}
