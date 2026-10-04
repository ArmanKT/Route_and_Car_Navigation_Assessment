import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoMath {
  GeoMath._();

  static const double earthRadiusMeters = 6371000.0;

  /// Calculates geodesic distance between two points in meters using Haversine formula.
  static double distanceBetween(LatLng p1, LatLng p2) {
    final lat1Rad = _degreesToRadians(p1.latitude);
    final lon1Rad = _degreesToRadians(p1.longitude);
    final lat2Rad = _degreesToRadians(p2.latitude);
    final lon2Rad = _degreesToRadians(p2.longitude);

    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final clampedA = a.clamp(0.0, 1.0);
    final c = 2 * math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));

    return earthRadiusMeters * c;
  }

  /// Calculates initial bearing from p1 to p2 in degrees [0, 360).
  /// If points are identical or distance is virtually zero (< 0.1m), returns fallbackBearing.
  static double bearingBetween(
    LatLng p1,
    LatLng p2, {
    double fallbackBearing = 0.0,
  }) {
    final lat1Rad = _degreesToRadians(p1.latitude);
    final lon1Rad = _degreesToRadians(p1.longitude);
    final lat2Rad = _degreesToRadians(p2.latitude);
    final lon2Rad = _degreesToRadians(p2.longitude);

    final dLon = lon2Rad - lon1Rad;

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    if (x.abs() < 1e-12 && y.abs() < 1e-12) {
      return fallbackBearing;
    }

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    return (bearingDeg + 360.0) % 360.0;
  }

  /// Linearly interpolates between two LatLng points with a fraction t in [0.0, 1.0].
  static LatLng interpolate(LatLng from, LatLng to, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final lat = from.latitude + (to.latitude - from.latitude) * clampedT;
    final lng = from.longitude + (to.longitude - from.longitude) * clampedT;
    return LatLng(lat, lng);
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);
  static double _radiansToDegrees(double radians) => radians * (180.0 / math.pi);
}
