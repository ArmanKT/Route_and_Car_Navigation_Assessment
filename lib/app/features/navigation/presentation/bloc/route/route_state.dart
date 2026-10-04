import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/navigation_route.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {
  const RouteInitial();
}

class RouteLoading extends RouteState {
  final LatLng destination;

  const RouteLoading({required this.destination});

  @override
  List<Object?> get props => [destination];
}

class RouteLoaded extends RouteState {
  final NavigationRoute route;

  const RouteLoaded({required this.route});

  @override
  List<Object?> get props => [route];
}

class RouteError extends RouteState {
  final String message;
  final LatLng? destination;

  const RouteError({
    required this.message,
    this.destination,
  });

  @override
  List<Object?> get props => [message, destination];
}
