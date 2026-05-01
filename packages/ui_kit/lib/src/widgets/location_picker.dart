import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const LocationPickerWidget({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLocation;
  Marker? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    if (_currentLocation != null) {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: _currentLocation!,
      );
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    final position = await Geolocator.getCurrentPosition();
    final newLocation = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _currentLocation = newLocation;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: newLocation,
      );
    });
    
    widget.onLocationSelected(newLocation);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: newLocation, zoom: 15),
    ));
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: location,
      );
    });
    widget.onLocationSelected(location);
  }

  @override
  Widget build(BuildContext context) {
    return _currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: _onMapTapped,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
  }
}
