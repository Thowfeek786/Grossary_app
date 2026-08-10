import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/auth_provider.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
            onPressed: () => context.pop(),
          ),
          title: const Text('My Addresses', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
        ),
        body: const Center(
          child: EmptyState(
            icon: Icons.location_off_rounded,
            title: 'Sign In Required',
            subtitle: 'Please sign in to view and manage your saved addresses.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Addresses', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<AddressModel>>(
        stream: UserRepository().getAddresses(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Icons.location_off_rounded,
              title: 'No Addresses Saved',
              subtitle: 'Add your home or office address for fast delivery.',
              actionLabel: 'Add New Address',
              onAction: () => context.push('/profile/add-address'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final addr = addresses[i];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: addr.isDefault ? const Color(0xFF10B981) : const Color(0xFFE5E7EB), width: addr.isDefault ? 1.8 : 1.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
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
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                addr.label.toLowerCase() == 'home' ? Icons.home_rounded : Icons.business_rounded,
                                color: const Color(0xFF059669),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(addr.label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ]
                          ],
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF6B7280), size: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'set_default', child: Text('Set as Default', style: TextStyle(fontWeight: FontWeight.w600))),
                            const PopupMenuItem(value: 'delete', child: Text('Delete Address', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600))),
                          ],
                          onSelected: (val) {
                            if (val == 'set_default') {
                              UserRepository().setDefaultAddress(user.id, addr.id);
                            } else if (val == 'delete') {
                              UserRepository().deleteAddress(user.id, addr.id);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text(addr.phone, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(addr.fullAddress, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/add-address'),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Add New Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
