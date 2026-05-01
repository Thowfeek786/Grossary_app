import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/management_provider.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  XFile? _image;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name);
    _isActive = widget.category?.isActive ?? true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final management = context.read<AdminManagementProvider>();
    management.setLoading(true);
    
    try {
      String imageUrl = widget.category?.imageUrl ?? '';
      if (_image != null) {
        imageUrl = await StorageRepository().uploadCategoryImage(
          File(_image!.path), 
          'cat_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image'), backgroundColor: AppColors.error));
        return;
      }

      final category = CategoryModel(
        id: widget.category?.id ?? '',
        name: _nameCtrl.text.trim(),
        imageUrl: imageUrl,
        isActive: _isActive,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        sortOrder: widget.category?.sortOrder ?? 0,
      );

      bool success;
      if (widget.category == null) {
        success = await management.addCategory(category);
      } else {
        success = await management.updateCategory(category);
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
    final isLoading = context.watch<AdminManagementProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: widget.category == null ? 'Add Category' : 'Edit Category',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                  child: _image != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                    : widget.category?.imageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.category!.imageUrl!, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 48),
                          SizedBox(height: 8),
                          Text('Add Category Image', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Category Name',
                controller: _nameCtrl,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              AppButton(
                label: widget.category == null ? 'Create Category' : 'Update Category',
                isLoading: isLoading,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
