import 'package:equatable/equatable.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/user_location.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationPermissionPromptRequired extends LocationState {
  const LocationPermissionPromptRequired();
}

class LocationAcquiringFix extends LocationState {
  const LocationAcquiringFix();
}

class LocationReady extends LocationState {
  final UserLocation location;
  final bool isLiveStreaming;

  const LocationReady({
    required this.location,
    this.isLiveStreaming = false,
  });

  LocationReady copyWith({
    UserLocation? location,
    bool? isLiveStreaming,
  }) {
    return LocationReady(
      location: location ?? this.location,
      isLiveStreaming: isLiveStreaming ?? this.isLiveStreaming,
    );
  }

  @override
  List<Object?> get props => [location, isLiveStreaming];
}

class LocationPermissionDenied extends LocationState {
  final String message;
  const LocationPermissionDenied([this.message = 'Location permission was denied.']);

  @override
  List<Object?> get props => [message];
}

class LocationPermissionPermanentlyDenied extends LocationState {
  final String message;
  const LocationPermissionPermanentlyDenied([
    this.message = 'Location permission permanently denied. Please enable in settings.',
  ]);

  @override
  List<Object?> get props => [message];
}

class LocationServicesDisabled extends LocationState {
  final String message;
  const LocationServicesDisabled([
    this.message = 'Device location services are turned off.',
  ]);

  @override
  List<Object?> get props => [message];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
