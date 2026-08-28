import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class WaterCanScreen extends StatefulWidget {
  const WaterCanScreen({super.key});

  @override
  State<WaterCanScreen> createState() => _WaterCanScreenState();
}

class _WaterCanScreenState extends State<WaterCanScreen> {
  final WaterCanRepository _waterCanRepo = WaterCanRepository();
  final WaterAssetRepository _assetRepo = WaterAssetRepository();
  final WaterSubscriptionRepository _subRepo = WaterSubscriptionRepository();
  UserModel? _selectedDealer;

  void _showCanOptionSheet({
    required BuildContext context,
    required bool initialHasEmptyCan,
    required Map<String, dynamic> config,
    required UserModel? dealer,
    ProductModel? refillProd,
    ProductModel? newCanProd,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CanOptionBottomSheet(
        initialHasEmptyCan: initialHasEmptyCan,
        config: config,
        dealer: dealer,
        refillProd: refillProd,
        newCanProd: newCanProd,
      ),
    );
  }

  void _showSubscriptionSetupModal(BuildContext context, UserModel? dealer, double refillPrice) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to set up automated recurring water delivery'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      context.push('/login');
      return;
    }

    SubscriptionCadence selectedCadence = SubscriptionCadence.alternateDays;
    int quantity = 1;
    String selectedSlot = '5:30 AM - 7:30 AM (Silent Doorstep Drop)';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final discountedPrice = refillPrice * 0.90; // 10% subscription discount

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.repeat_rounded, color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Hydration Subscription',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Save 10% on every refill • Pause anytime',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cadence Selector
                const Text(
                  'Delivery Frequency',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SubscriptionCadence.values.where((c) => c != SubscriptionCadence.customDays).map((cadence) {
                    final isSel = selectedCadence == cadence;
                    return ChoiceChip(
                      label: Text(cadence.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      selected: isSel,
                      selectedColor: const Color(0xFF059669).withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: isSel ? const Color(0xFF059669) : const Color(0xFF64748B)),
                      onSelected: (_) => setModalState(() => selectedCadence = cadence),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Preferred Slot
                const Text(
                  'Doorstep Delivery Slot',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSlot,
                      items: [
                        '5:30 AM - 7:30 AM (Silent Doorstep Drop)',
                        '7:00 AM - 9:00 AM (Morning Slot)',
                        '5:00 PM - 7:00 PM (Evening Slot)',
                      ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSlot = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quantity & Pricing Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subscription Price', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                          Text(
                            '₹${(discountedPrice * quantity).toStringAsFixed(0)} / delivery',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                            ),
                            Text('$quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => setModalState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            final nextDate = _subRepo.calculateNextDelivery(selectedCadence);

                            final newSub = WaterSubscriptionModel(
                              id: '',
                              userId: user.id,
                              userName: user.name,
                              userPhone: user.phone,
                              deliveryAddress: 'Saved Delivery Address',
                              dealerId: dealer?.id ?? 'default-dealer',
                              dealerName: dealer?.shopName ?? dealer?.name ?? 'GroceryGo Dark Store',
                              quantityPerDelivery: quantity,
                              cadence: selectedCadence,
                              timeSlot: selectedSlot,
                              pricePerCan: discountedPrice,
                              nextScheduledDelivery: nextDate,
                            );

                            try {
                              await _subRepo.createSubscription(newSub);
                              if (ctx.mounted) Navigator.pop(modalCtx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Water Subscription activated! Deliveries will arrive on schedule.'),
                                    backgroundColor: Color(0xFF059669),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Start Subscription ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDealerSelector(BuildContext context, List<UserModel> dealers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Water Supplier / Dark Store',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose your local partner delivering water cans to your area',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ...dealers.map((d) {
              final isSelected = _selectedDealer?.id == d.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () {
                    setState(() => _selectedDealer = d);
                    Navigator.pop(ctx);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  tileColor: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    d.shopName ?? d.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  subtitle: Text(
                    d.shopAddress ?? 'Local partner store',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF059669))
                      : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return StreamBuilder<List<UserModel>>(
      stream: _waterCanRepo.getAvailableWaterDealers(),
      builder: (context, dealersSnapshot) {
        final dealers = dealersSnapshot.data ?? [];

        // Check if cart already has an active dealer
        if (cart.items.isNotEmpty && _selectedDealer == null) {
          final cartDealerId = cart.items.first.dealerId;
          final match = dealers.where((d) => d.id == cartDealerId).firstOrNull;
          if (match != null) {
            _selectedDealer = match;
          }
        }

        // Default to first dealer if not selected
        if (_selectedDealer == null && dealers.isNotEmpty) {
          _selectedDealer = dealers.first;
        }

        final currentDealerId = _selectedDealer?.id ?? '';

        return StreamBuilder<List<ProductModel>>(
          stream: currentDealerId.isNotEmpty
              ? _waterCanRepo.getDealerWaterProducts(currentDealerId)
              : Stream.value(<ProductModel>[]),
          builder: (context, productsSnapshot) {
            final dealerProducts = productsSnapshot.data ?? [];

            final refillProd = dealerProducts
                .where((p) =>
                    p.name.toLowerCase().contains('refill') ||
                    (p.name.toLowerCase().contains('20l') &&
                        !p.name.toLowerCase().contains('new')))
                .firstOrNull;

            final newCanProd = dealerProducts
                .where((p) =>
                    p.name.toLowerCase().contains('new') &&
                    (p.name.toLowerCase().contains('can') ||
                        p.name.toLowerCase().contains('20l')))
                .firstOrNull;

            final bottle1LProd = dealerProducts
                .where((p) =>
                    p.name.toLowerCase().contains('1l') &&
                    !p.name.toLowerCase().contains('pack'))
                .firstOrNull;

            final bottlePackProd = dealerProducts
                .where((p) =>
                    p.name.toLowerCase().contains('pack of 6') ||
                    (p.name.toLowerCase().contains('1l') &&
                        p.name.toLowerCase().contains('pack')))
                .firstOrNull;

            return StreamBuilder<Map<String, dynamic>>(
              stream: _waterCanRepo.getPlatformCanConfig(),
              builder: (context, snapshot) {
                final platformConfig = snapshot.data ?? {
                  'refillPrice': 50.0,
                  'refillOriginalPrice': 80.0,
                  'exchangeDiscount': 30.0,
                  'newCanPrice': 150.0,
                  'refundableDeposit': 100.0,
                  'bottlePackPrice': 90.0,
                };

                final refillPrice = refillProd?.effectivePrice ?? (platformConfig['refillPrice'] as double);
                final refillOriginalPrice = refillProd?.price ?? (platformConfig['refillOriginalPrice'] as double);
                final exchangeDiscount = platformConfig['exchangeDiscount'] as double;
                final newCanPrice = newCanProd?.effectivePrice ?? (platformConfig['newCanPrice'] as double);
                final refundableDeposit = platformConfig['refundableDeposit'] as double;
                final bottlePackPrice = bottlePackProd?.effectivePrice ?? (platformConfig['bottlePackPrice'] as double);
                final bottle1LPrice = bottle1LProd?.effectivePrice ?? ((platformConfig['bottle1LPrice'] as num?)?.toDouble() ?? 20.0);

                final refillInStock = refillProd == null || refillProd.stockQuantity > 0;
                final newCanInStock = newCanProd == null || newCanProd.stockQuantity > 0;
                final bottlePackInStock = bottlePackProd == null || bottlePackProd.stockQuantity > 0;
                final bottle1LInStock = bottle1LProd == null || bottle1LProd.stockQuantity > 0;

                final activeConfig = {
                  'refillPrice': refillPrice,
                  'refillOriginalPrice': refillOriginalPrice,
                  'exchangeDiscount': exchangeDiscount,
                  'newCanPrice': newCanPrice,
                  'refundableDeposit': refundableDeposit,
                  'bottlePackPrice': bottlePackPrice,
                  'bottle1LPrice': bottle1LPrice,
                };

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    title: const Text(
                      'Water & Beverages',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A)),
                            if (cart.itemCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () => context.go('/cart'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dealer Fulfillment Selector Banner
                        if (dealers.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => _showDealerSelector(context, dealers),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFDCFCE7)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fulfilling Partner Store:',
                                          style: TextStyle(fontSize: 10.5, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          _selectedDealer?.shopName ?? _selectedDealer?.name ?? 'GroceryGo Dark Store',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF059669), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Water Quality & Lab Purity Badge
                        StreamBuilder<WaterQualityModel?>(
                          stream: currentDealerId.isNotEmpty
                              ? _assetRepo.getLatestQualityLog(currentDealerId)
                              : Stream.value(null),
                          builder: (context, qualSnap) {
                            return WaterPurityBadge(quality: qualSnap.data);
                          },
                        ),
                        const SizedBox(height: 14),

                        // Top Promotional Hero Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF047857).withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        '💧 100% Pure & Hygienic',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Pure Water, Healthy Life',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '20L Water Can Delivery to your doorstep',
                                      style: TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Smart Subscription Banner
                        StreamBuilder<StoreSettingsModel>(
                          stream: SettingsRepository().getGlobalSettings(),
                          builder: (context, setSnap) {
                            final isSubEnabled = setSnap.data?.isWaterSubscriptionEnabled ?? true;
                            if (!isSubEnabled) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.repeat_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Automate with Subscription',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Daily / Alternate days • Save 10%',
                                          style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 11.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _showSubscriptionSetupModal(context, _selectedDealer, refillPrice),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1E3A8A),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Subscribe', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Section 1: Water Cans
                        const Text(
                          'Water Cans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Item 1: 20L Water Can (Refill)
                        _WaterProductCard(
                          title: '20L Drinking Water Can (Refill)',
                          subtitle: 'Exchange your empty can & get ₹${exchangeDiscount.toStringAsFixed(0)} off',
                          price: refillPrice,
                          originalPrice: refillOriginalPrice,
                          badgeText: 'Exchange Offer',
                          badgeColor: const Color(0xFF059669),
                          icon: Icons.sync_rounded,
                          imageAsset: 'assets/images/water_can_20l.png',
                          inStock: refillInStock,
                          onAdd: () => _showCanOptionSheet(
                            context: context,
                            initialHasEmptyCan: true,
                            config: activeConfig,
                            dealer: _selectedDealer,
                            refillProd: refillProd,
                            newCanProd: newCanProd,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Item 2: 20L Water Can (New Can)
                        _WaterProductCard(
                          title: '20L Drinking Water Can (New Can)',
                          subtitle: 'Includes new can (₹${refundableDeposit.toStringAsFixed(0)} refundable deposit)',
                          price: newCanPrice,
                          badgeText: 'New Can',
                          badgeColor: const Color(0xFF2563EB),
                          icon: Icons.add_circle_outline_rounded,
                          imageAsset: 'assets/images/water_can_20l.png',
                          inStock: newCanInStock,
                          onAdd: () => _showCanOptionSheet(
                            context: context,
                            initialHasEmptyCan: false,
                            config: activeConfig,
                            dealer: _selectedDealer,
                            refillProd: refillProd,
                            newCanProd: newCanProd,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Section 2: Water Bottles
                        const Text(
                          'Water Bottles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Item 3: 1L Water Bottle (Single)
                        _WaterProductCard(
                          title: '1L Mineral Water Bottle',
                          subtitle: 'Single 1L bottle (Pure Mineral Water)',
                          price: bottle1LPrice,
                          icon: Icons.local_drink_rounded,
                          inStock: bottle1LInStock,
                          onAdd: () {
                            final dealerId = _selectedDealer?.id ?? 'default-dealer';
                            final dealerName = _selectedDealer?.shopName ?? _selectedDealer?.name;

                            cart.addItemById(CartItemModel(
                              productId: bottle1LProd?.id ?? 'water-bottle-1l-single',
                              productName: '1L Mineral Water Bottle',
                              price: bottle1LPrice,
                              unit: 'bottle',
                              quantity: 1,
                              dealerId: dealerId,
                              dealerName: dealerName,
                              isWaterCan: false,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('1L Mineral Water Bottle added to cart!'),
                                backgroundColor: Color(0xFF059669),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Item 4: 1L Water Bottle (Pack of 6)
                        _WaterProductCard(
                          title: '1L Water Bottle (Pack of 6)',
                          subtitle: 'Pack of 6 bottles (Pure Mineral Water)',
                          price: bottlePackPrice,
                          icon: Icons.local_drink_rounded,
                          inStock: bottlePackInStock,
                          onAdd: () {
                            final dealerId = _selectedDealer?.id ?? 'default-dealer';
                            final dealerName = _selectedDealer?.shopName ?? _selectedDealer?.name;

                            cart.addItemById(CartItemModel(
                              productId: bottlePackProd?.id ?? 'water-bottle-1l-pack6',
                              productName: '1L Water Bottle (Pack of 6)',
                              price: bottlePackPrice,
                              unit: 'pack',
                              quantity: 1,
                              dealerId: dealerId,
                              dealerName: dealerName,
                              isWaterCan: false,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('1L Water Bottle (Pack of 6) added to cart!'),
                                backgroundColor: Color(0xFF059669),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Link to "My Cans" Ledger
                        GestureDetector(
                          onTap: () => context.push('/profile/my-cans'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 22),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'My Can Balance & Escrow Ledger',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'View serialized containers & instant deposit refunds',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Water Product Card
// ─────────────────────────────────────────────
class _WaterProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double price;
  final double? originalPrice;
  final String? badgeText;
  final Color? badgeColor;
  final IconData icon;
  final String? imageAsset;
  final bool inStock;
  final VoidCallback onAdd;

  const _WaterProductCard({
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    this.badgeText,
    this.badgeColor,
    required this.icon,
    this.imageAsset,
    this.inStock = true,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Graphic Image Container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(imageAsset!, width: 72, height: 72, fit: BoxFit.cover),
                  )
                : Icon(icon, color: const Color(0xFF059669), size: 36),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? const Color(0xFF059669)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        color: badgeColor ?? const Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                    if (originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${originalPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Add Button
          ElevatedButton(
            onPressed: inStock ? onAdd : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: inStock ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              inStock ? 'Add' : 'Out of Stock',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Can Option Bottom Sheet (Exchange vs New Can)
// ─────────────────────────────────────────────
class _CanOptionBottomSheet extends StatefulWidget {
  final bool initialHasEmptyCan;
  final Map<String, dynamic> config;
  final UserModel? dealer;
  final ProductModel? refillProd;
  final ProductModel? newCanProd;

  const _CanOptionBottomSheet({
    required this.initialHasEmptyCan,
    required this.config,
    this.dealer,
    this.refillProd,
    this.newCanProd,
  });

  @override
  State<_CanOptionBottomSheet> createState() => _CanOptionBottomSheetState();
}

class _CanOptionBottomSheetState extends State<_CanOptionBottomSheet> {
  late bool _hasEmptyCan;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _hasEmptyCan = widget.initialHasEmptyCan;
  }

  @override
  Widget build(BuildContext context) {
    final refillPrice = widget.config['refillPrice'] as double;
    final refillOriginalPrice = widget.config['refillOriginalPrice'] as double;
    final exchangeDiscount = widget.config['exchangeDiscount'] as double;
    final newCanPrice = widget.config['newCanPrice'] as double;
    final refundableDeposit = widget.config['refundableDeposit'] as double;

    final unitPrice = _hasEmptyCan ? refillPrice : newCanPrice;
    final totalPrice = unitPrice * _quantity;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header with Water Can Image & Price
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF059669), size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasEmptyCan
                          ? '20L Drinking Water Can (Refill)'
                          : '20L Drinking Water Can (New Can)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasEmptyCan
                          ? 'Exchange your empty can & get ₹${exchangeDiscount.toStringAsFixed(0)} off'
                          : 'Includes ₹${refundableDeposit.toStringAsFixed(0)} refundable can deposit',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${unitPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                        if (_hasEmptyCan) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${refillOriginalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Do you have an empty can?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Option 1: Yes, I have (Refill)
          GestureDetector(
            onTap: () => setState(() => _hasEmptyCan = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hasEmptyCan ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasEmptyCan ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  width: _hasEmptyCan ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hasEmptyCan ? const Color(0xFF059669) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_rounded,
                      color: _hasEmptyCan ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yes, I have Empty Can',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Exchange & Save ₹${exchangeDiscount.toStringAsFixed(0)} • Pay ₹${refillPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _hasEmptyCan ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: _hasEmptyCan ? const Color(0xFF059669) : Colors.grey.shade400,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Option 2: No, I need New Can
          GestureDetector(
            onTap: () => setState(() => _hasEmptyCan = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !_hasEmptyCan ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_hasEmptyCan ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  width: !_hasEmptyCan ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !_hasEmptyCan ? const Color(0xFF2563EB) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: !_hasEmptyCan ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No, I need a New Can',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Includes ₹${refundableDeposit.toStringAsFixed(0)} deposit • Pay ₹${newCanPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    !_hasEmptyCan ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: !_hasEmptyCan ? const Color(0xFF2563EB) : Colors.grey.shade400,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quantity Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Add to Cart Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final cart = context.read<CartProvider>();
                final dealerId = widget.dealer?.id ?? 'default-dealer';
                final dealerName = widget.dealer?.shopName ?? widget.dealer?.name;

                final String productId = _hasEmptyCan
                    ? (widget.refillProd?.id.isNotEmpty == true
                        ? widget.refillProd!.id
                        : 'water-can-20l-refill')
                    : (widget.newCanProd?.id.isNotEmpty == true
                        ? widget.newCanProd!.id
                        : 'water-can-20l-new');

                final item = CartItemModel(
                  productId: productId,
                  productName: _hasEmptyCan
                      ? '20L Drinking Water Can (Refill)'
                      : '20L Drinking Water Can (New Can)',
                  price: unitPrice,
                  unit: '20L Can',
                  quantity: _quantity,
                  dealerId: dealerId,
                  dealerName: dealerName,
                  isWaterCan: true,
                  canExchange: _hasEmptyCan,
                  depositAmount: _hasEmptyCan ? 0.0 : refundableDeposit,
                );

                cart.addItemById(item);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${item.productName} (x$_quantity) added to cart from ${dealerName ?? "Store"}!',
                    ),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Add to Cart • ₹${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
