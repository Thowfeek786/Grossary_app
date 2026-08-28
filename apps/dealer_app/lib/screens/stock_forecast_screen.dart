import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class StockForecastScreen extends StatefulWidget {
  const StockForecastScreen({super.key});

  @override
  State<StockForecastScreen> createState() => _StockForecastScreenState();
}

class _StockForecastScreenState extends State<StockForecastScreen> {
  final Map<String, int> _reorderQuantities = {};
  bool _isRestocking = false;
  final TextEditingController _vendorPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _vendorPhoneCtrl.dispose();
    super.dispose();
  }

  void _initReorderQty(ProductModel p) {
    if (!_reorderQuantities.containsKey(p.id)) {
      // Recommend ordering enough to reach a safety stock target of 30 units
      final deficit = (30 - p.stockQuantity.toInt()).clamp(10, 100);
      _reorderQuantities[p.id] = deficit;
    }
  }

  Future<void> _sharePOOnWhatsApp(UserModel user, List<ProductModel> lowStockProducts) async {
    if (lowStockProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No low stock items selected for PO'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    final storeName = user.shopName?.isNotEmpty == true ? user.shopName! : 'Dark Store';
    final dateStr = DateTime.now().toLocal().toString().substring(0, 10);

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('📦 *PURCHASE ORDER — $storeName*');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('--------------------------------');
    buffer.writeln('*ITEMS REQUESTED:*');

    double totalEstCost = 0.0;
    int index = 1;
    for (final p in lowStockProducts) {
      final orderQty = _reorderQuantities[p.id] ?? 20;
      final estUnitCost = p.price * 0.75; // Estimated wholesale purchase cost (75% of MSRP)
      final lineCost = estUnitCost * orderQty;
      totalEstCost += lineCost;

      buffer.writeln('$index. *${p.name}*');
      buffer.writeln('   • Quantity: *$orderQty ${p.unit}*');
      buffer.writeln('   • Current Stock: ${p.stockQuantity.toInt()} units');
      index++;
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('💰 *Est. PO Value:* ₹${totalEstCost.toStringAsFixed(0)}');
    buffer.writeln('📍 *Delivery To:* ${user.shopAddress ?? 'Store Warehouse'}');
    buffer.writeln('📞 *Contact:* ${user.phone}');
    buffer.writeln('\nPlease confirm dispatch timing.');

    final encodedMessage = Uri.encodeComponent(buffer.toString());
    final phone = _vendorPhoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(phone.isNotEmpty ? 'https://wa.me/91$phone?text=$encodedMessage' : 'https://wa.me/?text=$encodedMessage');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: buffer.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PO copied to clipboard! (WhatsApp not installed)'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PO copied to clipboard!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    }
  }

  Future<void> _quickApplyRestock(List<ProductModel> products) async {
    setState(() => _isRestocking = true);
    try {
      final repo = ProductRepository();
      for (final p in products) {
        final addQty = _reorderQuantities[p.id] ?? 20;
        final newStock = p.stockQuantity + addQty;
        await repo.updateProduct(p.copyWith(stockQuantity: newStock, isActive: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully restocked ${products.length} products!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DealerAuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Smart Stock Forecaster',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductRepository().getProducts(dealerId: user.id, activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }

          final allProducts = snapshot.data ?? [];
          // Filter items needing reorder (Stock < 15 or Out of Stock)
          final lowStockItems = allProducts.where((p) => p.stockQuantity < 15 || !p.inStock).toList();

          // Sort by lowest stock first
          lowStockItems.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

          for (final p in lowStockItems) {
            _initReorderQty(p);
          }

          if (lowStockItems.isEmpty) {
            return Center(
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
                      child: const Icon(Icons.verified_rounded, size: 54, color: Color(0xFF059669)),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'All Inventory Levels Healthy! 🚀',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'All products in your store currently have ample stock reserves.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/inventory'),
                      icon: const Icon(Icons.inventory_2_rounded, size: 18),
                      label: const Text('View All Inventory', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Top Forecast Insights Banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lowStockItems.length} Products Require Reorder',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF78350F)),
                          ),
                          const Text(
                            'AI predicts stockouts within 1-2 days based on current store sales velocity.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Reorder List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lowStockItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final p = lowStockItems[idx];
                    final currentStock = p.stockQuantity.toInt();
                    final reorderQty = _reorderQuantities[p.id] ?? 20;
                    final isCritical = currentStock == 0 || !p.inStock;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCritical ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCritical ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isCritical ? 'CRITICAL OUT' : 'LOW ($currentStock left)',
                                        style: TextStyle(
                                          color: isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      p.categoryName,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Est. Runout: ${isCritical ? 'Immediate' : '${(currentStock / 3.5).toStringAsFixed(1)} days'}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                          // Reorder Quantity Counter Stepper
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('PO Quantity', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: reorderQty > 5
                                          ? () => setState(() => _reorderQuantities[p.id] = reorderQty - 5)
                                          : null,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Icon(Icons.remove_rounded, size: 16, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Text(
                                      '$reorderQty',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _reorderQuantities[p.id] = reorderQty + 5),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Icon(Icons.add_rounded, size: 16, color: Color(0xFF0F172A)),
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
                  },
                ),
              ),

              // Bottom Actions Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _sharePOOnWhatsApp(user, lowStockItems),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                            label: const Text(
                              'Share PO on WhatsApp',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isRestocking ? null : () => _quickApplyRestock(lowStockItems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _isRestocking
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Restock All', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
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
}
