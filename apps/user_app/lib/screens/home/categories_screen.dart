import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../widgets/voice_search_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Header (Search in minutes input + Mic)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/home/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Search in minutes',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => VoiceSearchDialog.show(
                                context,
                                onQueryRecognized: (query) {
                                  context.push('/home/search', extra: {'query': query});
                                },
                              ),
                              icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF4B5563), size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Sectioned Categories Body
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: CategoryRepository().getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _CategoryShimmer4Grid();
                  }
                  if (snapshot.hasError) {
                    return AppErrorWidget(message: snapshot.error.toString());
                  }
                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return const EmptyState(
                      icon: Icons.category_outlined,
                      title: 'No Categories Found',
                      subtitle: 'Check back later for fresh categories!',
                    );
                  }

                  // Group categories into sections (or default fallback sections)
                  final sections = _buildCategorySections(categories);

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: sections.length,
                    itemBuilder: (ctx, sectionIdx) {
                      final sec = sections[sectionIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: sec.items.length,
                            itemBuilder: (context, i) {
                              final item = sec.items[i];
                              return _CategoryTile4Col(
                                category: item,
                                onTap: () => context.push(
                                  '/home/category/${item.id}',
                                  extra: {'name': item.name},
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SectionData> _buildCategorySections(List<CategoryModel> categories) {
    // Standard section mappings as shown in screenshots
    final Map<String, List<CategoryModel>> groups = {
      'Grocery': [],
      'Snacks & drinks': [],
      'Beauty & personal care': [],
      'Household & lifestyle': [],
    };

    for (final cat in categories) {
      final n = cat.name.toLowerCase();
      if (n.contains('fruit') || n.contains('veg') || n.contains('rice') || n.contains('dal') || n.contains('oil') || n.contains('dairy') || n.contains('meat') || n.contains('egg') || n.contains('atta')) {
        groups['Grocery']!.add(cat);
      } else if (n.contains('snack') || n.contains('drink') || n.contains('choc') || n.contains('tea') || n.contains('coffee') || n.contains('biscuit') || n.contains('juice') || n.contains('sauce') || n.contains('ice')) {
        groups['Snacks & drinks']!.add(cat);
      } else if (n.contains('beauty') || n.contains('care') || n.contains('bath') || n.contains('hair') || n.contains('fragrance') || n.contains('hygiene')) {
        groups['Beauty & personal care']!.add(cat);
      } else {
        groups['Household & lifestyle']!.add(cat);
      }
    }

    final list = <_SectionData>[];
    groups.forEach((title, items) {
      if (items.isNotEmpty) {
        list.add(_SectionData(title: title, items: items));
      }
    });

    if (list.isEmpty) {
      list.add(_SectionData(title: 'All Categories', items: categories));
    }

    return list;
  }
}

class _SectionData {
  final String title;
  final List<CategoryModel> items;
  _SectionData({required this.title, required this.items});
}

class _CategoryTile4Col extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryTile4Col({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFFF3F4F6)),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(_getCategoryEmoji(category.name), style: const TextStyle(fontSize: 32)),
                      ),
                    )
                  : Center(
                      child: Text(_getCategoryEmoji(category.name), style: const TextStyle(fontSize: 32)),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('fruit')) return '🍎';
    if (n.contains('veg')) return '🥦';
    if (n.contains('rice') || n.contains('dal') || n.contains('atta')) return '🌾';
    if (n.contains('oil') || n.contains('ghee')) return '🪔';
    if (n.contains('dairy') || n.contains('milk') || n.contains('bread')) return '🍞';
    if (n.contains('snack') || n.contains('choc')) return '🍫';
    if (n.contains('drink') || n.contains('tea') || n.contains('coffee')) return '🧃';
    if (n.contains('meat') || n.contains('fish')) return '🍗';
    if (n.contains('beauty') || n.contains('care')) return '🧴';
    if (n.contains('clean') || n.contains('home')) return '🧼';
    return '🧺';
  }
}

class _CategoryShimmer4Grid extends StatelessWidget {
  const _CategoryShimmer4Grid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 140, height: 20, color: Colors.white),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.76,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: 8,
              itemBuilder: (_, __) => Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 50, height: 10, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
