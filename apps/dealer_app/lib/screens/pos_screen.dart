import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/auth_provider.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _paymentMethod = 'Cash'; // Cash, UPI, Card

  // In-memory cart for the walk-in session: Map<productId, quantity>
  final Map<String, int> _cart = {};
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    super.dispose();
  }

  double _calculateTotal(List<ProductModel> products) {
    double total = 0;
    for (final entry in _cart.entries) {
      final p = products.where((item) => item.id == entry.key).firstOrNull;
      if (p != null) {
        total += (p.effectivePrice * entry.value);
      }
    }
    return total;
  }

  int _calculateTotalItems() {
    return _cart.values.fold(0, (sum, q) => sum + q);
  }

  Future<void> _completeCheckout(List<ProductModel> products, UserModel user) async {
    if (_cart.isEmpty) return;

    final customerName = _customerNameCtrl.text.trim().isEmpty ? 'Walk-in Customer' : _customerNameCtrl.text.trim();
    final customerPhone = _customerPhoneCtrl.text.trim();
    final total = _calculateTotal(products);

    setState(() => _isProcessing = true);

    try {
      final List<CartItemModel> items = [];

      for (final entry in _cart.entries) {
        final p = products.where((item) => item.id == entry.key).firstOrNull;
        if (p != null) {
          items.add(
            CartItemModel(
              productId: p.id,
              productName: p.name,
              price: p.price,
              discountPrice: p.discountPrice,
              quantity: entry.value,
              unit: p.unit,
              imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
              dealerId: user.id,
              dealerName: user.shopName ?? user.name,
            ),
          );
        }
      }

      final newOrder = OrderModel(
        id: '',
        userId: 'walkin-${DateTime.now().millisecondsSinceEpoch}',
        userName: customerName,
        userEmail: 'walkin@store.local',
        userPhone: customerPhone.isNotEmpty ? customerPhone : user.phone,
        items: items,
        total: total,
        subtotal: total,
        discount: 0,
        deliveryFee: 0,
        status: OrderStatus.delivered,
        paymentMethod: 'POS - $_paymentMethod',
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dealerId: user.id,
        dealerName: user.shopName ?? user.name,
        deliveryAddress: AddressModel(
          id: 'pos-store',
          userId: user.id,
          label: 'Store Counter',
          fullName: customerName,
          phone: customerPhone.isNotEmpty ? customerPhone : user.phone,
          addressLine1: user.shopAddress ?? 'Over the counter POS',
          city: 'Local',
          state: 'Store',
          pincode: '000000',
        ),
      );

      final orderId = await OrderRepository().placeOrder(newOrder);

      setState(() {
        _cart.clear();
        _customerNameCtrl.clear();
        _customerPhoneCtrl.clear();
        _isProcessing = false;
      });

      if (mounted) {
        _showReceiptDialog(orderId, customerName, total, items);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete sale: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _showReceiptDialog(String orderId, String customer, double total, List<CartItemModel> items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 26),
            SizedBox(width: 10),
            Text('Sale Completed!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Text(customer, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items Sold', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Text('${items.fold(0, (sum, i) => sum + i.quantity)} items', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 12.5)),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 14)),
                      Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done / Next Customer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Walk-in Store POS',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFF87171)),
              onPressed: () => setState(() => _cart.clear()),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductRepository().getProducts(dealerId: user.id, activeOnly: true),
        builder: (context, prodSnap) {
          final allProducts = prodSnap.data ?? [];
          final categories = allProducts.map((p) => p.categoryName).toSet().toList();

          var filtered = allProducts;
          if (_selectedCategory != 'All') {
            filtered = filtered.where((p) => p.categoryName == _selectedCategory).toList();
          }
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          final totalAmount = _calculateTotal(allProducts);
          final totalCount = _calculateTotalItems();

          return Column(
            children: [
              // Top Search & Quick Category Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search or scan product SKU...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0F766E), size: 20),
                              tooltip: 'Scan Barcode / QR with Camera',
                              onPressed: () async {
                                final scanned = await CanQrScannerDialog.show(
                                  context,
                                  title: 'Scan Item Barcode / QR',
                                  prompt: 'Align product barcode or QR code inside the camera viewfinder',
                                );
                                if (scanned != null && scanned.isNotEmpty) {
                                  _searchCtrl.text = scanned;
                                  setState(() => _searchQuery = scanned);
                                }
                              },
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterPill('All', _selectedCategory == 'All', () => setState(() => _selectedCategory = 'All')),
                          ...categories.map((c) => _buildFilterPill(c, _selectedCategory == c, () => setState(() => _selectedCategory = c))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Product Catalog Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          allProducts.isEmpty ? 'No store products found' : 'No matching items',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          final qtyInCart = _cart[p.id] ?? 0;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: qtyInCart > 0 ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                width: qtyInCart > 0 ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: p.imageUrls.isNotEmpty && p.imageUrls.first.startsWith('http')
                                          ? Image.network(p.imageUrls.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 36, color: Color(0xFF94A3B8)))
                                          : Image.asset('assets/images/water_can_20l.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF059669))),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${p.effectivePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF059669))),
                                    Text('Stock: ${p.stockQuantity.toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (qtyInCart == 0)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: p.stockQuantity > 0
                                          ? () => setState(() => _cart[p.id] = 1)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF059669)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 14, color: Color(0xFF059669)),
                                          onPressed: () {
                                            setState(() {
                                              if (qtyInCart == 1) {
                                                _cart.remove(p.id);
                                              } else {
                                                _cart[p.id] = qtyInCart - 1;
                                              }
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        ),
                                        Text('$qtyInCart', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 12)),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 14, color: Color(0xFF059669)),
                                          onPressed: qtyInCart < p.stockQuantity
                                              ? () => setState(() => _cart[p.id] = qtyInCart + 1)
                                              : null,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Checkout Tray
              if (_cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customerNameCtrl,
                              decoration: InputDecoration(
                                hintText: 'Customer name (optional)',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Payment mode selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: _paymentMethod,
                              underline: const SizedBox.shrink(),
                              icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 12),
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('💵 Cash')),
                                DropdownMenuItem(value: 'UPI', child: Text('📱 UPI / QR')),
                                DropdownMenuItem(value: 'Card', child: Text('💳 Card')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _paymentMethod = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$totalCount items in cart', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _completeCheckout(allProducts, user),
                            icon: _isProcessing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.point_of_sale_rounded, size: 18),
                            label: const Text('Complete Sale', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B3C26) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}
