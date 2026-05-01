import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final List<String> _recentSearches = ['Tomatoes', 'Milk', 'Bread', 'Onions', 'Eggs'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce or just search
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 48,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search for fresh items...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.grey400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
              suffixIcon: isTyping 
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.grey400),
                    onPressed: () {
                      _searchCtrl.clear();
                      context.read<ProductProvider>().search('');
                    },
                  )
                : null,
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                        title: 'No results found',
                        subtitle: 'Try searching for something else like "Tomatoes" or "Milk"',
                      )
                    : _buildResults(context, provider.searchResults),
      ),
    );
  }

  Widget _buildDiscovery(BuildContext context, ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text('Recent Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recentSearches
                  .map((s) => GestureDetector(
                        onTap: () {
                          _searchCtrl.text = s;
                          context.read<ProductProvider>().search(s);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 16, color: AppColors.grey400),
                              const SizedBox(width: 8),
                              Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],
          const Text('Popular Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: provider.categories.length > 6 ? 6 : provider.categories.length,
            itemBuilder: (ctx, i) {
              final cat = provider.categories[i];
              return GestureDetector(
                onTap: () => context.push('/home/category/${cat.id}', extra: {'name': cat.name}),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                        child: cat.imageUrl != null 
                          ? Image.network(cat.imageUrl!, fit: BoxFit.cover) 
                          : const Icon(Icons.category_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              children: [
                TextSpan(text: '${results.length} results', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const TextSpan(text: ' found for '),
                TextSpan(text: '"${_searchCtrl.text}"', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.88,
              crossAxisSpacing: 12, mainAxisSpacing: 12,
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
        crossAxisCount: 2, childAspectRatio: 0.88, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) => Shimmer.fromColors(
        baseColor: AppColors.grey100,
        highlightColor: AppColors.white,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
