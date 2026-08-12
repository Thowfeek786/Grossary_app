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

  // Banner Navigation Target Dropdown options
  final List<Map<String, String>> _navigationTargets = [
    {'label': 'No Action / Display Only', 'value': ''},
    {'label': 'Categories Screen', 'value': '/categories'},
    {'label': 'All Products', 'value': '/products'},
    {'label': 'Coupons & Deals', 'value': '/coupons'},
    {'label': 'User Cart', 'value': '/cart'},
    {'label': 'Custom Action / Link', 'value': 'custom'},
  ];

  String _selectedTarget = '';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.banner?.title);
    _descCtrl = TextEditingController(text: widget.banner?.subtitle);
    _linkCtrl = TextEditingController(text: widget.banner?.actionUrl);
    _isActive = widget.banner?.isActive ?? true;

    final actionUrl = widget.banner?.actionUrl ?? '';
    final existingMatch = _navigationTargets.firstWhere(
      (t) => t['value'] == actionUrl && actionUrl.isNotEmpty,
      orElse: () => {'label': actionUrl.isNotEmpty ? 'Custom Action / Link' : 'No Action / Display Only', 'value': actionUrl.isNotEmpty ? 'custom' : ''},
    );
    _selectedTarget = existingMatch['value']!;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final messenger = ScaffoldMessenger.of(context);
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
        messenger.showSnackBar(const SnackBar(content: Text('Please select an image'), backgroundColor: AppColors.error));
        return;
      }

      final actionUrl = _selectedTarget == 'custom' ? _linkCtrl.text.trim() : _selectedTarget;

      final banner = BannerModel(
        id: widget.banner?.id ?? '',
        title: _titleCtrl.text.trim(),
        subtitle: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        actionUrl: actionUrl,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: widget.banner == null ? 'Add Banner' : 'Edit Banner',
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
                          Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6366F1), size: 48),
                          SizedBox(height: 8),
                          Text('Add Banner Image', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700)),
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
                label: 'Description / Subtitle',
                controller: _descCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ─── Banner Navigation Target Dropdown ───
              const Text('Banner Navigation Target',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTarget,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6366F1)),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _selectedTarget = val;
                          if (val != 'custom') {
                            _linkCtrl.text = val;
                          }
                        });
                      }
                    },
                    items: _navigationTargets.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['value'],
                        child: Row(
                          children: [
                            Icon(
                              t['value'] == '' ? Icons.block_rounded :
                              t['value'] == '/categories' ? Icons.category_rounded :
                              t['value'] == '/products' ? Icons.inventory_2_rounded :
                              t['value'] == '/coupons' ? Icons.confirmation_num_rounded :
                              t['value'] == '/cart' ? Icons.shopping_cart_rounded :
                              Icons.link_rounded,
                              size: 18,
                              color: const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 10),
                            Text(t['label']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedTarget == 'custom') ...[
                AppTextField(
                  label: 'Custom Action URL / Route',
                  controller: _linkCtrl,
                  hint: 'e.g. /category/dairy or https://example.com',
                ),
                const SizedBox(height: 16),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: const Color(0xFF6366F1),
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
