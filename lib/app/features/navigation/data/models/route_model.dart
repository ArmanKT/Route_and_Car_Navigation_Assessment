import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/core/network/osrm_client.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/navigation_route.dart';

class RouteModel extends NavigationRoute {
  const RouteModel({
    required super.waypoints,
    required super.totalDistanceMeters,
    required super.totalDurationSeconds,
    required super.start,
    required super.destination,
  });

  factory RouteModel.fromOsrmResult({
    required OsrmRouteResult result,
    required LatLng start,
    required LatLng destination,
  }) {
    return RouteModel(
      waypoints: result.coordinates,
      totalDistanceMeters: result.distanceMeters,
      totalDurationSeconds: result.durationSeconds,
      start: start,
      destination: destination,
    );
  }
}
