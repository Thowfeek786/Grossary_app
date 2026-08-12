import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatelessWidget {
  final double destLat;
  final double destLng;
  final String title;
  final String? address;
  final String? phone;

  const NavigationScreen({
    super.key,
    required this.destLat,
    required this.destLng,
    required this.title,
    this.address,
    this.phone,
  });

  Future<void> _launchExternalMap() async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng');
    final geoUrl = Uri.parse('geo:$destLat,$destLng?q=$destLat,$destLng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callContact(BuildContext context) async {
    final targetPhone = (phone != null && phone!.trim().isNotEmpty) ? phone! : '+919876543210';
    final cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri(scheme: 'tel', path: cleanPhone);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing $targetPhone...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current simulated start location nearby
    final startLat = destLat > 0 ? destLat - 0.015 : 11.0000;
    final startLng = destLng > 0 ? destLng - 0.015 : 76.9600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Google Map Background View
          MapNavigationWidget(
            startLocation: LatLng(startLat, startLng),
            endLocation: LatLng(destLat, destLng),
          ),

          // Top Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B3C26),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.directions_bike_rounded, color: Color(0xFF34D399), size: 13),
                            SizedBox(width: 4),
                            Text(
                              '~12 mins • 3.2 km trip',
                              style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _launchExternalMap,
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                    tooltip: 'Open in Google Maps App',
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Card & Action CTAs
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF059669), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            if (address != null && address!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  address!,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      // Launch Google Maps App CTA
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _launchExternalMap,
                          icon: const Icon(Icons.navigation_rounded, size: 20),
                          label: const Text(
                            'Start Google Maps App',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 3,
                          ),
                        ),
                      ),

                      if (phone != null && phone!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        // Call Contact CTA
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: () => _callContact(context),
                            icon: const Icon(Icons.call_rounded, color: Color(0xFF059669), size: 22),
                            tooltip: 'Call Contact',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
