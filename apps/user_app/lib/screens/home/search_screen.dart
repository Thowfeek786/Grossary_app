import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

import '../../widgets/voice_search_dialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final List<String> _recentSearches = ['Fresh Apples', 'Pure Milk', 'Whole Bread', 'Onions', 'Eggs'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null && extra.containsKey('query')) {
        final q = extra['query'] as String;
        if (q.isNotEmpty) {
          _searchCtrl.text = q;
        }
      }
    });
  }

  void _onSearchChanged() {
    if (_searchCtrl.text.isEmpty) {
      context.read<ProductProvider>().search('');
    } else if (_searchCtrl.text.length >= 2) {
      context.read<ProductProvider>().search(_searchCtrl.text);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isTyping = _searchCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 48,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search fresh groceries...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6B7280)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              suffixIcon: isTyping
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      onPressed: () {
                        _searchCtrl.clear();
                        context.read<ProductProvider>().search('');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.mic_rounded, size: 20, color: Color(0xFF059669)),
                      onPressed: () => VoiceSearchDialog.show(
                        context,
                        onQueryRecognized: (query) {
                          _searchCtrl.text = query;
                        },
                      ),
                    ),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        ),
      ),
      body: SafeArea(
        child: !isTyping
            ? SingleChildScrollView(child: _buildDiscovery(context, provider))
            : provider.isSearching
                ? const _SearchShimmer()
                : provider.searchResults.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No items found',
                        subtitle: 'Try searching for something else like "Apples" or "Milk"',
                      )
                    : _buildResults(context, provider.searchResults),
      ),
    );
  }

  Widget _buildDiscovery(BuildContext context, ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              'Recent Searches 🔍',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.3),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((s) => GestureDetector(
                        onTap: () {
                          _searchCtrl.text = s;
                          context.read<ProductProvider>().search(s);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 15, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
          ],
          const Text(
            'Explore Popular Categories 🛒',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.categories.length > 6 ? 6 : provider.categories.length,
            itemBuilder: (ctx, i) {
              final cat = provider.categories[i];
              return GestureDetector(
                onTap: () => context.push('/home/category/${cat.id}', extra: {'name': cat.name}),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: cat.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Icon(Icons.category_rounded, size: 20, color: Color(0xFF059669)),
                              )
                            : const Icon(Icons.category_rounded, size: 20, color: Color(0xFF059669)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<ProductModel> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              children: [
                TextSpan(text: '${results.length} items', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                const TextSpan(text: ' found for '),
                TextSpan(text: '"${_searchCtrl.text}"', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669))),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: results.length,
            itemBuilder: (ctx, i) => ProductCard(
              product: results[i],
              onTap: () => context.push('/home/product/${results[i].id}'),
              onAddToCart: () => context.read<CartProvider>().addItem(results[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) => Shimmer.fromColors(
        baseColor: const Color(0xFFF3F4F6),
        highlightColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
