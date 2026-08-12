import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/management_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _stockCtrl;
  
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedDealerId;
  String? _selectedDealerName;
  bool _isFeatured = false;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name);
    _descCtrl = TextEditingController(text: p?.description);
    _priceCtrl = TextEditingController(text: p?.price.toString());
    _discountCtrl = TextEditingController(text: p?.discountPrice?.toString());
    _unitCtrl = TextEditingController(text: p?.unit ?? '1 kg');
    _stockCtrl = TextEditingController(text: p?.stockQuantity.toString() ?? '100');
    _selectedCategoryId = p?.categoryId;
    _selectedCategoryName = p?.categoryName;
    _selectedDealerId = p?.dealerId;
    _selectedDealerName = p?.dealerName;
    _isFeatured = p?.isFeatured ?? false;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedDealerId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Category and Dealer'), backgroundColor: AppColors.error));
       return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final management = context.read<AdminManagementProvider>();
    management.setLoading(true);
    
    try {
      List<String> imageUrls = widget.product?.imageUrls ?? [];
      
      if (_image != null) {
        final url = await StorageRepository().uploadProductImage(
          File(_image!.path), 
          'prod_${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls = [url]; // For simplicity, we handle one image now
      }

      if (imageUrls.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('Please select a product image'), backgroundColor: AppColors.error));
        return;
      }

      final p = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        discountPrice: _discountCtrl.text.isNotEmpty ? double.parse(_discountCtrl.text) : null,
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        dealerId: _selectedDealerId,
        dealerName: _selectedDealerName,
        imageUrls: imageUrls,
        unit: _unitCtrl.text.trim(),
        stockQuantity: double.parse(_stockCtrl.text),
        isFeatured: _isFeatured,
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (widget.product == null) {
        success = await management.addProduct(p);
      } else {
        success = await management.updateProduct(p);
      }

      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      management.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final management = context.watch<AdminManagementProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: widget.product == null ? 'Add Product' : 'Edit Product',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Image', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 170,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: _image != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                              : (widget.product?.imageUrls.isNotEmpty == true)
                                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(widget.product!.imageUrls.first, fit: BoxFit.cover))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF6366F1), size: 28),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('Tap to upload product image', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        const Text('JPG, PNG up to 5MB', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                      ],
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Product Name', controller: _nameCtrl, validator: Validators.required),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Description', controller: _descCtrl, maxLines: 3, validator: Validators.required),
                      const SizedBox(height: 16),

                      // Category Selection
                      StreamBuilder<List<CategoryModel>>(
                        stream: management.getCategories(),
                        builder: (context, snapshot) {
                          final cats = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedCategoryId = v;
                                _selectedCategoryName = cats.firstWhere((c) => c.id == v).name;
                              });
                            },
                            validator: (v) => v == null ? 'Category is required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dealer Selection
                      StreamBuilder<List<UserModel>>(
                        stream: management.getUsers(),
                        builder: (context, snapshot) {
                          final dealers = (snapshot.data ?? []).where((u) => u.role == UserRole.dealer).toList();
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedDealerId,
                            decoration: InputDecoration(
                              labelText: 'Assign Vendor / Dealer',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: dealers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedDealerId = v;
                                _selectedDealerName = dealers.firstWhere((d) => d.id == v).name;
                              });
                            },
                            validator: (v) => v == null ? 'Vendor is required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: AppTextField(label: 'Price (₹)', controller: _priceCtrl, keyboardType: TextInputType.number, validator: Validators.required)),
                          const SizedBox(width: 16),
                          Expanded(child: AppTextField(label: 'Discount Price (₹)', controller: _discountCtrl, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: AppTextField(label: 'Unit (e.g. 1 kg)', controller: _unitCtrl, validator: Validators.required)),
                          const SizedBox(width: 16),
                          Expanded(child: AppTextField(label: 'Stock Quantity', controller: _stockCtrl, keyboardType: TextInputType.number, validator: Validators.required)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SwitchListTile(
                          title: const Text('Featured Product', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                          subtitle: const Text('Highlight on app homepage', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          value: _isFeatured,
                          onChanged: (v) => setState(() => _isFeatured = v),
                          activeThumbColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: management.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: management.isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                            widget.product == null ? 'Create Product' : 'Save Changes',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                  ),
                ),
                if (widget.product != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final confirm = await AppHelpers.showConfirmDialog(context, title: 'Delete Product', content: 'Are you sure you want to delete this product?');
                        if (confirm == true) {
                          await management.deleteProduct(widget.product!.id);
                          if (mounted) navigator.pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
          ),
        ),
      ),
    );
  }
}
