import 'package:route_and_car_navigation/app/features/navigation/domain/entities/user_location.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/location_repository.dart';

class WatchLocationUpdatesUseCase {
  final LocationRepository _repository;

  WatchLocationUpdatesUseCase(this._repository);

  Stream<UserLocation> call() => _repository.watchLocationUpdates();
}
