import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';

import 'add_edit_banner_screen.dart';

class BannerManagementScreen extends StatelessWidget {
  const BannerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final management = context.watch<AdminManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Banners & Promos',
      ),
      body: StreamBuilder<List<BannerModel>>(
        stream: management.getBanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          final banners = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final b = banners[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(b.imageUrl), fit: BoxFit.cover),
                ),
                child: Container(
                   decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)]),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Text(b.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                                  if (b.subtitle != null) Text(b.subtitle!, style: const TextStyle(color: AppColors.white, fontSize: 13)),
                               ],
                            ),
                          ),
                          Row(
                            children: [
                               IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.white), onPressed: () {
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditBannerScreen(banner: b)));
                               }),
                               IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), onPressed: () => management.deleteBanner(b.id)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBannerScreen()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}
