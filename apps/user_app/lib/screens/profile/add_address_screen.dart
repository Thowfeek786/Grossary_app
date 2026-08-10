import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:repository/repository.dart';
import '../../providers/auth_provider.dart';

class _AddressDetails {
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  _AddressDetails({this.street = '', this.area = '', this.city = '', this.state = '', this.pincode = ''});
}

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
  bool _isDetectingLocation = false;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        if (_nameCtrl.text.isEmpty && user.name.isNotEmpty) {
          _nameCtrl.text = user.name;
        }
        if (_phoneCtrl.text.isEmpty && user.phone.isNotEmpty) {
          _phoneCtrl.text = user.phone;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<_AddressDetails> _getExactAddressFromCoordinates(double lat, double lng) async {
    String street = '';
    String area = '';
    String city = '';
    String state = '';
    String pincode = '';

    // 1. Try Native Geocoder
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Street Line 1 (Door No, Street Name)
        final streetList = <String>[];
        if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) streetList.add(p.subThoroughfare!);
        if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty && p.thoroughfare != 'Unnamed Road') streetList.add(p.thoroughfare!);
        if (p.name != null && p.name!.isNotEmpty && p.name != p.thoroughfare && p.name != p.subLocality && p.name != p.locality && p.name != 'Unnamed Road') {
          streetList.add(p.name!);
        }
        street = streetList.join(', ');

        // Area Line 2 (Locality / Suburb / Neighborhood e.g. Surampatti, Perundurai Road, Kottur)
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          area = p.subLocality!;
        }

        // City / Town (e.g. Erode, Tiruchengode, Salem, Namakkal, Coimbatore)
        if (p.locality != null && p.locality!.isNotEmpty) {
          city = p.locality!;
        } else if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) {
          city = p.subAdministrativeArea!;
        }

        state = p.administrativeArea ?? '';
        pincode = p.postalCode ?? '';
      }
    } catch (_) {}

    // 2. Complementary & Failsafe Nominatim Web API reverse geocoding
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      ));
      request.headers.set('User-Agent', 'GroceryGoApp/1.0');
      final response = await request.close();
      if (response.statusCode == 200) {
        final bodyStr = await response.transform(utf8.decoder).join();
        final data = json.decode(bodyStr);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final house = addr['house_number'] ?? addr['building'] ?? '';
          final road = addr['road'] ?? addr['pedestrian'] ?? addr['street'] ?? '';

          // Area (Suburb / Locality / Ward)
          final nomArea = addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['residential'] ??
              addr['subdistrict'] ??
              addr['quarter'] ??
              '';

          // City / Town (Town e.g. Tiruchengode, City e.g. Erode, Salem, Municipality, District)
          final nomCity = addr['town'] ??
              addr['city'] ??
              addr['municipality'] ??
              addr['city_district'] ??
              addr['district'] ??
              addr['county'] ??
              addr['state_district'] ??
              addr['village'] ??
              '';

          final nomState = addr['state'] ?? '';
          final nomPostcode = addr['postcode'] ?? '';

          if (street.isEmpty) {
            street = [house, road].where((e) => e.toString().isNotEmpty).join(' ');
            if (street.isEmpty) {
              final rawDisplay = data['display_name'] as String?;
              if (rawDisplay != null && rawDisplay.isNotEmpty) {
                street = rawDisplay.split(',').take(2).join(',');
              }
            }
          }

          if (area.isEmpty && nomArea.toString().isNotEmpty) {
            area = nomArea.toString();
          }

          // Prioritize town/city over suburb/area for City field
          if (city.isEmpty || (nomCity.toString().isNotEmpty && city == area)) {
            city = nomCity.toString();
          }

          if (state.isEmpty) state = nomState.toString();
          if (pincode.isEmpty) pincode = nomPostcode.toString();
        }
      }
      client.close();
    } catch (_) {}

    // Ensure City and Area are separate and distinct
    if (city == area) {
      area = '';
    }

    return _AddressDetails(
      street: street,
      area: area,
      city: city,
      state: state,
      pincode: pincode,
    );
  }

  Future<void> _fetchAndApplyCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled on your device.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied.';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in Settings.';
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw 'Unable to acquire precise GPS coordinates. Please ensure GPS is active and try again.';
      }

      final loc = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = loc);

      final details = await _getExactAddressFromCoordinates(loc.latitude, loc.longitude);
      setState(() {
        if (details.street.isNotEmpty) _address1Ctrl.text = details.street;
        if (details.area.isNotEmpty) _address2Ctrl.text = details.area;
        if (details.city.isNotEmpty) _cityCtrl.text = details.city;
        if (details.state.isNotEmpty) _stateCtrl.text = details.state;
        if (details.pincode.isNotEmpty) _pincodeCtrl.text = details.pincode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exact location detected & address auto-filled!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Delivery Address', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Tag Selector
              const Text(
                'Save Address As',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['Home', 'Work', 'Other'].map((l) {
                  final isSelected = _label == l;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(l),
                      selected: isSelected,
                      onSelected: (b) {
                        if (b) setState(() => _label = l);
                      },
                      selectedColor: const Color(0xFF059669),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // GPS Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Color(0xFF059669), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current GPS Location',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF111827)),
                              ),
                              Text(
                                _selectedLocation != null ? 'GPS coordinates captured' : 'Autofill fields using your location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedLocation != null ? const Color(0xFF059669) : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _isDetectingLocation ? null : _fetchAndApplyCurrentLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isDetectingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Locate Me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.map_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pin on Map',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF111827)),
                              ),
                              Text(
                                'Search address & select pin manually',
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            LatLng? tempSelectedLoc = _selectedLocation;
                            final loc = await Navigator.push<LatLng>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatefulBuilder(
                                  builder: (context, setStateSB) {
                                    return Scaffold(
                                      appBar: AppBar(
                                        backgroundColor: Colors.white,
                                        elevation: 0,
                                        title: const Text('Select Location', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
                                      ),
                                      body: LocationPickerWidget(
                                        initialLocation: _selectedLocation,
                                        onLocationSelected: (l) {
                                          tempSelectedLoc = l;
                                        },
                                      ),
                                      bottomNavigationBar: Container(
                                        padding: const EdgeInsets.all(20),
                                        color: Colors.white,
                                        child: SizedBox(
                                          height: 52,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF059669),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context, tempSelectedLoc);
                                            },
                                            child: const Text('Confirm Picked Location', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                            if (loc != null) {
                              setState(() => _selectedLocation = loc);
                              final details = await _getExactAddressFromCoordinates(loc.latitude, loc.longitude);
                              setState(() {
                                if (details.street.isNotEmpty) _address1Ctrl.text = details.street;
                                if (details.area.isNotEmpty) _address2Ctrl.text = details.area;
                                if (details.city.isNotEmpty) _cityCtrl.text = details.city;
                                if (details.state.isNotEmpty) _stateCtrl.text = details.state;
                                if (details.pincode.isNotEmpty) _pincodeCtrl.text = details.pincode;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2563EB)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_rounded, size: 14, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text('Search', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Text Fields
              AppTextField(
                label: 'Full Name',
                hint: 'Enter receiver full name',
                controller: _nameCtrl,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                hint: '10-digit mobile number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Flat, House No., Building Name',
                hint: 'e.g. Flat 402, Green Apartments',
                controller: _address1Ctrl,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Area, Street, Sector, Landmark',
                hint: 'Address Line 2 (Optional)',
                controller: _address2Ctrl,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'City',
                      hint: 'City name',
                      controller: _cityCtrl,
                      validator: Validators.required,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppTextField(
                      label: 'State',
                      hint: 'State name',
                      controller: _stateCtrl,
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Pincode / Zip Code',
                hint: '6-digit Postal code',
                controller: _pincodeCtrl,
                keyboardType: TextInputType.number,
                validator: Validators.required,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 8 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}
