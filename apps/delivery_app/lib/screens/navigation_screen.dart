import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

class NavigationScreen extends StatelessWidget {
  final double destLat;
  final double destLng;
  final String title;

  const NavigationScreen({
    Key? key,
    required this.destLat,
    required this.destLng,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: MapNavigationWidget(
        startLocation: LatLng(destLat - 0.01, destLng - 0.01), // Simulated start
        endLocation: LatLng(destLat, destLng),
      ),
    );
  }
}
