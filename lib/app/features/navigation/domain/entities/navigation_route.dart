import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class NavigationRoute extends Equatable {
  final List<LatLng> waypoints;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final LatLng start;
  final LatLng destination;

  const NavigationRoute({
    required this.waypoints,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.start,
    required this.destination,
  });

  @override
  List<Object?> get props => [
        waypoints,
        totalDistanceMeters,
        totalDurationSeconds,
        start,
        destination,
      ];
}
