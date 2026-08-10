import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final UserRepository _userRepo = UserRepository();
  AddressModel? _selectedAddress;
  String _paymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = ['Cash on Delivery', 'GroceryGo Wallet', 'UPI', 'Card'];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<AddressModel>>(
        stream: _userRepo.getAddresses(user.id),
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? [];
          if (_selectedAddress == null && addresses.isNotEmpty) {
            final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedAddress = def);
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Delivery Address Card
                _buildCard(
                  title: 'Delivery Address',
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF10B981),
                  child: addresses.isEmpty
                      ? _AddAddressPrompt(onTap: () => context.push('/profile/add-address'))
                      : Column(
                          children: [
                            ...addresses.map((a) => _AddressTile(
                              address: a,
                              isSelected: _selectedAddress?.id == a.id,
                              onSelect: () => setState(() => _selectedAddress = a),
                            )),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => context.push('/profile/add-address'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF059669)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, color: Color(0xFF059669), size: 18),
                                    SizedBox(width: 6),
                                    Text('Add New Address', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 16),

                // 2. Order Items Summary Card
                _buildCard(
                  title: 'Order Items (${cart.itemCount})',
                  icon: Icons.shopping_bag_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  child: Column(
                    children: cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity} × ${item.unit}',
                                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 15),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Applied Coupon Banner
                if (cart.appliedCoupon != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_rounded, color: Color(0xFF059669)),
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
                                'You save ₹${cart.discountAmount.toStringAsFixed(0)} on this order',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-₹${cart.discountAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),

                // 4. Payment Method Selection Card
                _buildCard(
                  title: 'Payment Method',
                  icon: Icons.payment_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  child: Column(
                    children: _paymentMethods.map((method) {
                      final isSelected = _paymentMethod == method;
                      final isWallet = method == 'GroceryGo Wallet';
                      return GestureDetector(
                        onTap: () => setState(() => _paymentMethod = method),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.06) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                    color: isSelected ? const Color(0xFF059669) : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    method,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                                  ),
                                  if (isWallet) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('Instant', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ],
                              ),
                              if (isWallet && isSelected)
                                StreamBuilder<WalletModel>(
                                  stream: WalletRepository().getWallet(user.id),
                                  builder: (context, walletSnap) {
                                    final wallet = walletSnap.data ?? WalletModel(userId: user.id, balance: 0.0, transactions: [], updatedAt: DateTime.now());
                                    final isSufficient = wallet.balance >= cart.total;
                                    return Container(
                                      margin: const EdgeInsets.only(top: 10, left: 32),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSufficient
                                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Balance: ₹${wallet.balance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: isSufficient ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                            ),
                                          ),
                                          if (!isSufficient)
                                            GestureDetector(
                                              onTap: () => context.push('/profile/wallet'),
                                              child: const Text(
                                                'Top Up Wallet →',
                                                style: TextStyle(
                                                  color: Color(0xFF059669),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
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
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildPlaceOrderBar(context, cart, user),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPlaceOrderBar(BuildContext context, CartProvider cart, UserModel user) {
    final orderProvider = context.watch<OrderProvider>();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GRAND TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8)),
                  Text('Inclusive of all taxes', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
              Text(
                '₹${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selectedAddress == null || orderProvider.isLoading)
                  ? null
                  : () => _placeOrder(context, cart, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: orderProvider.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Place Order Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          if (_selectedAddress == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Please add or select a delivery address to place order',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart, UserModel user) async {
    final orderProvider = context.read<OrderProvider>();

    // Wallet balance check if paying via Wallet
    if (_paymentMethod == 'GroceryGo Wallet') {
      try {
        final walletStream = await WalletRepository().getWallet(user.id).first;
        if (walletStream.balance < cart.total) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Insufficient wallet balance. Please top up your wallet or choose another payment method.'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          return;
        }
      } catch (_) {}
    }

    final order = OrderModel(
      id: '',
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      userPhone: user.phone,
      items: cart.items.toList(),
      deliveryAddress: _selectedAddress!,
      status: OrderStatus.pending,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      discount: cart.discountAmount,
      total: cart.total,
      paymentMethod: _paymentMethod,
      dealerId: cart.items.isNotEmpty ? cart.items.first.dealerId : null,
      dealerName: cart.items.isNotEmpty ? cart.items.first.dealerName : null,
      createdAt: DateTime.now(),
    );

    final id = await orderProvider.placeOrder(order);
    if (id != null && mounted) {
      // Deduct from wallet if wallet payment was chosen
      if (_paymentMethod == 'GroceryGo Wallet') {
        try {
          await WalletRepository().deductBalance(
            userId: user.id,
            amount: cart.total,
            description: 'Payment for Order #${id.substring(0, 6).toUpperCase()}',
          );
        } catch (_) {}
      }

      // Increment coupon usage count if coupon applied
      if (cart.appliedCoupon != null) {
        try {
          await CouponRepository().incrementUsage(cart.appliedCoupon!.id);
        } catch (_) {}
      }

      cart.clearCart();
      context.go('/order-success/$id');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place order'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onSelect;
  const _AddressTile({required this.address, required this.isSelected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                address.label == 'Home' ? Icons.home_rounded : Icons.business_rounded,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111827))),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('DEFAULT', style: TextStyle(color: Color(0xFF047857), fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
          ],
        ),
      ),
    );
  }
}

class _AddAddressPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAddressPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF059669), width: 1.5),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Add Delivery Address', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
