import 'package:equatable/equatable.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/user_location.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationCheckRequested extends LocationEvent {
  const LocationCheckRequested();
}

class LocationPermissionRequested extends LocationEvent {
  const LocationPermissionRequested();
}

class LocationFetchCurrentRequested extends LocationEvent {
  const LocationFetchCurrentRequested();
}

class LocationUpdatesStarted extends LocationEvent {
  const LocationUpdatesStarted();
}

class LocationUpdated extends LocationEvent {
  final UserLocation location;
  const LocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationSettingsOpenRequested extends LocationEvent {
  const LocationSettingsOpenRequested();
}
