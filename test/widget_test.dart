import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/core/utils/geo_math.dart';
import 'package:route_and_car_navigation/app/core/utils/shortest_bearing.dart';

void main() {
  group('GeoMath and ShortestBearing Unit Tests', () {
    test('Calculates geodesic distance accurately', () {
      const p1 = LatLng(0.0, 0.0);
      const p2 = LatLng(0.0, 1.0);
      final distance = GeoMath.distanceBetween(p1, p2);
      expect(distance, greaterThan(111000));
      expect(distance, lessThan(112000));
    });

    test('Shortest angle delta avoids long-way-round rotation', () {
      // 359° to 1° should be +2°, not -358°
      final delta = ShortestBearing.shortestAngleDelta(359, 1);
      expect(delta, closeTo(2.0, 0.001));

      // 1° to 359° should be -2°, not +358°
      final deltaReverse = ShortestBearing.shortestAngleDelta(1, 359);
      expect(deltaReverse, closeTo(-2.0, 0.001));

      // 10° to 100° should be +90°
      final deltaNormal = ShortestBearing.shortestAngleDelta(10, 100);
      expect(deltaNormal, closeTo(90.0, 0.001));
    });

    test('Interpolates angle along shortest path correctly', () {
      final angle = ShortestBearing.interpolateAngle(359, 1, 0.5);
      expect(angle, closeTo(0.0, 0.001));
    });

    test('Handles duplicate points safely without NaN or crash', () {
      const p1 = LatLng(23.8103, 90.4125);
      const p2 = LatLng(23.8103, 90.4125);
      final dist = GeoMath.distanceBetween(p1, p2);
      expect(dist, equals(0.0));

      final bearing = GeoMath.bearingBetween(p1, p2, fallbackBearing: 45.0);
      expect(bearing, equals(45.0));
      expect(bearing.isNaN, isFalse);
    });
  });
}
