import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
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
    if (img != null) {
      await context.read<DealerAuthProvider>().updateProfileImage(File(img.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<DealerAuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Vendor Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey200)),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(context),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50, backgroundColor: AppColors.primarySurface,
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'V', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 32)) : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: auth.isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                              : const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 16),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: user.isApproved ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      user.isApproved ? 'VERIFIED VENDOR' : 'PENDING APPROVAL',
                      style: TextStyle(color: user.isApproved ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Real Stats from Repository
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
                           const SizedBox(width: 16),
                           _InfoCard(title: 'Rating', value: rating.toStringAsFixed(1)),
                           const SizedBox(width: 16),
                           _InfoCard(title: 'Sales', value: '₹${(sales/1000).toStringAsFixed(1)}K'),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _ProfileItem(icon: Icons.store_rounded, title: 'Store Details', subtitle: user.shopName ?? 'Set shop details', onTap: () => _showEditShopDialog(context, user, auth)),
            _ProfileItem(icon: Icons.local_shipping_rounded, title: 'Delivery & Shipping Rates', subtitle: 'Set custom delivery fee & minimum free threshold', onTap: () => context.push('/delivery-settings')),
            _ProfileItem(icon: Icons.payments_rounded, title: 'Payment Payouts', onTap: (){}),
            _ProfileItem(icon: Icons.support_agent_rounded, title: 'Vendor Support', onTap: (){}),
            _ProfileItem(icon: Icons.help_outline_rounded, title: 'Partner Terms', onTap: (){}),
            const SizedBox(height: 32),
            AppButton(
              label: 'Logout Account', variant: AppButtonVariant.outlined,
              onTap: () => auth.logout(),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _showDeleteConfirmation(context, auth),
                child: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DealerAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is irreversible. All your shop details, product inventory, and sales history will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.deleteAccount();
              if (auth.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Store Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Store Location', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                selectedLat != null ? 'Location selected' : 'Mark store on map',
                                style: TextStyle(color: selectedLat != null ? AppColors.success : AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            LatLng? tempSelectedLoc = selectedLat != null ? LatLng(selectedLat!, selectedLng!) : null;
                            final loc = await Navigator.push<LatLng>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatefulBuilder(
                                  builder: (context, setStateMap) {
                                    return Scaffold(
                                      appBar: const CustomAppBar(title: 'Pick Store Location'),
                                      body: LocationPickerWidget(
                                        initialLocation: tempSelectedLoc,
                                        onLocationSelected: (l) {
                                          tempSelectedLoc = l;
                                        },
                                      ),
                                      bottomNavigationBar: Container(
                                        padding: const EdgeInsets.all(20),
                                        child: AppButton(
                                          label: 'Confirm Location',
                                          onTap: () {
                                            Navigator.pop(context, tempSelectedLoc); 
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              ),
                            );
                            if (loc != null) {
                              setStateSB(() {
                                selectedLat = loc.latitude;
                                selectedLng = loc.longitude;
                              });
                              try {
                                final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  final parts = [p.street, p.subLocality, p.locality, p.administrativeArea, p.postalCode].where((e) => e != null && e.isNotEmpty).toList();
                                  if (parts.isNotEmpty) {
                                    setStateSB(() {
                                      addrCtrl.text = parts.join(', ');
                                    });
                                  }
                                }
                              } catch (_) {}
                            }
                          },
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Save Changes',
                    onTap: () async {
                      await auth.updateUserProfile(
                         shopName: nameCtrl.text.trim(),
                         shopAddress: addrCtrl.text.trim(),
                         latitude: selectedLat,
                         longitude: selectedLng,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }
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
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
