import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/features/navigation/data/datasources/route_remote_datasource.dart';
import 'package:route_and_car_navigation/app/features/navigation/data/models/route_model.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/navigation_route.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource _remoteDataSource;

  RouteRepositoryImpl(this._remoteDataSource);

  @override
  Future<NavigationRoute> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final result = await _remoteDataSource.getRoute(
      start: start,
      destination: destination,
    );

    return RouteModel.fromOsrmResult(
      result: result,
      start: start,
      destination: destination,
    );
  }
}
