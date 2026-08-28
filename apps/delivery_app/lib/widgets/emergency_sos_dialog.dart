import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class EmergencySosDialog extends StatefulWidget {
  final UserModel? user;
  final String? activeOrderId;

  const EmergencySosDialog({super.key, this.user, this.activeOrderId});

  static Future<void> show(BuildContext context, {UserModel? user, String? activeOrderId}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: EmergencySosDialog(user: user, activeOrderId: activeOrderId),
      ),
    );
  }

  @override
  State<EmergencySosDialog> createState() => _EmergencySosDialogState();
}

class _EmergencySosDialogState extends State<EmergencySosDialog> {
  Position? _currentPosition;
  bool _isLoadingGps = true;
  bool _isSosTriggered = false;

  @override
  void initState() {
    super.initState();
    _fetchGps();
  }

  Future<void> _fetchGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLoadingGps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _triggerSos() {
    HapticFeedback.heavyImpact();
    setState(() => _isSosTriggered = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Emergency SOS alert sent to Central Dispatch Team!'),
        backgroundColor: Color(0xFFDC2626),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.user?.name ?? 'Delivery Partner';
    final gpsCoord = _currentPosition != null
        ? '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}'
        : 'Lat 12.9716, Lng 77.5946 (Bangalore Hub)';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Partner Safety & Support',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SOS Alert Button
          GestureDetector(
            onTap: _isSosTriggered ? null : _triggerSos,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: _isSosTriggered
                    ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                    : const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_isSosTriggered ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isSosTriggered ? Icons.check_circle_rounded : Icons.warning_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isSosTriggered ? 'SOS Signal Broadcasted ✓' : '🚨 TRIGGER EMERGENCY SOS',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Live Telemetry GPS Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR LIVE GPS TELEMETRY',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      Text(
                        _isLoadingGps ? 'Locating...' : gpsCoord,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: gpsCoord));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordinates copied!'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Copy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('24/7 Dispatcher Hotlines', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          // Action Contacts List
          _ContactActionTile(
            icon: Icons.local_police_rounded,
            color: const Color(0xFFDC2626),
            title: 'Police & Emergency Helpline',
            subtitle: 'National Emergency Response (112)',
            onTap: () => _callPhone('112'),
          ),
          const SizedBox(height: 8),
          _ContactActionTile(
            icon: Icons.headset_mic_rounded,
            color: const Color(0xFF059669),
            title: 'Central Dispatch Desk (24/7)',
            subtitle: 'Toll-Free Partner Helpline 1800-476-2379',
            onTap: () => _callPhone('18004762379'),
          ),
          const SizedBox(height: 8),
          _ContactActionTile(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF25D366),
            title: 'Chat on WhatsApp with Fleet Support',
            subtitle: 'Send trip telemetry & road issue details',
            onTap: () => _openWhatsApp(
              '🚨 *Fleet Support Needed*\n'
              '• Partner: $driverName\n'
              '• Active Trip: ${widget.activeOrderId ?? "General Route"}\n'
              '• GPS Location: $gpsCoord\n'
              'Please assist immediately.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A))),
                    Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
