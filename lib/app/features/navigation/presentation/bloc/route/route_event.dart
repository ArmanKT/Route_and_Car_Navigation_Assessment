import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class DestinationSelected extends RouteEvent {
  final LatLng start;
  final LatLng destination;

  const DestinationSelected({
    required this.start,
    required this.destination,
  });

  @override
  List<Object?> get props => [start, destination];
}

class RouteCleared extends RouteEvent {
  const RouteCleared();
}
