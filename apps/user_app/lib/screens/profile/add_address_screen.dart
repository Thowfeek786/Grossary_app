import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:repository/repository.dart';
import '../../providers/auth_provider.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  
  String _label = 'Home';
  bool _isLoading = false;
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _address1Ctrl.dispose();
    _address2Ctrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user!;
      final addr = AddressModel(
        id: '',
        userId: user.id,
        label: _label,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine1: _address1Ctrl.text.trim(),
        addressLine2: _address2Ctrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );
      await UserRepository().addAddress(user.id, addr);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Add Address'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Address Label', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: ['Home', 'Work', 'Other'].map((l) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(l),
                    selected: _label == l,
                    onSelected: (b) { if (b) setState(() => _label = l); },
                    checkmarkColor: AppColors.primary,
                    selectedColor: AppColors.primarySurface,
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _label == l ? AppColors.primary : AppColors.grey200)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pin Location on Map', style: TextStyle(fontWeight: FontWeight.w600)),
                          if (_selectedLocation != null)
                            const Text('Location selected', style: TextStyle(color: AppColors.success, fontSize: 12))
                          else
                            const Text('Help us find you better', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        LatLng? tempSelectedLoc = _selectedLocation;
                        final loc = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StatefulBuilder(
                              builder: (context, setStateSB) {
                                return Scaffold(
                                  appBar: const CustomAppBar(title: 'Pick Location'),
                                  body: LocationPickerWidget(
                                    initialLocation: _selectedLocation,
                                    onLocationSelected: (l) {
                                      tempSelectedLoc = l;
                                    },
                                  ),
                                  bottomNavigationBar: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: AppButton(
                                      label: 'Confirm Location',
                                      onTap: () {
                                        Navigator.pop(context, tempSelectedLoc); 
                                      },
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                        );
                        if (loc != null) {
                          setState(() => _selectedLocation = loc);
                          try {
                            final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
                            if (placemarks.isNotEmpty) {
                              final p = placemarks.first;
                              setState(() {
                                _address1Ctrl.text = p.street ?? _address1Ctrl.text;
                                _address2Ctrl.text = p.subLocality ?? _address2Ctrl.text;
                                _cityCtrl.text = p.locality ?? p.subAdministrativeArea ?? _cityCtrl.text;
                                _stateCtrl.text = p.administrativeArea ?? _stateCtrl.text;
                                _pincodeCtrl.text = p.postalCode ?? _pincodeCtrl.text;
                              });
                            }
                          } catch (_) {}
                        }
                      },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(label: 'Full Name', hint: 'Full Name', controller: _nameCtrl, validator: Validators.required),
              const SizedBox(height: 16),
              AppTextField(label: 'Phone Number', hint: '10-digit number', controller: _phoneCtrl, keyboardType: TextInputType.phone, validator: Validators.phone),
              const SizedBox(height: 16),
              AppTextField(label: 'Flat, House no., Building', hint: 'Address Line 1', controller: _address1Ctrl, validator: Validators.required),
              const SizedBox(height: 16),
              AppTextField(label: 'Area, Street, Sector', hint: 'Address Line 2 (Optional)', controller: _address2Ctrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'City', hint: 'City', controller: _cityCtrl, validator: Validators.required)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'State', hint: 'State', controller: _stateCtrl, validator: Validators.required)),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Pincode', hint: 'ZIP / Postal Code', controller: _pincodeCtrl, keyboardType: TextInputType.number, validator: Validators.required),
              const SizedBox(height: 32),
              AppButton(label: 'Save Address', isLoading: _isLoading, onTap: _save),
            ],
          ),
        ),
      ),
    );
  }
}
