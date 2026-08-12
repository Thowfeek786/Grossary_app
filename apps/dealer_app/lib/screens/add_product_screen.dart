import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../providers/auth_provider.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AddProductScreen({super.key, this.product});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _stockCtrl;
  String? _selectedCategory;
  XFile? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name);
    _descCtrl = TextEditingController(text: widget.product?.description);
    _priceCtrl = TextEditingController(text: widget.product?.price.toString());
    _discountCtrl = TextEditingController(text: widget.product?.discountPrice?.toString());
    _unitCtrl = TextEditingController(text: widget.product?.unit ?? '1 kg');
    _stockCtrl = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '50');
    _selectedCategory = widget.product?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _unitCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a product category'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = context.read<DealerAuthProvider>().user!;
      final cats = await CategoryRepository().getCategories().first;
      final category = cats.firstWhere((c) => c.id == _selectedCategory);

      List<String> imageUrls = widget.product?.imageUrls ?? [];
      if (_image != null) {
        final url = await StorageRepository().uploadProductImage(
          File(_image!.path),
          'temp_${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls = [url];
      }

      final p = ProductModel(
        id: widget.product?.id ?? '',
        dealerId: user.id,
        dealerName: user.name,
        categoryId: _selectedCategory!,
        categoryName: category.name,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrls: imageUrls,
        price: double.parse(_priceCtrl.text),
        discountPrice: _discountCtrl.text.isNotEmpty ? double.parse(_discountCtrl.text) : null,
        unit: _unitCtrl.text.trim(),
        stockQuantity: double.parse(_stockCtrl.text),
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (widget.product == null) {
        await ProductRepository().addProduct(p);
      } else {
        await ProductRepository().updateProduct(p);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: widget.product == null ? 'Add Store Product' : 'Edit Product Details',
        backgroundColor: const Color(0xFF0B3C26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Upload Container
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: _image != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                      : widget.product?.imageUrls.isNotEmpty == true
                          ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(widget.product!.imageUrls.first, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF059669), size: 32),
                                ),
                                const SizedBox(height: 10),
                                const Text('Tap to Upload Product Photo', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 14)),
                                const SizedBox(height: 2),
                                const Text('Supports PNG, JPG (High resolution recommended)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 24),

              // Product Info Form Body Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Product Name',
                      controller: _nameCtrl,
                      hint: 'e.g. Fresh Organic Tomatoes',
                      prefixIcon: Icons.shopping_bag_outlined,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Description',
                      controller: _descCtrl,
                      hint: 'Describe farm freshness, origin or quality specs...',
                      maxLines: 3,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 14),

                    StreamBuilder<List<CategoryModel>>(
                      stream: CategoryRepository().getCategories(),
                      builder: (context, snapshot) {
                        final cats = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: cats.any((c) => c.id == _selectedCategory) ? _selectedCategory : null,
                          decoration: InputDecoration(
                            labelText: 'Store Category',
                            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF64748B), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                          validator: (v) => v == null ? 'Please select a category' : null,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pricing & Stock Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing & Inventory Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Regular Price (₹)',
                            controller: _priceCtrl,
                            hint: 'e.g. 120',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                            validator: Validators.required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Discount Price (₹)',
                            controller: _discountCtrl,
                            hint: 'e.g. 99 (Optional)',
                            prefixIcon: Icons.local_offer_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Package Unit',
                            controller: _unitCtrl,
                            hint: 'e.g. 1 kg / 500 g',
                            prefixIcon: Icons.scale_outlined,
                            validator: Validators.required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Initial Stock Qty',
                            controller: _stockCtrl,
                            hint: 'e.g. 50',
                            prefixIcon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            validator: Validators.required,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.product == null ? 'Publish Product to Store' : 'Save Product Changes',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
