import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _stockFilter = 'All';
  String _searchQuery = '';

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var list = products;
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    switch (_stockFilter) {
      case 'In Stock':
        return list.where((p) => p.inStock && p.stockQuantity >= 10).toList();
      case 'Low Stock':
        return list.where((p) => p.stockQuantity < 10 && p.stockQuantity > 0).toList();
      case 'Out of Stock':
        return list.where((p) => !p.inStock || p.stockQuantity == 0).toList();
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Store Inventory',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF34D399), size: 28),
            onPressed: () => context.push('/add-product'),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductRepository().getProducts(dealerId: user.id, activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          final rawProducts = snapshot.data ?? [];
          final products = _filterProducts(rawProducts);

          return Column(
            children: [
              // Search & Filter Header Container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search products by name...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((cat) {
                          final isSelected = _stockFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _stockFilter = cat);
                              },
                              selectedColor: const Color(0xFF059669),
                              backgroundColor: const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12,
                              ),
                              side: BorderSide(color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Product Inventory List
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF059669)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                rawProducts.isEmpty ? 'No Products in Inventory' : 'No Products Found ($_stockFilter)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap the + button above to list new store items for your customers.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final p = products[i];
                          return _InventoryCard(product: p);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final ProductModel product;
  const _InventoryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isLow = product.stockQuantity < 10 && product.stockQuantity > 0;
    final isOut = !product.inStock || product.stockQuantity == 0;

    Color statusColor = const Color(0xFF059669);
    Color statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
    String statusText = 'Stock: ${product.stockQuantity}';

    if (isOut) {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      statusText = 'Out of Stock';
    } else if (isLow) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      statusText = 'Low Stock (${product.stockQuantity})';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imageUrls.isNotEmpty
                ? Image.network(product.imageUrls.first, width: 68, height: 68, fit: BoxFit.cover)
                : Container(width: 68, height: 68, color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('₹${product.price.toStringAsFixed(0)} / ${product.unit}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick Stock Add +10 Button
                    InkWell(
                      onTap: () {
                        final newQty = product.stockQuantity + 10;
                        ProductRepository().updateProduct(product.copyWith(stockQuantity: newQty, isActive: true));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: const Text('+10 Stock', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 28,
                child: Switch(
                  value: product.isActive,
                  activeThumbColor: const Color(0xFF059669),
                  onChanged: (v) => ProductRepository().toggleProductActive(product.id, v),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () => context.push('/add-product', extra: product),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
