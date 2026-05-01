import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapNavigationWidget extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final LatLng? currentLocation;

  const MapNavigationWidget({
    Key? key,
    required this.startLocation,
    required this.endLocation,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<MapNavigationWidget> createState() => _MapNavigationWidgetState();
}

class _MapNavigationWidgetState extends State<MapNavigationWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  @override
  void didUpdateWidget(covariant MapNavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _setupMarkers();
      _updateCamera();
    }
  }

  void _setupMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: widget.startLocation,
        infoWindow: const InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: widget.endLocation,
        infoWindow: const InfoWindow(title: 'Delivery Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (widget.currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: widget.currentLocation!,
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _updateCamera() async {
    if (widget.currentLocation == null) return;
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: widget.currentLocation!, zoom: 16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.currentLocation ?? widget.startLocation,
        zoom: 14,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        
        // Fit bounds for start and end
        LatLngBounds bounds;
        if (widget.startLocation.latitude > widget.endLocation.latitude) {
          bounds = LatLngBounds(southwest: widget.endLocation, northeast: widget.startLocation);
        } else {
          bounds = LatLngBounds(southwest: widget.startLocation, northeast: widget.endLocation);
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        });
      },
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
