import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:geocoding/geocoding.dart';

class StoreGeofenceScreen extends StatefulWidget {
  const StoreGeofenceScreen({super.key});

  @override
  State<StoreGeofenceScreen> createState() => _StoreGeofenceScreenState();
}

class _StoreGeofenceScreenState extends State<StoreGeofenceScreen> {
  final _searchAddressCtrl = TextEditingController();

  @override
  void dispose() {
    _searchAddressCtrl.dispose();
    super.dispose();
  }

  void _showEditStoreLocationModal(BuildContext context, UserModel dealer) {
    final latCtrl = TextEditingController(text: (dealer.latitude ?? 12.9716).toStringAsFixed(5));
    final lngCtrl = TextEditingController(text: (dealer.longitude ?? 77.5946).toStringAsFixed(5));
    final addressCtrl = TextEditingController(text: dealer.shopAddress ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Pin: ${dealer.shopName ?? dealer.name}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Store Physical Address',
                  controller: addressCtrl,
                  hint: 'e.g. 12th Main, Indiranagar, Bangalore',
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Latitude',
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Longitude',
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final addr = addressCtrl.text.trim();
                      if (addr.isEmpty) return;
                      try {
                        final locations = await locationFromAddress(addr);
                        if (locations.isNotEmpty) {
                          setModalState(() {
                            latCtrl.text = locations.first.latitude.toStringAsFixed(5);
                            lngCtrl.text = locations.first.longitude.toStringAsFixed(5);
                          });
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Could not geocode address automatically'), backgroundColor: Color(0xFFEF4444)),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFF059669)),
                    label: const Text('Auto-fetch Coordinates from Address', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final lat = double.tryParse(latCtrl.text.trim());
                            final lng = double.tryParse(lngCtrl.text.trim());
                            if (lat == null || lng == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Invalid GPS coordinates'), backgroundColor: Color(0xFFEF4444)),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            try {
                              await UserRepository().updateUser(
                                dealer.copyWith(
                                  shopAddress: addressCtrl.text.trim(),
                                  latitude: lat,
                                  longitude: lng,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('🎉 Store location pin updated!'), backgroundColor: Color(0xFF059669)),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Coordinates', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Store Zones & Geofencing',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<StoreSettingsModel>(
        stream: SettingsRepository().getGlobalSettings(),
        builder: (context, settingsSnap) {
          final settings = settingsSnap.data ?? const StoreSettingsModel(id: 'global');
          final maxRadius = settings.maxDeliveryRadiusKm;

          return StreamBuilder<List<UserModel>>(
            stream: UserRepository().getUsersByRole(UserRole.dealer),
            builder: (context, dealerSnap) {
              if (dealerSnap.connectionState == ConnectionState.waiting) {
                return const AppLoader();
              }

              final dealers = dealerSnap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Geofence Coverage Visualizer
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.radar_rounded, color: Color(0xFF34D399), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Platform Service Coverage Zone',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                    Text(
                                      'Active delivery boundary from store GPS pins',
                                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Visual Radar Circle Container
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1329),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Ring
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3), width: 1.5),
                                  ),
                                ),
                                // Inner Ring
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.5),
                                  ),
                                ),
                                // Center Store Pin
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 12,
                                  child: Text(
                                    'Max Radius: ${maxRadius.toStringAsFixed(0)} KM',
                                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Active Dark Stores List & Location Pins
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Store Delivery Coordinates',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${dealers.length} Active Stores',
                            style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (dealers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text('No vendor dark stores registered yet.', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dealers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final d = dealers[idx];
                          final lat = d.latitude ?? 12.9716;
                          final lng = d.longitude ?? 77.5946;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF059669), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.shopName ?? d.name,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        d.shopAddress?.isNotEmpty == true ? d.shopAddress! : 'No address set',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} • Service: ${maxRadius.toStringAsFixed(0)} KM',
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669), fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF3B82F6), size: 22),
                                  tooltip: 'Adjust GPS Pin',
                                  onPressed: () => _showEditStoreLocationModal(context, d),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
