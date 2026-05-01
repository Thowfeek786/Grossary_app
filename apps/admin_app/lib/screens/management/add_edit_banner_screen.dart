import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:repository/repository.dart';
import '../../providers/management_provider.dart';

class AddEditBannerScreen extends StatefulWidget {
  final BannerModel? banner;
  const AddEditBannerScreen({super.key, this.banner});

  @override
  State<AddEditBannerScreen> createState() => _AddEditBannerScreenState();
}

class _AddEditBannerScreenState extends State<AddEditBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _linkCtrl;
  XFile? _image;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.banner?.title);
    _descCtrl = TextEditingController(text: widget.banner?.subtitle);
    _linkCtrl = TextEditingController(text: widget.banner?.actionUrl);
    _isActive = widget.banner?.isActive ?? true;
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
      String imageUrl = widget.banner?.imageUrl ?? '';
      if (_image != null) {
        imageUrl = await StorageRepository().uploadBannerImage(
          File(_image!.path), 
          'banner_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image'), backgroundColor: AppColors.error));
        return;
      }

      final banner = BannerModel(
        id: widget.banner?.id ?? '',
        title: _titleCtrl.text.trim(),
        subtitle: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        actionUrl: _linkCtrl.text.trim(),
        isActive: _isActive,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
        sortOrder: widget.banner?.sortOrder ?? 0,
      );

      bool success;
      if (widget.banner == null) {
        success = await management.addBanner(banner);
      } else {
        success = await management.updateBanner(banner);
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
        title: widget.banner == null ? 'Add Banner' : 'Edit Banner',
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
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)),
                  child: _image != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                    : widget.banner?.imageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.banner!.imageUrl, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 48),
                          SizedBox(height: 8),
                          Text('Add Banner Image', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Banner Title',
                controller: _titleCtrl,
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                controller: _descCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Action Link (Optional)',
                controller: _linkCtrl,
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
                label: widget.banner == null ? 'Create Banner' : 'Update Banner',
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
