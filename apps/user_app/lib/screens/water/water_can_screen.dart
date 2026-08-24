import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import '../../providers/cart_provider.dart';

class WaterCanScreen extends StatefulWidget {
  const WaterCanScreen({super.key});

  @override
  State<WaterCanScreen> createState() => _WaterCanScreenState();
}

class _WaterCanScreenState extends State<WaterCanScreen> {
  final WaterCanRepository _waterCanRepo = WaterCanRepository();

  void _showCanOptionSheet({
    required BuildContext context,
    required bool initialHasEmptyCan,
    required Map<String, dynamic> config,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CanOptionBottomSheet(
        initialHasEmptyCan: initialHasEmptyCan,
        config: config,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return StreamBuilder<Map<String, dynamic>>(
      stream: _waterCanRepo.getPlatformCanConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? {
          'refillPrice': 50.0,
          'refillOriginalPrice': 80.0,
          'exchangeDiscount': 30.0,
          'newCanPrice': 150.0,
          'refundableDeposit': 100.0,
          'bottlePackPrice': 90.0,
        };

        final refillPrice = config['refillPrice'] as double;
        final refillOriginalPrice = config['refillOriginalPrice'] as double;
        final exchangeDiscount = config['exchangeDiscount'] as double;
        final newCanPrice = config['newCanPrice'] as double;
        final refundableDeposit = config['refundableDeposit'] as double;
        final bottlePackPrice = config['bottlePackPrice'] as double;

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

                const SizedBox(height: 24),

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
                  onAdd: () => _showCanOptionSheet(
                    context: context,
                    initialHasEmptyCan: true,
                    config: config,
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
                  onAdd: () => _showCanOptionSheet(
                    context: context,
                    initialHasEmptyCan: false,
                    config: config,
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

                // Item 3: 1L Water Bottle (Pack of 6)
                _WaterProductCard(
                  title: '1L Water Bottle',
                  subtitle: 'Pack of 6 bottles (Pure Mineral Water)',
                  price: bottlePackPrice,
                  icon: Icons.local_drink_rounded,
                  onAdd: () {
                    cart.addItemById(CartItemModel(
                      productId: 'water-bottle-1l-pack6',
                      productName: '1L Water Bottle (Pack of 6)',
                      price: bottlePackPrice,
                      unit: 'pack',
                      quantity: 1,
                      dealerId: 'default-dealer',
                      isWaterCan: false,
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('1L Water Bottle (Pack of 6) added to cart!'),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
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
                                'My Can Balance & Ledger',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Check active cans held & return records',
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
  final VoidCallback onAdd;

  const _WaterProductCard({
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    this.badgeText,
    this.badgeColor,
    required this.icon,
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
            child: Icon(icon, color: const Color(0xFF059669), size: 36),
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
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
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

  const _CanOptionBottomSheet({
    required this.initialHasEmptyCan,
    required this.config,
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
                final item = CartItemModel(
                  productId: _hasEmptyCan ? 'water-can-20l-refill' : 'water-can-20l-new',
                  productName: _hasEmptyCan
                      ? '20L Drinking Water Can (Refill)'
                      : '20L Drinking Water Can (New Can)',
                  price: unitPrice,
                  unit: '20L Can',
                  quantity: _quantity,
                  dealerId: 'default-dealer',
                  isWaterCan: true,
                  canExchange: _hasEmptyCan,
                  depositAmount: _hasEmptyCan ? 0.0 : refundableDeposit,
                );

                cart.addItemById(item);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${item.productName} (x$_quantity) added to cart!',
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
