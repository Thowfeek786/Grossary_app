import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  String _selectedVehicle = 'Electric Scooter ⚡';
  final _dlController = TextEditingController();
  final _rcController = TextEditingController();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _vehicles = [
    {'type': 'Electric Scooter ⚡', 'icon': Icons.electric_scooter_rounded, 'badge': 'Eco Preferred'},
    {'type': 'Motorbike 🛵', 'icon': Icons.two_wheeler_rounded, 'badge': 'Fast Delivery'},
    {'type': 'Bicycle 🚲', 'icon': Icons.pedal_bike_rounded, 'badge': 'Short Distance'},
    {'type': 'Delivery Van 🚐', 'icon': Icons.airport_shuttle_rounded, 'badge': 'Bulk Transport'},
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<DeliveryAuthProvider>().user;
    if (user != null) {
      if (user.vehicleType != null && user.vehicleType!.isNotEmpty) {
        _selectedVehicle = user.vehicleType!;
      }
      _dlController.text = user.dlNumber ?? '';
      _rcController.text = user.rcNumber ?? '';
    }
  }

  @override
  void dispose() {
    _dlController.dispose();
    _rcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DeliveryAuthProvider>();
    final user = auth.user;
    final status = user?.docVerificationStatus ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Vehicle & Documents',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Banner
            _buildStatusBanner(status),
            const SizedBox(height: 24),

            // Vehicle Type Selector Header
            const Text('Active Delivery Vehicle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            ..._vehicles.map((v) {
              final isSelected = _selectedVehicle == v['type'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedVehicle = v['type'] as String),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF059669).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(v['icon'] as IconData, color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B), size: 22),
                  ),
                  title: Text(v['type'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  subtitle: Text(v['badge'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  trailing: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Document Details Section
            const Text('Document Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            AppTextField(
              controller: _dlController,
              label: 'Driving License (DL) Number',
              hint: 'e.g. DL-TN38-2024-89712',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 14),

            AppTextField(
              controller: _rcController,
              label: 'Vehicle Registration (RC) Number',
              hint: 'e.g. TN-38-BZ-4921',
              prefixIcon: Icons.description_outlined,
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveVehicleAndDocs(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Save & Submit for Verification', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bg;
    Color border;
    Color iconColor;
    String title;
    String subtitle;

    if (status == 'approved') {
      bg = const Color(0xFF10B981).withValues(alpha: 0.1);
      border = const Color(0xFF6EE7B7);
      iconColor = const Color(0xFF059669);
      title = 'Documents Verified ✓';
      subtitle = 'Your vehicle and driver documents are approved for delivery duty.';
    } else if (status == 'rejected') {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
      border = const Color(0xFFFCA5A5);
      iconColor = const Color(0xFFEF4444);
      title = 'Verification Action Needed ⚠️';
      subtitle = 'Your document submission was rejected by Admin. Please update your details.';
    } else {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
      border = const Color(0xFFFCD34D);
      iconColor = const Color(0xFFD97706);
      title = 'Verification Pending ⏳';
      subtitle = 'Submitted documents are under review by the Admin team.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(status == 'approved' ? Icons.verified_user_rounded : Icons.pending_actions_rounded, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: iconColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVehicleAndDocs(dynamic user) async {
    final dl = _dlController.text.trim();
    final rc = _rcController.text.trim();

    if (dl.isEmpty || rc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in both DL and RC numbers'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (user != null) {
        final updatedUser = user.copyWith(
          vehicleType: _selectedVehicle,
          dlNumber: dl,
          rcNumber: rc,
          docVerificationStatus: 'pending',
        );

        await UserRepository().updateUser(updatedUser);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Vehicle set to $_selectedVehicle & documents submitted for Admin review!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save documents: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
