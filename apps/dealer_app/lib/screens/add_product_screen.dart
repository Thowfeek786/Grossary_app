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
  late TextEditingController _offerValueCtrl;
  String? _selectedCategory;
  String _selectedOfferType = 'none';
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
    _selectedOfferType = widget.product?.offerType ?? 'none';
    _offerValueCtrl = TextEditingController(text: widget.product?.offerValue?.toString() ?? '');
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
    _offerValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  String? _getComputedOfferLabel() {
    switch (_selectedOfferType) {
      case 'bogo':
        return 'BUY 1 GET 1 FREE';
      case 'buy2get1':
        return 'BUY 2 GET 1 FREE';
      case 'percent':
        final val = _offerValueCtrl.text.trim();
        return val.isNotEmpty ? '$val% OFF' : 'SPECIAL % OFF';
      case 'flat':
        final val = _offerValueCtrl.text.trim();
        return val.isNotEmpty ? 'FLAT ₹$val OFF' : 'FLAT OFF';
      default:
        return null;
    }
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
        offerType: _selectedOfferType,
        offerLabel: _getComputedOfferLabel(),
        offerValue: _offerValueCtrl.text.isNotEmpty ? double.tryParse(_offerValueCtrl.text) : null,
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

              const SizedBox(height: 16),

              // Product Offers & Promotional Deals Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 22),
                        SizedBox(width: 8),
                        Text('Customer Offers & Deals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF9A3412))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Attach high-converting promotional banners to boost customer orders', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildOfferChip('none', 'No Offer', Icons.block_outlined),
                        _buildOfferChip('bogo', 'Buy 1 Get 1 (BOGO)', Icons.card_giftcard_rounded),
                        _buildOfferChip('buy2get1', 'Buy 2 Get 1 Free', Icons.auto_awesome_rounded),
                        _buildOfferChip('percent', '% Discount', Icons.percent_rounded),
                        _buildOfferChip('flat', 'Flat ₹ Cash Off', Icons.currency_rupee_rounded),
                      ],
                    ),

                    if (_selectedOfferType == 'percent' || _selectedOfferType == 'flat') ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        label: _selectedOfferType == 'percent' ? 'Discount Percentage (%)' : 'Flat Cash Discount (₹)',
                        controller: _offerValueCtrl,
                        hint: _selectedOfferType == 'percent' ? 'e.g. 20 for 20% OFF' : 'e.g. 50 for ₹50 OFF',
                        prefixIcon: _selectedOfferType == 'percent' ? Icons.percent_rounded : Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],

                    if (_selectedOfferType != 'none') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.preview_rounded, size: 18, color: Color(0xFFEA580C)),
                            const SizedBox(width: 8),
                            const Text('Customer Badge Preview: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF97316)]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getComputedOfferLabel() ?? 'OFFER',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildOfferChip(String type, String title, IconData icon) {
    final isSelected = _selectedOfferType == type;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF9A3412)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 12,
              color: isSelected ? Colors.white : const Color(0xFF78350F),
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFEA580C),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFFED7AA),
        ),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedOfferType = type);
        }
      },
    );
  }
}
