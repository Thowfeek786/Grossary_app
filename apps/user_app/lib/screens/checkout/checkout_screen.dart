import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
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
  final List<String> _paymentMethods = ['Cash on Delivery', 'UPI', 'Card'];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Checkout'),
      body: StreamBuilder<List<AddressModel>>(
        stream: _userRepo.getAddresses(user.id),
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? [];
          if (_selectedAddress == null && addresses.isNotEmpty) {
            final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedAddress = def);
            });
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'Delivery Address',
                        icon: Icons.location_on_rounded,
                        child: addresses.isEmpty
                            ? _AddAddressPrompt(onTap: () => context.push('/profile/add-address'))
                            : Column(
                                children: [
                                  ...addresses.map((a) => _AddressTile(
                                    address: a,
                                    isSelected: _selectedAddress?.id == a.id,
                                    onSelect: () => setState(() => _selectedAddress = a),
                                  )),
                                  TextButton.icon(
                                    onPressed: () => context.push('/profile/add-address'),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add New Address'),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Order Items (${cart.itemCount})',
                        icon: Icons.shopping_bag_outlined,
                        child: Column(
                          children: cart.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.imageUrl != null
                                      ? Image.network(item.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                                      : Container(width: 48, height: 48, color: AppColors.grey100,
                                          child: const Icon(Icons.image_outlined, color: AppColors.grey400)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text('${item.quantity} × ${item.unit}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('₹${item.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Payment Method',
                        icon: Icons.payment_rounded,
                        child: Column(
                          children: _paymentMethods.map((method) => RadioListTile<String>(
                            title: Text(method, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            value: method,
                            groupValue: _paymentMethod,
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildPlaceOrderBar(context, cart, user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPlaceOrderBar(BuildContext context, CartProvider cart, UserModel user) {
    final orderProvider = context.watch<OrderProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.white,
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('₹${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          AppButton(
            label: 'Place Order',
            isLoading: orderProvider.isLoading,
            icon: Icons.check_rounded,
            onTap: _selectedAddress == null ? null : () => _placeOrder(context, cart, user),
          ),
          if (_selectedAddress == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Please select a delivery address',
                  style: TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart, UserModel user) async {
    final orderProvider = context.read<OrderProvider>();
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
      discount: 0,
      total: cart.total,
      paymentMethod: _paymentMethod,
      dealerId: cart.items.isNotEmpty ? cart.items.first.dealerId : null,
      dealerName: cart.items.isNotEmpty ? cart.items.first.dealerName : null,
      createdAt: DateTime.now(),
    );
    final id = await orderProvider.placeOrder(order);
    if (id != null && mounted) {
      cart.clearCart();
      context.go('/order-success/$id');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error ?? 'Failed to place order'),
            backgroundColor: AppColors.error),
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
          color: isSelected ? AppColors.primarySurface : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.grey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                address.label == 'Home' ? Icons.home_rounded : Icons.business_rounded,
                color: isSelected ? AppColors.white : AppColors.grey500, size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(address.fullAddress,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
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
          border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primarySurface,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Delivery Address', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
