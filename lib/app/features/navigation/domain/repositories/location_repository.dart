import 'package:route_and_car_navigation/app/core/service/location_service.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/user_location.dart';

abstract class LocationRepository {
  Future<LocationPermissionStatus> checkPermission();
  Future<LocationPermissionStatus> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<bool> openAppSettings();
  Future<UserLocation> getCurrentLocation();
  Stream<UserLocation> watchLocationUpdates();
  void dispose();
}
