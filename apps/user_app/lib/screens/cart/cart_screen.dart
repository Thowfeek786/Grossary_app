import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'My Cart',
        actions: [
          if (cart.itemCount > 0)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add some fresh groceries to get started!',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return _CartTile(item: item, cart: cart);
                    },
                  ),
                ),
                _buildSummary(context, cart),
              ],
            ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          _SummaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _SummaryRow(
            'Delivery Fee',
            cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
            valueColor: cart.deliveryFee == 0 ? AppColors.success : null,
          ),
          if (cart.deliveryFee == 0) ...[
            const SizedBox(height: 4),
            const Text('🎉 Free delivery on orders above ₹500',
                style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          _SummaryRow('Total', '₹${cart.total.toStringAsFixed(0)}',
              isBold: true, valueColor: AppColors.primary),
          const SizedBox(height: 16),
          AppButton(
            label: 'Proceed to Checkout',
            icon: Icons.arrow_forward_rounded,
            onTap: () => context.push('/checkout'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) cart.clearCart();
  }
}

class _CartTile extends StatelessWidget {
  final item;
  final CartProvider cart;
  const _CartTile({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null
                ? Image.network(item.imageUrl!, width: 70, height: 70, fit: BoxFit.cover)
                : Container(
                    width: 70, height: 70,
                    color: AppColors.grey100,
                    child: const Icon(Icons.image_outlined, color: AppColors.grey400),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.unit, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text('₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                onPressed: () => cart.deleteItem(item.productId),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SmallBtn(Icons.remove_rounded, () => cart.removeItem(item.productId)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    _SmallBtn(Icons.add_rounded, () => cart.addItemById(item)),
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

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: AppColors.primarySurface),
        child: Icon(icon, size: 16, color: AppColors.primary),
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
        Text(label, style: TextStyle(
          fontSize: isBold ? 16 : 14,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        Text(value, style: TextStyle(
          fontSize: isBold ? 18 : 14,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: valueColor ?? AppColors.textPrimary,
        )),
      ],
    );
  }
}
