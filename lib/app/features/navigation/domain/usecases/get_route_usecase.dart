import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/navigation_route.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/route_repository.dart';

class GetRouteUseCase {
  final RouteRepository _repository;

  GetRouteUseCase(this._repository);

  Future<NavigationRoute> call({
    required LatLng start,
    required LatLng destination,
  }) {
    return _repository.getRoute(start: start, destination: destination);
  }
}
