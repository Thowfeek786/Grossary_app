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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product image'), backgroundColor: AppColors.error));
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
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: widget.product == null ? 'Add Product' : 'Edit Product',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text('Product Image', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
               const SizedBox(height: 16),
               GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                  child: _image != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                    : (widget.product?.imageUrls.isNotEmpty == true)
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.product!.imageUrls.first, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 48),
                          SizedBox(height: 8),
                          Text('Upload Product Image', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                ),
               ),
               const SizedBox(height: 24),
               const Text('Product Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
               const SizedBox(height: 16),
               AppTextField(label: 'Name', controller: _nameCtrl, validator: Validators.required),
               const SizedBox(height: 16),
               AppTextField(label: 'Description', controller: _descCtrl, maxLines: 3, validator: Validators.required),
               const SizedBox(height: 16),
               
               // Category Selection
               StreamBuilder<List<CategoryModel>>(
                 stream: management.getCategories(),
                 builder: (context, snapshot) {
                   final cats = snapshot.data ?? [];
                   return DropdownButtonFormField<String>(
                     value: _selectedCategoryId,
                     decoration: const InputDecoration(labelText: 'Category'),
                     items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                     onChanged: (v) {
                       setState(() {
                         _selectedCategoryId = v;
                         _selectedCategoryName = cats.firstWhere((c) => c.id == v).name;
                       });
                     },
                     validator: (v) => v == null ? 'Required' : null,
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
                     value: _selectedDealerId,
                     decoration: const InputDecoration(labelText: 'Assign to Dealer / Vendor'),
                     items: dealers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                     onChanged: (v) {
                       setState(() {
                         _selectedDealerId = v;
                         _selectedDealerName = dealers.firstWhere((d) => d.id == v).name;
                       });
                     },
                     validator: (v) => v == null ? 'Required' : null,
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
                   Expanded(child: AppTextField(label: 'Unit (e.g. 1 kg)', controller: _unitCtrl, validator: Validators.required)),
                   const SizedBox(width: 16),
                   Expanded(child: AppTextField(label: 'Stock', controller: _stockCtrl, keyboardType: TextInputType.number, validator: Validators.required)),
                 ],
               ),
               const SizedBox(height: 16),
               SwitchListTile(
                 title: const Text('Featured Product', style: TextStyle(fontWeight: FontWeight.w600)),
                 subtitle: const Text('Highlighted in user home screen'),
                 value: _isFeatured,
                 onChanged: (v) => setState(() => _isFeatured = v),
                 activeColor: AppColors.primary,
               ),
               const SizedBox(height: 40),
               AppButton(
                 label: widget.product == null ? 'Create Product' : 'Save Changes',
                 isLoading: management.isLoading,
                 onTap: _submit,
               ),
               if (widget.product != null) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Delete Product',
                    variant: AppButtonVariant.outlined,
                    onTap: () async {
                      final confirm = await AppHelpers.showConfirmDialog(context, title: 'Delete Product', content: 'Are you sure you want to delete this product?');
                      if (confirm == true) {
                         await management.deleteProduct(widget.product!.id);
                         if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
               ],
               const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
