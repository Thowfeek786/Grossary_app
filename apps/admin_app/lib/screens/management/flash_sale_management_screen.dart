import 'dart:async';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_drawer.dart';

class FlashSaleManagementScreen extends StatefulWidget {
  const FlashSaleManagementScreen({super.key});

  @override
  State<FlashSaleManagementScreen> createState() => _FlashSaleManagementScreenState();
}

class _FlashSaleManagementScreenState extends State<FlashSaleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final FlashSaleRepository _flashRepo = FlashSaleRepository();
  final ProductRepository _productRepo = ProductRepository();

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _discountController;

  bool _isActive = true;
  DateTime _endTime = DateTime.now().add(const Duration(hours: 4));
  List<String> _selectedProductIds = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subtitleController = TextEditingController();
    _discountController = TextEditingController();
    _loadFlashSale();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final diff = _endTime.difference(DateTime.now()).inSeconds;
        setState(() {
          _secondsLeft = diff > 0 ? diff : 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    _subtitleController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashSale() async {
    final sale = await _flashRepo.getFlashSaleOnce();
    setState(() {
      _isActive = sale.isActive;
      _titleController.text = sale.title;
      _subtitleController.text = sale.subtitle;
      _discountController.text = sale.discountPercentage.toStringAsFixed(0);
      _endTime = sale.endTime.isAfter(DateTime.now()) ? sale.endTime : DateTime.now().add(const Duration(hours: 4));
      _selectedProductIds = List<String>.from(sale.productIds);
      _isLoading = false;
    });
  }

  String _formatTimer() {
    if (_secondsLeft <= 0) return 'Sale Expired';
    final h = (_secondsLeft ~/ 3600).toString().padLeft(2, '0');
    final m = ((_secondsLeft % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _pickEndDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _endTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveFlashSale() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final sale = FlashSaleModel(
        id: 'active',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        endTime: _endTime,
        productIds: _selectedProductIds,
        isActive: _isActive,
        discountPercentage: double.tryParse(_discountController.text) ?? 20.0,
      );

      await _flashRepo.saveFlashSale(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash Sale settings updated successfully!'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(),
      appBar: CustomAppBar(
        title: 'Flash Sale Management',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, size: 20, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Active Toggle Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: SwitchListTile(
                      value: _isActive,
                      activeThumbColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setState(() => _isActive = val);
                      },
                      title: const Text('Flash Sale Banner Active', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Text(
                        _isActive ? 'Visible to users on Home Screen' : 'Hidden from users',
                        style: TextStyle(color: _isActive ? const Color(0xFF6366F1) : Colors.grey, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isActive ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_fire_department_rounded, color: _isActive ? const Color(0xFFF59E0B) : Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Timer Preview Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_rounded, color: Color(0xFFFACC15), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _titleController.text.isNotEmpty ? _titleController.text : 'FLASH SALE ⚡',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatTimer(),
                                style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ends at: ${DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_endTime)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pickEndDateTime,
                            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                            label: const Text('Change Sale End Time'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // General Settings Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sale Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Flash Sale Title',
                            hintText: 'e.g. FLASH SALE ⚡',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _subtitleController,
                          decoration: InputDecoration(
                            labelText: 'Subtitle / Tagline',
                            hintText: 'e.g. Up to 50% OFF Fresh Produce',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Default Discount Banner (%)',
                            hintText: 'e.g. 20',
                            suffixText: '% OFF',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Select Included Products
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Flash Sale Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedProductIds.length} Selected',
                                style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search products by name...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<ProductModel>>(
                          stream: _productRepo.getProducts(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
                            }
                            final allProducts = snapshot.data!;
                            final filtered = allProducts.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: Text('No products found')),
                              );
                            }

                            return Container(
                              height: 280,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final p = filtered[i];
                                  final isSelected = _selectedProductIds.contains(p.id);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: const Color(0xFF6366F1),
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    subtitle: Text('₹${p.price.toStringAsFixed(0)} / ${p.unit}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedProductIds.add(p.id);
                                        } else {
                                          _selectedProductIds.remove(p.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFlashSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Flash Sale Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
