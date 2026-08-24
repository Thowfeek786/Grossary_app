import 'dart:async';
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

import '../../widgets/voice_search_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final topPadding = MediaQuery.of(context).padding.top;
    final searchBarHeight = 68.0;

    final bannerAreaHeight = 155.0;
    final categoryFullHeight = 150.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user),
          // Sticky Header: Search + Banners + Categories
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
                  const SizedBox(height: 12),
                  _FlashSaleSection(),
                  const SizedBox(height: 24),
                  _OrderAgainSection(),
                  const SizedBox(height: 24),
                  _FeaturedProductsSection(),
                  const SizedBox(height: 24),
                  _AllProductsSection(),
                  const SizedBox(height: 32),
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
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final name = user?.name.split(' ').first ?? 'Shopper';

    return SliverAppBar(
      backgroundColor: const Color(0xFF0F5132),
      expandedHeight: 168,
      floating: false,
      pinned: false,
      elevation: 0,
      leading: const SizedBox.shrink(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Dark Emerald Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B3C26),
                    Color(0xFF13653F),
                    Color(0xFF052B1B),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 38, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Location Pill Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (user != null) {
                              context.push('/profile/addresses');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: user == null
                                      ? const Text(
                                          'Select Delivery Location',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : StreamBuilder<List<AddressModel>>(
                                          stream: UserRepository().getAddresses(
                                            user.id,
                                          ),
                                          builder: (context, snapshot) {
                                            String locationText =
                                                'Select Delivery Location';
                                            if (snapshot.hasData &&
                                                snapshot.data!.isNotEmpty) {
                                              final def = snapshot.data!
                                                  .firstWhere(
                                                    (a) => a.isDefault,
                                                    orElse: () =>
                                                        snapshot.data!.first,
                                                  );
                                              locationText =
                                                  '${def.label.isNotEmpty ? def.label : "Home"} • ${def.city}';
                                            }
                                            return Text(
                                              locationText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Notifications Button
                      _CircularHeaderButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      const SizedBox(width: 10),
                      // User Avatar Profile Button
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: user?.photoUrl != null
                                ? Image.network(
                                    user!.photoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      user?.name.isNotEmpty == true
                                          ? user!.name[0].toUpperCase()
                                          : 'G',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting, $name 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<StoreSettingsModel>(
                              stream: SettingsRepository().getGlobalSettings(),
                              builder: (context, settingsSnap) {
                                final timingLabel = settingsSnap.data?.estimatedDeliveryTime.toUpperCase() ?? '20 TO 30 MINS';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF34D399,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        color: Color(0xFFFDE047),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'DELIVERY IN $timingLabel',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Smooth bottom curve transition into canvas
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Container(
                height: 24,
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

class _CircularHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Interactive Glass Search Bar
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Search "Fresh Milk, Apples, Bread..."',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Over 5,000+ items delivered in minutes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => VoiceSearchDialog.show(
                context,
                onQueryRecognized: (query) {
                  context.push('/home/search', extra: {'query': query});
                },
              ),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.primary,
                  size: 18,
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
// Premium Banner Carousel
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
                height: 125,
                autoPlay: true,
                autoPlayCurve: Curves.fastOutSlowIn,
                viewportFraction: 0.90,
                enlargeCenterPage: true,
                enlargeFactor: 0.12,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 600),
                onPageChanged: (index, reason) {
                  setState(() => _current = index);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _current == entry.key ? 18 : 6,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _current == entry.key
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
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
    return GestureDetector(
      onTap: () => context.go('/categories'),
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF047857)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🌿 FRESH DAILY HARVEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Up to 40% OFF Organic Veggies',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Shop Deals →',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Text('🥦', style: TextStyle(fontSize: 48)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final catId = banner.categoryId?.trim() ?? '';
        final prodId = banner.productId?.trim() ?? '';

        if (catId.isNotEmpty) {
          context.push(
            '/home/category/$catId?name=${Uri.encodeComponent(banner.title)}',
          );
        } else if (prodId.isNotEmpty) {
          context.push('/home/product/$prodId');
        } else {
          context.go('/categories');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
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
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.grey100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.grey200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.grey200,
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                      ),
                    ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        color: Color(0xFFEF4444),
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'FEATURED DEAL',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
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
// Category Chips Grid Section
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
                  title: 'Explore Categories',
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
                return const SizedBox(height: 86, child: AppLoader());
              }
              final cats = snapshot.data!;
              return SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
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

  static const List<List<Color>> _gradients = [
    [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
    [Color(0xFFFEF9C3), Color(0xFFFDE047)],
    [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
    [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
    [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
  ];

  static const List<Color> _accentColors = [
    Color(0xFF15803D),
    Color(0xFFA16207),
    Color(0xFF1D4ED8),
    Color(0xFFBE185D),
    Color(0xFF6B21A8),
  ];

  @override
  Widget build(BuildContext context) {
    final grad = _gradients[colorIndex % _gradients.length];
    final accent = _accentColors[colorIndex % _accentColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: grad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.category_rounded, color: accent, size: 28),
                    ),
                  )
                : Icon(Icons.category_rounded, color: accent, size: 28),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
// Flash Sale Section with Live Firestore Sync & Ticker
// ─────────────────────────────────────────────
class _FlashSaleSection extends StatefulWidget {
  @override
  State<_FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<_FlashSaleSection> {
  Timer? _timer;
  DateTime? _targetEndTime;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_targetEndTime != null) {
        final now = DateTime.now();
        final diff = _targetEndTime!.difference(now);
        setState(() {
          _remaining = diff.isNegative ? Duration.zero : diff;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Widget _buildTimeBadge(String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF9A3412),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FlashSaleModel?>(
      stream: FlashSaleRepository().getFlashSale(),
      builder: (context, flashSnapshot) {
        final sale = flashSnapshot.data;
        if (sale == null || !sale.isActive) {
          return const SizedBox.shrink();
        }

        // Update target end time
        if (_targetEndTime != sale.endTime) {
          _targetEndTime = sale.endTime;
          final diff = sale.endTime.difference(DateTime.now());
          _remaining = diff.isNegative ? Duration.zero : diff;
        }

        // Hide completely if timer has reached zero or expired
        if (_remaining.inSeconds <= 0 || sale.endTime.isBefore(DateTime.now())) {
          return const SizedBox.shrink();
        }

        final hours = _twoDigits(_remaining.inHours);
        final minutes = _twoDigits(_remaining.inMinutes.remainder(60));
        final seconds = _twoDigits(_remaining.inSeconds.remainder(60));

        return StreamBuilder<List<ProductModel>>(
          stream: ProductRepository().getProducts(featuredOnly: sale.productIds.isEmpty),
          builder: (context, prodSnapshot) {
            if (!prodSnapshot.hasData || prodSnapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final allProducts = prodSnapshot.data!;
            final products = sale.productIds.isNotEmpty
                ? allProducts.where((p) => sale.productIds.contains(p.id)).toList()
                : allProducts;

            final displayProducts = products.isNotEmpty ? products : allProducts;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF97316).withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.title.isNotEmpty ? sale.title : 'FLASH SALE ⚡',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF9A3412),
                              ),
                            ),
                            if (sale.discountPercentage > 0)
                              Text(
                                'Up to ${sale.discountPercentage.toStringAsFixed(0)}% OFF on items',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Styled Digits Countdown Ticker
                      Row(
                        children: [
                          _buildTimeBadge(hours, 'h'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A3412))),
                          ),
                          _buildTimeBadge(minutes, 'm'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A3412))),
                          ),
                          _buildTimeBadge(seconds, 's'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 205,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) => SizedBox(
                        width: 150,
                        child: ProductCard(
                          product: displayProducts[i],
                          onTap: () => context.push('/home/product/${displayProducts[i].id}'),
                          onAddToCart: () => context.read<CartProvider>().addItem(displayProducts[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Quick Order Again Section
// ─────────────────────────────────────────────
class _OrderAgainSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Order Again'),
        const SizedBox(height: 12),
        StreamBuilder<List<ProductModel>>(
          stream: ProductRepository().getProducts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final products = snapshot.data!.take(6).toList();
            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return GestureDetector(
                    onTap: () => context.push('/home/product/${p.id}'),
                    child: Container(
                      width: 210,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                p.imageUrls.isNotEmpty &&
                                    p.imageUrls.first.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: p.imageUrls.first,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 54,
                                      height: 54,
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.shopping_bag),
                                    ),
                                  )
                                : Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.shopping_bag),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  '₹${p.price.toStringAsFixed(0)} / ${p.unit}',
                                  style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    context.read<CartProvider>().addItem(p);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${p.name} added to cart!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF059669,
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '+ Reorder',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Featured Products Section
// ─────────────────────────────────────────────
class _FeaturedProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Featured Collection'),
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
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) => SizedBox(
                  width: 155,
                  child: ProductCard(
                    product: products[i],
                    onTap: () =>
                        context.push('/home/product/${products[i].id}'),
                    onAddToCart: () =>
                        context.read<CartProvider>().addItem(products[i]),
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
// All Products Grid
// ─────────────────────────────────────────────
class _AllProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'All Products'),
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
                childAspectRatio: 0.78,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
              ),
              itemCount: products.length,
              itemBuilder: (ctx, i) => ProductCard(
                product: products[i],
                onTap: () => context.push('/home/product/${products[i].id}'),
                onAddToCart: () =>
                    context.read<CartProvider>().addItem(products[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Master Header Delegate
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

  double get searchBarSection => 68.0;
  double get categoryStickHeight => 94.0;
  double get stickyTopPadding => topPadding;

  @override
  double get minExtent =>
      stickyTopPadding + searchBarSection + categoryStickHeight;

  @override
  double get maxExtent => searchBarSection + bannerHeight + categoryFullHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bannerOpacity = (1.0 - (shrinkOffset / bannerHeight)).clamp(0.0, 1.0);
    final categoryHeaderProgress = (shrinkOffset / (bannerHeight + 43)).clamp(
      0.0,
      1.0,
    );
    final titleOpacity = (1.0 - (categoryHeaderProgress * 2)).clamp(0.0, 1.0);
    final currentTopPadding =
        (shrinkOffset / 40).clamp(0.0, 1.0) * stickyTopPadding;
    final stickyY = (searchBarSection + bannerHeight - shrinkOffset).clamp(
      currentTopPadding + searchBarSection,
      maxExtent,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: currentTopPadding,
                left: 0,
                right: 0,
                height: searchBarSection,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: _SearchBar(onTap: () => context.push('/home/search')),
                ),
              ),
              if (bannerOpacity > 0.05)
                Positioned(
                  top: searchBarSection - shrinkOffset,
                  left: 0,
                  right: 0,
                  height: bannerHeight,
                  child: Opacity(
                    opacity: bannerOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _BannerSlider(),
                    ),
                  ),
                ),
              Positioned(
                top: stickyY,
                left: 0,
                right: 0,
                height: 150,
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
