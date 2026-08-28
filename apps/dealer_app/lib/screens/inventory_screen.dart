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
  String _selectedCategoryId = 'All';
  String _sortBy = 'Default';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var list = List<ProductModel>.from(products);

    // 1. Category Filter
    if (_selectedCategoryId != 'All') {
      list = list.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // 2. Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 3. Stock / Offer Status Filter
    switch (_stockFilter) {
      case 'In Stock':
        list = list.where((p) => p.inStock && p.stockQuantity >= 10).toList();
        break;
      case 'Low Stock':
        list = list.where((p) => p.stockQuantity < 10 && p.stockQuantity > 0).toList();
        break;
      case 'Out of Stock':
        list = list.where((p) => !p.inStock || p.stockQuantity == 0).toList();
        break;
      case 'Offers & BOGO':
        list = list.where((p) => p.hasSpecialOffer).toList();
        break;
      default:
        break;
    }

    // 4. Sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Stock: Low to High':
        list.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'Stock: High to Low':
        list.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case 'Name: A-Z':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      default:
        break;
    }

    return list;
  }

  void _showWaterStockModal(BuildContext context, List<ProductModel> rawProducts, UserModel user) {
    final refillProd = rawProducts.where((p) => p.name.toLowerCase().contains('refill') || (p.name.toLowerCase().contains('20l') && !p.name.toLowerCase().contains('new'))).firstOrNull;
    final newCanProd = rawProducts.where((p) => p.name.toLowerCase().contains('new') && (p.name.toLowerCase().contains('can') || p.name.toLowerCase().contains('20l'))).firstOrNull;
    final bottle1LProd = rawProducts.where((p) => p.name.toLowerCase().contains('1l') && !p.name.toLowerCase().contains('pack')).firstOrNull;
    final bottlePackProd = rawProducts.where((p) => p.name.toLowerCase().contains('pack of 6') || (p.name.toLowerCase().contains('1l') && p.name.toLowerCase().contains('pack'))).firstOrNull;

    int refillStock = refillProd?.stockQuantity.toInt() ?? 25;
    double refillPrice = refillProd?.effectivePrice ?? 50.0;

    int newCanStock = newCanProd?.stockQuantity.toInt() ?? 10;
    double newCanPrice = newCanProd?.effectivePrice ?? 150.0;

    int bottle1LStock = bottle1LProd?.stockQuantity.toInt() ?? 40;
    double bottle1LPrice = bottle1LProd?.effectivePrice ?? 20.0;

    int bottlePackStock = bottlePackProd?.stockQuantity.toInt() ?? 15;
    double bottlePackPrice = bottlePackProd?.effectivePrice ?? 90.0;

    final refillPriceCtrl = TextEditingController(text: refillPrice.toStringAsFixed(0));
    final newCanPriceCtrl = TextEditingController(text: newCanPrice.toStringAsFixed(0));
    final bottle1LPriceCtrl = TextEditingController(text: bottle1LPrice.toStringAsFixed(0));
    final bottlePackPriceCtrl = TextEditingController(text: bottlePackPrice.toStringAsFixed(0));

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Water Stock & Price Control',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure live stock and selling prices for ${user.shopName ?? "your store"}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Color(0xFF059669), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      children: [
                        // 1. 20L Water Can (Refill)
                        _buildWaterStockItemCard(
                          title: '20L Water Can (Refill)',
                          subtitle: 'Exchange empty can refill price',
                          stock: refillStock,
                          priceCtrl: refillPriceCtrl,
                          icon: Icons.sync_rounded,
                          onStockChanged: (val) => setModalState(() => refillStock = val),
                        ),
                        const SizedBox(height: 12),

                        // 2. 20L Water Can (New)
                        _buildWaterStockItemCard(
                          title: '20L Water Can (New + Deposit)',
                          subtitle: 'Brand new filled can with deposit',
                          stock: newCanStock,
                          priceCtrl: newCanPriceCtrl,
                          icon: Icons.add_circle_outline_rounded,
                          onStockChanged: (val) => setModalState(() => newCanStock = val),
                        ),
                        const SizedBox(height: 12),

                        // 3. 1L Single Bottle
                        _buildWaterStockItemCard(
                          title: '1L Water Bottle (Single)',
                          subtitle: 'Individual 1 Litre packaged bottle',
                          stock: bottle1LStock,
                          priceCtrl: bottle1LPriceCtrl,
                          icon: Icons.local_drink_rounded,
                          onStockChanged: (val) => setModalState(() => bottle1LStock = val),
                        ),
                        const SizedBox(height: 12),

                        // 4. 1L Bottle (Pack of 6)
                        _buildWaterStockItemCard(
                          title: '1L Water Bottle (Pack of 6)',
                          subtitle: 'Bulk pack of 6 mineral water bottles',
                          stock: bottlePackStock,
                          priceCtrl: bottlePackPriceCtrl,
                          icon: Icons.inventory_2_outlined,
                          onStockChanged: (val) => setModalState(() => bottlePackStock = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              final repo = WaterAssetRepository();
                              final generated = await repo.registerNewCanBatch(
                                dealerId: user.id,
                                dealerName: user.shopName ?? user.name,
                                count: 20,
                              );
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ Successfully registered ${generated.length} new serialized QR cans into dark store pool!'),
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text('+ Provision 20 Serialized QR Can Pool', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        try {
                          final productRepo = ProductRepository();
                          final double rPrice = double.tryParse(refillPriceCtrl.text) ?? 50.0;
                          final double nPrice = double.tryParse(newCanPriceCtrl.text) ?? 150.0;
                          final double b1Price = double.tryParse(bottle1LPriceCtrl.text) ?? 20.0;
                          final double bPPrice = double.tryParse(bottlePackPriceCtrl.text) ?? 90.0;

                          // 1. Refill Can
                          if (refillProd != null) {
                            await productRepo.updateProduct(refillProd.copyWith(
                              price: rPrice,
                              stockQuantity: refillStock.toDouble(),
                              imageUrls: ['assets/images/water_can_20l.png'],
                            ));
                          } else {
                            await productRepo.addProduct(
                              ProductModel(
                                id: '',
                                name: '20L Water Can (Refill)',
                                description: '20L mineral water can refill with empty can exchange.',
                                price: rPrice,
                                categoryId: 'water_cans',
                                categoryName: 'Water & Beverages',
                                imageUrls: ['assets/images/water_can_20l.png'],
                                unit: '20L Can',
                                stockQuantity: refillStock.toDouble(),
                                dealerId: user.id,
                                dealerName: user.shopName ?? 'Dealer Store',
                                createdAt: DateTime.now(),
                                tags: ['water', 'can', 'refill', '20l'],
                              ),
                            );
                          }

                          // 2. New Can
                          if (newCanProd != null) {
                            await productRepo.updateProduct(newCanProd.copyWith(
                              price: nPrice,
                              stockQuantity: newCanStock.toDouble(),
                              imageUrls: ['assets/images/water_can_20l.png'],
                            ));
                          } else {
                            await productRepo.addProduct(
                              ProductModel(
                                id: '',
                                name: '20L Water Can (New with Can)',
                                description: 'Brand new 20L water can with initial security deposit.',
                                price: nPrice,
                                categoryId: 'water_cans',
                                categoryName: 'Water & Beverages',
                                imageUrls: ['assets/images/water_can_20l.png'],
                                unit: '20L Can + Jar',
                                stockQuantity: newCanStock.toDouble(),
                                dealerId: user.id,
                                dealerName: user.shopName ?? 'Dealer Store',
                                createdAt: DateTime.now(),
                                tags: ['water', 'can', 'new', 'deposit', '20l'],
                              ),
                            );
                          }

                          // 3. Single 1L Bottle
                          if (bottle1LProd != null) {
                            await productRepo.updateProduct(bottle1LProd.copyWith(
                              price: b1Price,
                              stockQuantity: bottle1LStock.toDouble(),
                            ));
                          } else {
                            await productRepo.addProduct(
                              ProductModel(
                                id: '',
                                name: '1L Mineral Water (Single)',
                                description: '1 Litre pure packaged drinking water bottle.',
                                price: b1Price,
                                categoryId: 'water_cans',
                                categoryName: 'Water & Beverages',
                                imageUrls: ['assets/images/water_can_20l.png'],
                                unit: '1 Litre',
                                stockQuantity: bottle1LStock.toDouble(),
                                dealerId: user.id,
                                dealerName: user.shopName ?? 'Dealer Store',
                                createdAt: DateTime.now(),
                                tags: ['water', 'bottle', '1l'],
                              ),
                            );
                          }

                          // 4. Pack of 6 Bottles
                          if (bottlePackProd != null) {
                            await productRepo.updateProduct(bottlePackProd.copyWith(
                              price: bPPrice,
                              stockQuantity: bottlePackStock.toDouble(),
                            ));
                          } else {
                            await productRepo.addProduct(
                              ProductModel(
                                id: '',
                                name: '1L Mineral Water (Pack of 6)',
                                description: 'Pack of 6 x 1L pure mineral water bottles.',
                                price: bPPrice,
                                categoryId: 'water_cans',
                                categoryName: 'Water & Beverages',
                                imageUrls: ['assets/images/water_can_20l.png'],
                                unit: '6 x 1L Pack',
                                stockQuantity: bottlePackStock.toDouble(),
                                dealerId: user.id,
                                dealerName: user.shopName ?? 'Dealer Store',
                                createdAt: DateTime.now(),
                                tags: ['water', 'bottle', 'pack', '6pack'],
                              ),
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Water inventory & pricing updated successfully!'),
                                backgroundColor: Color(0xFF059669),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Save Stock & Prices', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaterStockItemCard({
    required String title,
    required String subtitle,
    required int stock,
    required TextEditingController priceCtrl,
    required IconData icon,
    required Function(int) onStockChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF059669), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Price field
              Expanded(
                flex: 3,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      prefixText: ' ₹ ',
                      prefixStyle: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Stock stepper
              Expanded(
                flex: 4,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: stock > 0 ? () => onStockChanged(stock - 1) : null,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                      Text('$stock units', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF059669))),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => onStockChanged(stock + 1),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(
    BuildContext context,
    List<ProductModel> rawProducts,
    List<CategoryModel> categories,
  ) {
    String tempStockFilter = _stockFilter;
    String tempCategoryId = _selectedCategoryId;
    String tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculate filtered preview count inside modal
          var previewList = List<ProductModel>.from(rawProducts);
          if (tempCategoryId != 'All') {
            previewList = previewList.where((p) => p.categoryId == tempCategoryId).toList();
          }
          if (_searchQuery.isNotEmpty) {
            previewList = previewList.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }
          switch (tempStockFilter) {
            case 'In Stock':
              previewList = previewList.where((p) => p.inStock && p.stockQuantity >= 10).toList();
              break;
            case 'Low Stock':
              previewList = previewList.where((p) => p.stockQuantity < 10 && p.stockQuantity > 0).toList();
              break;
            case 'Out of Stock':
              previewList = previewList.where((p) => !p.inStock || p.stockQuantity == 0).toList();
              break;
            case 'Offers & BOGO':
              previewList = previewList.where((p) => p.hasSpecialOffer).toList();
              break;
          }

          // Stock counts for badges inside modal
          final inStockCount = rawProducts.where((p) => p.inStock && p.stockQuantity >= 10).length;
          final lowStockCount = rawProducts.where((p) => p.stockQuantity < 10 && p.stockQuantity > 0).length;
          final outOfStockCount = rawProducts.where((p) => !p.inStock || p.stockQuantity == 0).length;
          final offersCount = rawProducts.where((p) => p.hasSpecialOffer).length;

          final bool isDirty = tempStockFilter != 'All' || tempCategoryId != 'All' || tempSortBy != 'Default';

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Top Drag Handle
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // 2. Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF059669), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter & Sort Inventory',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Showing ${previewList.length} of ${rawProducts.length} items',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (isDirty)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempStockFilter = 'All';
                              tempCategoryId = 'All';
                              tempSortBy = 'Default';
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 3. Scrollable Filter Sections
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      // Section A: Sort By
                      _buildSectionHeader('Sort Inventory By', Icons.sort_rounded),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.7,
                        children: [
                          _buildSortGridCard('Default', 'Recent / Default', Icons.access_time_rounded, tempSortBy, (v) => setModalState(() => tempSortBy = v)),
                          _buildSortGridCard('Name: A-Z', 'Alphabetical', Icons.sort_by_alpha_rounded, tempSortBy, (v) => setModalState(() => tempSortBy = v)),
                          _buildSortGridCard('Price: Low to High', 'Price: Low → High', Icons.arrow_upward_rounded, tempSortBy, (v) => setModalState(() => tempSortBy = v)),
                          _buildSortGridCard('Price: High to Low', 'Price: High → Low', Icons.arrow_downward_rounded, tempSortBy, (v) => setModalState(() => tempSortBy = v)),
                          _buildSortGridCard('Stock: Low to High', 'Stock: Low → High', Icons.warning_amber_rounded, tempSortBy, (v) => setModalState(() => tempSortBy = v)),
                          _buildSortGridCard('Stock: High to Low', 'Stock: High → Low', Icons.inventory_2_rounded, tempSortBy, (v) => setModalState(() => tempSortBy = v)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Section B: Stock Health & Status
                      _buildSectionHeader('Stock Health & Status', Icons.inventory_2_outlined),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _buildStockStatusTile(
                            title: 'All Products',
                            subtitle: 'Show entire inventory stock',
                            count: rawProducts.length,
                            isSelected: tempStockFilter == 'All',
                            icon: Icons.apps_rounded,
                            accentColor: const Color(0xFF0F172A),
                            onTap: () => setModalState(() => tempStockFilter = 'All'),
                          ),
                          const SizedBox(height: 8),
                          _buildStockStatusTile(
                            title: 'In Stock (10+ Units)',
                            subtitle: 'Healthy available stock',
                            count: inStockCount,
                            isSelected: tempStockFilter == 'In Stock',
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: const Color(0xFF059669),
                            onTap: () => setModalState(() => tempStockFilter = 'In Stock'),
                          ),
                          const SizedBox(height: 8),
                          _buildStockStatusTile(
                            title: 'Low Stock (< 10 Units)',
                            subtitle: 'Needs replenishment soon',
                            count: lowStockCount,
                            isSelected: tempStockFilter == 'Low Stock',
                            icon: Icons.warning_amber_rounded,
                            accentColor: const Color(0xFFD97706),
                            onTap: () => setModalState(() => tempStockFilter = 'Low Stock'),
                          ),
                          const SizedBox(height: 8),
                          _buildStockStatusTile(
                            title: 'Out of Stock (0 Units)',
                            subtitle: 'Items currently unavailable',
                            count: outOfStockCount,
                            isSelected: tempStockFilter == 'Out of Stock',
                            icon: Icons.cancel_outlined,
                            accentColor: const Color(0xFFEF4444),
                            onTap: () => setModalState(() => tempStockFilter = 'Out of Stock'),
                          ),
                          const SizedBox(height: 8),
                          _buildStockStatusTile(
                            title: 'Special Offers & BOGO',
                            subtitle: 'Active discounts & promo deals',
                            count: offersCount,
                            isSelected: tempStockFilter == 'Offers & BOGO',
                            icon: Icons.local_fire_department_rounded,
                            accentColor: const Color(0xFFEA580C),
                            onTap: () => setModalState(() => tempStockFilter = 'Offers & BOGO'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Section C: Product Categories
                      _buildSectionHeader('Product Categories', Icons.category_rounded),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCategoryBadgeChip(
                            label: 'All Categories',
                            count: rawProducts.length,
                            isSelected: tempCategoryId == 'All',
                            icon: Icons.category_rounded,
                            onTap: () => setModalState(() => tempCategoryId = 'All'),
                          ),
                          ...categories.map((c) {
                            final catCount = rawProducts.where((p) => p.categoryId == c.id).length;
                            return _buildCategoryBadgeChip(
                              label: c.name,
                              count: catCount,
                              isSelected: tempCategoryId == c.id,
                              icon: null,
                              onTap: () => setModalState(() => tempCategoryId = c.id),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Sticky Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            tempStockFilter = 'All';
                            tempCategoryId = 'All';
                            tempSortBy = 'Default';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                        child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _stockFilter = tempStockFilter;
                              _selectedCategoryId = tempCategoryId;
                              _sortBy = tempSortBy;
                            });
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            'Show ${previewList.length} Products',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF059669)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildSortGridCard(String key, String label, IconData icon, String currentSort, Function(String) onSelect) {
    final isSelected = currentSort == key;
    return InkWell(
      onTap: () => onSelect(key),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 16, color: Color(0xFF059669)),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatusTile({
    required String title,
    required String subtitle,
    required int count,
    required bool isSelected,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669).withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF059669) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadgeChip({
    required String label,
    required int count,
    required bool isSelected,
    required IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B3C26) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B3C26) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF059669)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

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
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          final rawProducts = snapshot.data ?? [];
          final products = _filterProducts(rawProducts);

          // Calculate active filter count for badge
          int activeFiltersCount = 0;
          if (_stockFilter != 'All') activeFiltersCount++;
          if (_selectedCategoryId != 'All') activeFiltersCount++;
          if (_sortBy != 'Default') activeFiltersCount++;
          if (_searchQuery.isNotEmpty) activeFiltersCount++;

          final bool hasActiveFilters = activeFiltersCount > 0;

          return StreamBuilder<List<CategoryModel>>(
            stream: CategoryRepository().getCategories(),
            builder: (context, catSnap) {
              final categories = catSnap.data ?? [];
              final selectedCategoryName = categories.where((c) => c.id == _selectedCategoryId).firstOrNull?.name ?? _selectedCategoryId;

              return RefreshIndicator(
                color: const Color(0xFF059669),
                onRefresh: () async {
                  setState(() {});
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // Top Collapsible Header
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Search Bar with Filter Modal Trigger
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Search Input
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                        decoration: InputDecoration(
                                          hintText: 'Search products or SKU...',
                                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() => _searchQuery = '');
                                                  },
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: const Color(0xFFF1F5F9),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Filter Bottom Sheet Button with Badge
                                    InkWell(
                                      onTap: () => _showFiltersBottomSheet(context, rawProducts, categories),
                                      borderRadius: BorderRadius.circular(14),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: hasActiveFilters ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: hasActiveFilters ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              size: 18,
                                              color: hasActiveFilters ? Colors.white : const Color(0xFF334155),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Filter',
                                              style: TextStyle(
                                                color: hasActiveFilters ? Colors.white : const Color(0xFF334155),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            if (activeFiltersCount > 0) ...[
                                              const SizedBox(width: 5),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: hasActiveFilters ? Colors.white : const Color(0xFF059669),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$activeFiltersCount',
                                                  style: TextStyle(
                                                    color: hasActiveFilters ? const Color(0xFF059669) : Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Quick Category Horizontal Filter Bar
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildQuickCategoryChip('All', 'All Items', Icons.apps_rounded, rawProducts.length),
                                      ...categories.map((c) {
                                        final catCount = rawProducts.where((p) => p.categoryId == c.id).length;
                                        return _buildQuickCategoryChip(c.id, c.name, null, catCount);
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Active Filter Badges Strip (Visible when filters are active)
                          if (hasActiveFilters)
                            Container(
                              color: const Color(0xFFF8FAFC),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    if (_stockFilter != 'All')
                                      _buildActiveTag(
                                        label: 'Stock: $_stockFilter',
                                        onRemove: () => setState(() => _stockFilter = 'All'),
                                      ),
                                    if (_selectedCategoryId != 'All')
                                      _buildActiveTag(
                                        label: 'Category: $selectedCategoryName',
                                        onRemove: () => setState(() => _selectedCategoryId = 'All'),
                                      ),
                                    if (_sortBy != 'Default')
                                      _buildActiveTag(
                                        label: 'Sort: $_sortBy',
                                        onRemove: () => setState(() => _sortBy = 'Default'),
                                      ),
                                    if (_searchQuery.isNotEmpty)
                                      _buildActiveTag(
                                        label: 'Search: "$_searchQuery"',
                                        onRemove: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _stockFilter = 'All';
                                          _selectedCategoryId = 'All';
                                          _sortBy = 'Default';
                                          _searchQuery = '';
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 6),

                          // 2. Water Cans Quick Stock Banner
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF0FDF4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFF059669), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Water Can Inventory',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Builder(
                                          builder: (context) {
                                            final refillQty = rawProducts.where((p) => p.name.toLowerCase().contains('refill') || (p.name.toLowerCase().contains('20l') && !p.name.toLowerCase().contains('new'))).firstOrNull?.stockQuantity ?? 0;
                                            final newQty = rawProducts.where((p) => p.name.toLowerCase().contains('new') && (p.name.toLowerCase().contains('can') || p.name.toLowerCase().contains('20l'))).firstOrNull?.stockQuantity ?? 0;
                                            final packQty = rawProducts.where((p) => p.name.toLowerCase().contains('pack of 6') || (p.name.toLowerCase().contains('1l') && p.name.toLowerCase().contains('pack'))).firstOrNull?.stockQuantity ?? 0;
                                            return Text(
                                              '20L Refill (${refillQty.toInt()}) • 20L New (${newQty.toInt()}) • 1L (${packQty.toInt()})',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _showWaterStockModal(context, rawProducts, user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 3. Results Count Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${products.length} of ${rawProducts.length} items',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                ),
                                if (_sortBy != 'Default')
                                  Text(
                                    'Sorted by $_sortBy',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),

                    // Product Items List or Empty State
                    if (products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF059669)),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  rawProducts.isEmpty ? 'No Products in Inventory' : 'No Products Match Selected Filters',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rawProducts.isEmpty
                                      ? 'Tap the + button above to list your store products.'
                                      : 'Try adjusting your stock filters or search keywords.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                if (hasActiveFilters) ...[
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _stockFilter = 'All';
                                        _selectedCategoryId = 'All';
                                        _sortBy = 'Default';
                                        _searchQuery = '';
                                      });
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Clear All Filters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF059669),
                                      side: const BorderSide(color: Color(0xFF059669)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _InventoryCard(product: products[i]),
                            ),
                            childCount: products.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveTag({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategoryChip(String id, String label, IconData? icon, int count) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryId = id),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B3C26) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF0B3C26) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: isSelected ? Colors.white : const Color(0xFF046A38)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    String statusText = 'Stock: ${product.stockQuantity.toInt()}';

    if (isOut) {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      statusText = 'Out of Stock';
    } else if (isLow) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      statusText = 'Low Stock (${product.stockQuantity.toInt()})';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Builder(
              builder: (context) {
                if (product.imageUrls.isNotEmpty) {
                  final img = product.imageUrls.first;
                  if (img.startsWith('assets/')) {
                    return Image.asset(img, width: 68, height: 68, fit: BoxFit.cover);
                  }
                  if (img.startsWith('http')) {
                    return Image.network(
                      img,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/water_can_20l.png',
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                }
                if (product.name.toLowerCase().contains('water') || product.name.toLowerCase().contains('can')) {
                  return Image.asset('assets/images/water_can_20l.png', width: 68, height: 68, fit: BoxFit.cover);
                }
                return Container(
                  width: 68,
                  height: 68,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
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
                    if (product.hasSpecialOffer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF97316)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.offerLabel ?? 'OFFER',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                      ),
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
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => context.push('/add-product', extra: product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Delete Product?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}" from your store inventory? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ProductRepository().deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} deleted from inventory.'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
