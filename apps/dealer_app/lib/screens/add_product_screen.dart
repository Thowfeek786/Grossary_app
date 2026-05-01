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
    _unitCtrl = TextEditingController(text: widget.product?.unit);
    _stockCtrl = TextEditingController(text: widget.product?.stockQuantity.toString());
    _selectedCategory = widget.product?.categoryId;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
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
        imageUrls = [url]; // For simplicity, replace with new one in this demo
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: widget.product == null ? 'Add New Product' : 'Edit Product'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                  child: _image != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                    : widget.product?.imageUrls.isNotEmpty == true
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.product!.imageUrls.first, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 48),
                          SizedBox(height: 8),
                          Text('Add Product Image', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(label: 'Product Name', controller: _nameCtrl, validator: Validators.required),
              const SizedBox(height: 16),
              AppTextField(label: 'Description', controller: _descCtrl, maxLines: 3, validator: Validators.required),
              const SizedBox(height: 16),
              StreamBuilder<List<CategoryModel>>(
                stream: CategoryRepository().getCategories(),
                builder: (context, snapshot) {
                  final cats = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => v == null ? 'Please select a category' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Price (₹)', controller: _priceCtrl, keyboardType: TextInputType.number, validator: Validators.required)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'Discount (₹)', controller: _discountCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Unit', controller: _unitCtrl, validator: Validators.required)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'Stock', controller: _stockCtrl, keyboardType: TextInputType.number, validator: Validators.required)),
                ],
              ),
              const SizedBox(height: 32),
              AppButton(label: widget.product == null ? 'Publish Product' : 'Update Product', isLoading: _isLoading, onTap: _submit),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
