import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _isCheckingCoupon = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCouponByCode(CartProvider cart) async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isCheckingCoupon = true);
    try {
      final coupon = await CouponRepository().getCouponByCode(code);
      if (coupon == null) {
        throw 'Invalid coupon code. Please check and try again.';
      }
      if (!coupon.isValid) {
        throw 'This coupon is expired or no longer available.';
      }
      if (cart.subtotal < coupon.minSubtotal) {
        throw 'Minimum order subtotal of ₹${coupon.minSubtotal.toStringAsFixed(0)} required for code ${coupon.code}.';
      }

      cart.applyCoupon(coupon);
      _couponCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Coupon "${coupon.code}" applied! Saved ₹${coupon.calculateDiscount(cart.subtotal).toStringAsFixed(0)}'),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingCoupon = false);
    }
  }

  void _showCouponsBottomSheet(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF046A38).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_offer_rounded, color: Color(0xFF046A38), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Apply Coupon',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Promo input box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'Enter coupon code',
                            isDense: true,
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isCheckingCoupon
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _applyCouponByCode(cart);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046A38),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 28),
              Expanded(
                child: StreamBuilder<List<CouponModel>>(
                  stream: CouponRepository().getActiveCoupons(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF046A38)));
                    }
                    final coupons = snapshot.data ?? [];
                    if (coupons.isEmpty) {
                      return const Center(
                        child: Text(
                          'No promo coupons available right now.',
                          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: coupons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final coupon = coupons[i];
                        final isEligible = cart.subtotal >= coupon.minSubtotal;
                        final discount = coupon.calculateDiscount(cart.subtotal);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isEligible ? const Color(0xFF10B981).withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEligible ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF046A38),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      coupon.code,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: isEligible
                                        ? () {
                                            cart.applyCoupon(coupon);
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Coupon "${coupon.code}" applied! Saved ₹${discount.toStringAsFixed(0)}'),
                                                backgroundColor: const Color(0xFF046A38),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Text(
                                      cart.appliedCoupon?.id == coupon.id ? 'APPLIED' : 'APPLY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isEligible ? const Color(0xFF046A38) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                coupon.description,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEligible
                                    ? 'Save ₹${discount.toStringAsFixed(0)} on this order'
                                    : 'Add ₹${(coupon.minSubtotal - cart.subtotal).toStringAsFixed(0)} more to unlock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isEligible ? const Color(0xFF046A38) : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final dealerId = cart.items.isNotEmpty ? cart.items.first.dealerId : null;

    return StreamBuilder<StoreSettingsModel>(
      stream: (dealerId != null && dealerId.isNotEmpty)
          ? SettingsRepository().getDealerSettings(dealerId)
          : SettingsRepository().getGlobalSettings(),
      builder: (context, settingsSnap) {
        if (settingsSnap.hasData && settingsSnap.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cart.updateDeliverySettings(settingsSnap.data!);
          });
        }

        final freeDeliveryThreshold = settingsSnap.data?.freeDeliveryThreshold ?? 500.0;
        final isFreeDelivery = cart.subtotal >= freeDeliveryThreshold;
        final amountNeededForFree = (freeDeliveryThreshold - cart.subtotal).clamp(0.0, freeDeliveryThreshold);
        final progress = (cart.subtotal / freeDeliveryThreshold).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: context.canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: const Text(
              'My Cart',
              style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 18),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF046A38).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF046A38), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '100% Safe',
                      style: TextStyle(color: Color(0xFF046A38), fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: cart.items.isEmpty
              ? _buildEmptyState(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free delivery progress banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_shipping_rounded, color: Color(0xFF046A38), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isFreeDelivery
                                        ? '🎉 You have unlocked FREE delivery!'
                                        : 'Add ₹${amountNeededForFree.toStringAsFixed(0)} more to get FREE delivery',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFF046A38),
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${cart.subtotal.toStringAsFixed(0)} / ₹${freeDeliveryThreshold.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF046A38),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF046A38)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cart Item List
                      ...cart.items.map((item) => _buildCartItemCard(context, item, cart)),
                      const SizedBox(height: 14),

                      // Frequently Bought Together Cross-Sell Carousel
                      _buildCrossSellRecommendations(context, cart),
                      const SizedBox(height: 16),

                      // Apply Coupon Card
                      GestureDetector(
                        onTap: () => _showCouponsBottomSheet(context, cart),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF046A38).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.discount_rounded, color: Color(0xFF046A38), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cart.appliedCoupon != null
                                          ? 'Coupon: ${cart.appliedCoupon!.code}'
                                          : 'Apply Coupon',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF111827)),
                                    ),
                                    Text(
                                      cart.appliedCoupon != null
                                          ? 'You save ₹${cart.discountAmount.toStringAsFixed(0)}'
                                          : 'Use offers & save more',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              if (cart.appliedCoupon != null)
                                GestureDetector(
                                  onTap: () => cart.removeCoupon(),
                                  child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 12)),
                                )
                              else
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bill Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bill Summary',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Transparent billing with all charges',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 14),
                            _buildBillRow('Subtotal (${cart.itemCount} items)', '₹${cart.subtotal.toStringAsFixed(0)}'),
                            const SizedBox(height: 8),
                            _buildBillRow(
                              'Delivery Fee',
                              cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
                              isGreen: cart.deliveryFee == 0,
                            ),
                            if (cart.discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              _buildBillRow('Coupon Discount', '-₹${cart.discountAmount.toStringAsFixed(0)}', isGreen: true),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'To Pay',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827)),
                                ),
                                Text(
                                  '₹${cart.total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF046A38)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          bottomSheet: cart.items.isEmpty
              ? null
              : Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 8 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('To Pay', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600)),
                          Text(
                            '₹${cart.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => context.push('/checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046A38),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Proceed to Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItemModel item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Product Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.unit,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(0)} / ${item.unit}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          // Price & Quantity controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => cart.deleteItem(item.productId),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF9CA3AF), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => cart.updateQuantity(item.productId, item.quantity - 1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(
                          item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                          size: 16,
                          color: const Color(0xFF046A38),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF046A38)),
                      ),
                    ),
                    InkWell(
                      onTap: () => cart.updateQuantity(item.productId, item.quantity + 1),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.add_rounded, size: 16, color: Color(0xFF046A38)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrossSellRecommendations(BuildContext context, CartProvider cart) {
    return StreamBuilder<List<ProductModel>>(
      stream: ProductRepository().getProducts(activeOnly: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final products = snapshot.data!
            .where((p) => !cart.containsProduct(p.id) && p.stockQuantity > 0)
            .take(6)
            .toList();

        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF046A38), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Frequently Bought Together',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 165,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final product = products[i];
                  return Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: product.imageUrls.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.imageUrls.first,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image_outlined, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.unit,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF046A38)),
                            ),
                            GestureDetector(
                              onTap: () => cart.addItem(product),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF7EE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF046A38).withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: Color(0xFF046A38),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.add, size: 12, color: Color(0xFF046A38)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isGreen ? const Color(0xFF046A38) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF7EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFF046A38)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items to get started with fresh deliveries',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Start Shopping', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
