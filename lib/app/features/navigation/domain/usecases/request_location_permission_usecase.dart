import 'package:route_and_car_navigation/app/core/service/location_service.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/location_repository.dart';

class RequestLocationPermissionUseCase {
  final LocationRepository _repository;

  RequestLocationPermissionUseCase(this._repository);

  Future<LocationPermissionStatus> call() => _repository.requestPermission();
}
