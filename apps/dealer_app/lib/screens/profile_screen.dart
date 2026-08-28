import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/auth_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null && context.mounted) {
      await context.read<DealerAuthProvider>().updateProfileImage(File(img.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DealerAuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Vendor Profile Settings',
        backgroundColor: Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Emerald Profile Hero Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                  GestureDetector(
                    onTap: () => _pickImage(context),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'V',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B3C26), fontSize: 32),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                            child: auth.isLoading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.shopName ?? user.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isApproved ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: user.isApproved ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      user.isApproved ? 'VERIFIED STORE VENDOR' : 'PENDING VERIFICATION',
                      style: TextStyle(
                        color: user.isApproved ? const Color(0xFF34D399) : const Color(0xFFFCD34D),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Real Stats Row from Firestore
                  StreamBuilder<List<OrderModel>>(
                    stream: OrderRepository().getOrdersByDealer(user.id),
                    builder: (context, snapshot) {
                      final orders = snapshot.data ?? [];
                      final totalDeliveries = orders.where((o) => o.status == OrderStatus.delivered).length;
                      final rating = user.rating ?? 5.0;
                      final sales = orders.where((o) => o.status == OrderStatus.delivered).fold(0.0, (sum, o) => sum + o.total);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InfoCard(title: 'Orders', value: totalDeliveries.toString()),
                          const SizedBox(width: 12),
                          _InfoCard(title: 'Rating', value: rating.toStringAsFixed(1)),
                          const SizedBox(width: 12),
                          _InfoCard(title: 'Sales', value: '₹${(sales / 1000).toStringAsFixed(1)}K'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Profile Settings Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.store_rounded,
                    title: 'Store Details & Address',
                    subtitle: user.shopName ?? 'Configure store name and map location',
                    onTap: () => _showEditShopDialog(context, user, auth),
                  ),
                  _ProfileItem(
                    icon: Icons.local_shipping_rounded,
                    title: 'Delivery Radius & Fees',
                    subtitle: 'Set custom radius, delivery fee & free threshold',
                    onTap: () => context.push('/delivery-settings'),
                  ),
                  _ProfileItem(
                    icon: Icons.payments_rounded,
                    title: 'Payment & Payout Accounts',
                    subtitle: 'Request withdrawal to bank A/C or UPI VPA',
                    onTap: () => context.push('/dealer-payouts'),
                  ),
                  _ProfileItem(
                    icon: Icons.support_agent_rounded,
                    title: 'Vendor Partner Helpline',
                    subtitle: '24/7 store dispatch and support desk',
                    onTap: () => context.push('/help-support'),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutConfirmation(context, auth),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout Vendor Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: () => _showDeleteConfirmation(context, auth),
                      child: const Text('Delete Store Account', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, DealerAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
          ],
        ),
        content: const Text('Are you sure you want to log out of your vendor account?', style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DealerAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Store Account?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: const Text('This action is permanent and irreversible. Your store profile, inventory, and sales history will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.deleteAccount();
              if (auth.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!), backgroundColor: const Color(0xFFEF4444)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showEditShopDialog(BuildContext context, UserModel user, DealerAuthProvider auth) {
    final nameCtrl = TextEditingController(text: user.shopName);
    final addrCtrl = TextEditingController(text: user.shopAddress);
    double? selectedLat = user.latitude;
    double? selectedLng = user.longitude;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Store Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Shop Name',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'Shop Address',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF059669)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Store GPS Pin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              Text(
                                selectedLat != null ? '${selectedLat!.toStringAsFixed(4)}, ${selectedLng!.toStringAsFixed(4)}' : 'No GPS location set',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final LatLng? loc = await showDialog<LatLng>(
                              context: context,
                              builder: (c) => _LocationPickerModal(
                                initialLat: selectedLat ?? 12.9716,
                                initialLng: selectedLng ?? 77.5946,
                              ),
                            );
                            if (loc != null) {
                              setStateSB(() {
                                selectedLat = loc.latitude;
                                selectedLng = loc.longitude;
                              });
                              try {
                                List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  final addr = '${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}';
                                  addrCtrl.text = addr;
                                }
                              } catch (_) {}
                            }
                          },
                          child: const Text('Change Pin', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await auth.updateUserProfile(
                          shopName: nameCtrl.text.trim(),
                          shopAddress: addrCtrl.text.trim(),
                          latitude: selectedLat,
                          longitude: selectedLng,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
          Text(title, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileItem({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
          subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)) : null,
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _LocationPickerModal extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const _LocationPickerModal({required this.initialLat, required this.initialLng});

  @override
  State<_LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<_LocationPickerModal> {
  late LatLng _selectedPos;

  @override
  void initState() {
    super.initState();
    _selectedPos = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 450,
          child: Column(
            children: [
              AppBar(
                title: const Text('Pin Store Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _selectedPos, zoom: 15),
                  onTap: (pos) => setState(() => _selectedPos = pos),
                  markers: {
                    Marker(markerId: const MarkerId('store'), position: _selectedPos),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedPos),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                    child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
