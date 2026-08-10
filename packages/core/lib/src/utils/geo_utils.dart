import 'dart:math';

class GeoUtils {
  GeoUtils._();

  /// Calculates the Haversine distance in kilometers between two GPS coordinates
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates distance in meters
  static double calculateDistanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return calculateDistanceKm(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
        ) *
        1000.0;
  }

  /// Formats distance into a human readable string (e.g. "1.2 km" or "450 m")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  static double _toRadians(double degree) => degree * (pi / 180.0);
}
