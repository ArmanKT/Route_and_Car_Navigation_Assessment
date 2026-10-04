import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/core/service/location_service.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/user_location.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationService _locationService;

  LocationRepositoryImpl(this._locationService);

  @override
  Future<LocationPermissionStatus> checkPermission() {
    return _locationService.checkPermission();
  }

  @override
  Future<LocationPermissionStatus> requestPermission() {
    return _locationService.requestPermission();
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return _locationService.isLocationServiceEnabled();
  }

  @override
  Future<bool> openAppSettings() {
    return _locationService.openAppSettings();
  }

  @override
  Future<UserLocation> getCurrentLocation() async {
    final data = await _locationService.getCurrentLocation();
    return _mapToUserLocation(data);
  }

  @override
  Stream<UserLocation> watchLocationUpdates() {
    return _locationService
        .getLocationStream()
        .map(_mapToUserLocation);
  }

  @override
  void dispose() {
    _locationService.dispose();
  }

  UserLocation _mapToUserLocation(LocationData data) {
    return UserLocation(
      position: LatLng(data.latitude, data.longitude),
      accuracy: data.accuracy,
      bearing: data.bearing,
      speed: data.speed,
      timestamp: data.timestamp,
    );
  }
}
