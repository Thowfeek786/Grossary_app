import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/auth_provider.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'My Addresses'),
      body: StreamBuilder<List<AddressModel>>(
        stream: UserRepository().getAddresses(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No Addresses Found',
              subtitle: 'Add a delivery address to place orders',
              actionLabel: 'Add Address',
              onAction: () => context.push('/profile/add-address'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final addr = addresses[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(addr.label == 'Home' ? Icons.home_rounded : Icons.business_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(addr.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('DEFAULT', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            ]
                          ],
                        ),
                        PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'set_default', child: Text('Set as Default')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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
                    Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(addr.phone, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(addr.fullAddress, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/profile/add-address'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}
