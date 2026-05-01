import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final topPadding = MediaQuery.of(context).padding.top;
    final searchBarHeight = 64.0;

    final bannerAreaHeight = 210.0; // Slider height + spacing
    final categoryFullHeight = 145.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user),
          // Master Sticky Header: Search + Banner + Categories
          SliverPersistentHeader(
            pinned: true,
            delegate: _MasterHeaderDelegate(
              topPadding: topPadding,
              searchBarHeight: searchBarHeight,
              bannerHeight: bannerAreaHeight,
              categoryFullHeight: categoryFullHeight,
              user: user,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _FeaturedProductsSection(),
                   const SizedBox(height: 24),
                   _AllProductsSection(),
                   const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserModel? user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final subGreeting = hour < 12
        ? '🌤  Rise & shine!'
        : (hour < 17 ? '☀  Have a great day!' : '🌙  Good to see you!');

    return SliverAppBar(
      backgroundColor: AppColors.primary,
      expandedHeight: 154,
      floating: false,
      pinned: false,
      elevation: 0,
      leading: const SizedBox.shrink(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Gradient bg
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -40, right: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 34, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            if (user != null) context.push('/profile/addresses');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF86EFAC),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: user == null
                                      ? const Text('Add Location', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
                                      : StreamBuilder<List<AddressModel>>(
                                          stream: UserRepository().getAddresses(user.id),
                                          builder: (context, snapshot) {
                                            String locationText = 'Add Location';
                                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                              final def = snapshot.data!.firstWhere((a) => a.isDefault, orElse: () => snapshot.data!.first);
                                              locationText = '${def.label.isNotEmpty ? def.label : "Address"} • ${def.city}';
                                            }
                                            return Text(
                                              locationText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white60, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Notification
                      _CircularAction(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF86EFAC), Color(0xFF22C55E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                          ),
                          child: ClipOval(
                            child: user?.photoUrl != null
                                ? Image.network(user!.photoUrl!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'G',
                                      style: const TextStyle(
                                        color: Color(0xFF14532D),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subGreeting,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Rounded bottom edge into AppColors.background
            Positioned(
              bottom: -1, left: 0, right: 0,
              child: Container(
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Circular action button
// ─────────────────────────────────────────────
class _CircularAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDC9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1B4332).withOpacity(0.08)),
        ),
        child: Icon(icon, color: const Color(0xFF1B4332), size: 19),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Find fresh groceries...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Search across 5000+ items',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.primary, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Banner slider
// ─────────────────────────────────────────────
class _BannerSlider extends StatefulWidget {
  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BannerModel>>(
      stream: BannerRepository().getBanners(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _PlaceholderBanner();
        }
        final banners = snapshot.data!;

        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: banners.length,
              itemBuilder: (ctx, i, _) => _BannerCard(banner: banners[i]),
              options: CarouselOptions(
                height: 165,
                autoPlay: true,
                viewportFraction: 0.92,
                enlargeCenterPage: true,
                enlargeFactor: 0.22,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) {
                  setState(() => _current = index);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _current == entry.key ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _current == entry.key
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _PlaceholderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Text(
                          '🌿  Fresh Deals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Get Fresh\nGroceries Daily!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Up to 40% OFF this week',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Shop Now →',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🥗', style: TextStyle(fontSize: 64)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    String sanitizeUrl(String url) {
      if (url.contains('unsplash.com') && !url.contains('fm=')) {
        return url.contains('?') ? '$url&fm=jpg' : '$url?fm=jpg';
      }
      return url;
    }

    return GestureDetector(
      onTap: () {
        if (banner.categoryId != null) {
          context.push(
            '/home/category/${banner.categoryId}?name=${Uri.encodeComponent(banner.title)}',
          );
        } else if (banner.productId != null) {
          context.push('/home/product/${banner.productId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (banner.imageUrl.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: sanitizeUrl(banner.imageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.grey100,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.grey200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: AppColors.grey200,
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: AppColors.error, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'PROMO',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────
// Categories section
// ─────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  final bool showTitle;
  final double titleOpacity;
  final bool isSticky;

  const _CategoriesSection({
    this.showTitle = true,
    this.titleOpacity = 1.0,
    this.isSticky = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle && !isSticky) ...[
            Opacity(
              opacity: titleOpacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SectionHeader(
                  title: 'Categories',
                  actionLabel: 'See all',
                  onAction: () => context.go('/categories'),
                ),
              ),
            ),
            SizedBox(height: 8 * titleOpacity),
          ],
          StreamBuilder<List<CategoryModel>>(
            stream: CategoryRepository().getCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 82, child: AppLoader());
              }
              final cats = snapshot.data!;
              return SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) => _CategoryChip(
                    category: cats[i],
                    colorIndex: i,
                    onTap: () => context.push(
                      '/home/category/${cats[i].id}',
                      extra: {'name': cats[i].name},
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final int colorIndex;
  const _CategoryChip({
    required this.category,
    required this.onTap,
    required this.colorIndex,
  });

  static const List<Color> _bgColors = [
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFEDE7F6),
    Color(0xFFFFF3E0),
  ];
  static const List<Color> _iconColors = [
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF4527A0),
    Color(0xFFE65100),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[colorIndex % _bgColors.length];
    final ic = _iconColors[colorIndex % _iconColors.length];

    String sanitizeUrl(String url) {
      if (url.contains('unsplash.com') && !url.contains('fm=')) {
        return url.contains('?') ? '$url&fm=jpg' : '$url?fm=jpg';
      }
      return url;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ic.withOpacity(0.18)),
            ),
            child: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: CachedNetworkImage(
                      imageUrl: sanitizeUrl(category.imageUrl!),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: bg.withOpacity(0.3),
                        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey))),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.category_rounded, color: ic, size: 26),
                    ),
                  )
                : Icon(Icons.category_rounded, color: ic, size: 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Featured products
// ─────────────────────────────────────────────
class _FeaturedProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: SectionHeader(title: '⚡ Featured'),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<ProductModel>>(
          stream: ProductRepository().getProducts(featuredOnly: true),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 195, child: AppLoader());
            }
            if (snapshot.data!.isEmpty) return const SizedBox.shrink();
            final products = snapshot.data!;
            return SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) => SizedBox(
                  width: 155,
                  child: ProductCard(
                    product: products[i],
                    onTap: () => context.push('/home/product/${products[i].id}'),
                    onAddToCart: () => context.read<CartProvider>().addItem(products[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// All products grid
// ─────────────────────────────────────────────
class _AllProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '🛍  All Products'),
        const SizedBox(height: 16),
        StreamBuilder<List<ProductModel>>(
          stream: ProductRepository().getProducts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 200, child: AppLoader());
            }
            if (snapshot.data!.isEmpty) {
              return const EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'No products yet',
                subtitle: 'Check back soon!',
              );
            }
            final products = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.79,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
              ),
              itemCount: products.length,
              itemBuilder: (ctx, i) => ProductCard(
                product: products[i],
                onTap: () => context.push('/home/product/${products[i].id}'),
                onAddToCart: () => context.read<CartProvider>().addItem(products[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sliver persistent header delegate
// ─────────────────────────────────────────────
class _MasterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final double searchBarHeight;
  final double bannerHeight;
  final double categoryFullHeight;
  final UserModel? user;

  _MasterHeaderDelegate({
    required this.topPadding,
    required this.searchBarHeight,
    required this.bannerHeight,
    required this.categoryFullHeight,
    this.user,
  });

  double get searchBarSection => 68.0; // Compact search section
  double get categoryStickHeight => 94.0;
  double get stickyTopPadding => topPadding;

  @override
  double get minExtent => stickyTopPadding + searchBarSection + categoryStickHeight;

  @override
  double get maxExtent => searchBarSection + bannerHeight + categoryFullHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bannerOpacity = (1.0 - (shrinkOffset / bannerHeight)).clamp(0.0, 1.0);
    // categoryHeaderProgress reaches 1.0 when banner and categories title are scrolled away
    final categoryHeaderProgress = (shrinkOffset / (bannerHeight + 43)).clamp(0.0, 1.0);
    final titleOpacity = (1.0 - (categoryHeaderProgress * 2)).clamp(0.0, 1.0);
    final currentTopPadding = (shrinkOffset / 40).clamp(0.0, 1.0) * stickyTopPadding;
    final stickyY = (searchBarSection + bannerHeight - shrinkOffset).clamp(currentTopPadding + searchBarSection, maxExtent);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // 1. Search Bar (Moves down for status bar when pinned)
              Positioned(
                top: currentTopPadding, left: 0, right: 0,
                height: searchBarSection,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: _SearchBar(onTap: () => context.push('/home/search')),
                ),
              ),
              
              // 2. Banner (Moves up and fades)
              if (bannerOpacity > 0.05)
                Positioned(
                  top: searchBarSection - shrinkOffset,
                  left: 0, right: 0,
                  height: bannerHeight,
                  child: Opacity(
                    opacity: bannerOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _BannerSlider(),
                    ),
                  ),
                ),

              // 3. Categories (Slides up to Search Bar)
              Positioned(
                top: stickyY,
                left: 0, right: 0,
                height: 145,
                child: _CategoriesSection(
                   showTitle: true,
                   titleOpacity: titleOpacity,
                   isSticky: categoryHeaderProgress > 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_MasterHeaderDelegate old) => true;
}