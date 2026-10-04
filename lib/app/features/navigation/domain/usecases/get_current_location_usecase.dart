import 'package:route_and_car_navigation/app/features/navigation/domain/entities/user_location.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/location_repository.dart';

class GetCurrentLocationUseCase {
  final LocationRepository _repository;

  GetCurrentLocationUseCase(this._repository);

  Future<UserLocation> call() => _repository.getCurrentLocation();
}
