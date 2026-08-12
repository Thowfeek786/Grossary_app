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
            backgroundColor: const Color(0xFF059669),
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
          height: MediaQuery.of(ctx).size.height * 0.68,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded, color: Color(0xFF059669)),
                    SizedBox(width: 10),
                    Text(
                      'Available Promo Coupons',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: StreamBuilder<List<CouponModel>>(
                  stream: CouponRepository().getActiveCoupons(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                    }
                    final coupons = snapshot.data ?? [];
                    if (coupons.isEmpty) {
                      return const Center(
                        child: Text(
                          'No active coupons available right now.',
                          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: coupons.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      coupon.code,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
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
                                                backgroundColor: const Color(0xFF059669),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Text(
                                      cart.appliedCoupon?.id == coupon.id ? 'APPLIED' : 'APPLY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isEligible ? const Color(0xFF059669) : Colors.grey,
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
                                    : 'Add ₹${(coupon.minSubtotal - cart.subtotal).toStringAsFixed(0)} more to unlock code',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isEligible ? const Color(0xFF059669) : const Color(0xFFEF4444),
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

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'My Cart (${cart.itemCount})',
              style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900),
            ),
            actions: [
              if (cart.itemCount > 0)
                TextButton.icon(
                  onPressed: () => _confirmClear(context, cart),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  label: const Text('Clear', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          body: cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 72,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Your Cart is Empty',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore our fresh groceries and add items to get ${settingsSnap.data?.estimatedDeliveryTime ?? "20 to 30 minutes"} superfast delivery!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Start Shopping', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  child: Column(
                    children: [
                      // Superfast Express Delivery Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Superfast ${settingsSnap.data?.estimatedDeliveryTime ?? "20 to 30 Minutes"} Delivery',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF065F46)),
                                  ),
                                  const Text(
                                    'Items will be packed fresh & dispatched immediately',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cart Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final item = cart.items[i];
                          return _CartTile(item: item, cart: cart);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Coupon Promo Card
                      _buildCouponCard(cart),

                      const SizedBox(height: 20),

                      // Bill Summary Details
                      _buildBillSummary(cart),
                    ],
                  ),
                ),
          bottomNavigationBar: cart.isEmpty ? null : _buildCheckoutBar(context, cart),
        );
      },
    );
  }

  Widget _buildCouponCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cart.appliedCoupon != null ? const Color(0xFF059669) : Colors.grey.shade200,
          width: cart.appliedCoupon != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: cart.appliedCoupon != null
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon "${cart.appliedCoupon!.code}" Applied',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 13),
                      ),
                      Text(
                        'Saving ₹${cart.discountAmount.toStringAsFixed(0)} on this order',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => cart.removeCoupon(),
                  child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Enter Promo Code (e.g. WELCOME50)',
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF111827)),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isCheckingCoupon ? null : () => _applyCouponByCode(cart),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isCheckingCoupon
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                GestureDetector(
                  onTap: () => _showCouponsBottomSheet(context, cart),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, color: Color(0xFF059669), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'View Available Coupons & Offers',
                        style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBillSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 14),
          _SummaryRow('Item Total / Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _SummaryRow(
            'Delivery Fee',
            cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
            valueColor: cart.deliveryFee == 0 ? const Color(0xFF059669) : null,
          ),
          if (cart.appliedCoupon != null) ...[
            const SizedBox(height: 10),
            _SummaryRow(
              'Coupon Discount (${cart.appliedCoupon!.code})',
              '-₹${cart.discountAmount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF059669),
            ),
          ],
          if (cart.isFreeDeliveryEnabled && cart.deliveryFee == 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🎉 Free delivery applied on orders above ₹${cart.freeDeliveryThreshold.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _SummaryRow(
            'Grand Total',
            '₹${cart.total.toStringAsFixed(0)}',
            isBold: true,
            valueColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 8 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL PAYABLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8)),
              Text(
                '₹${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Proceed to Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Cart?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (ok == true) cart.clearCart();
  }
}

class _CartTile extends StatelessWidget {
  final CartItemModel item;
  final CartProvider cart;

  const _CartTile({
    required this.item,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(Icons.image_outlined, color: Colors.grey),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  item.unit,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () => cart.deleteItem(item.productId),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityBtn(Icons.remove_rounded, () => cart.removeItem(item.productId)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF065F46)),
                      ),
                    ),
                    _QuantityBtn(Icons.add_rounded, () => cart.addItemById(item)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFF059669)),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  const _SummaryRow(this.label, this.value, {this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
            color: isBold ? const Color(0xFF111827) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? (isBold ? const Color(0xFF111827) : const Color(0xFF111827)),
          ),
        ),
      ],
    );
  }
}
