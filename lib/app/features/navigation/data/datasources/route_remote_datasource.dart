import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/core/network/osrm_client.dart';

abstract class RouteRemoteDataSource {
  Future<OsrmRouteResult> getRoute({
    required LatLng start,
    required LatLng destination,
  });
}

class RouteRemoteDataSourceImpl implements RouteRemoteDataSource {
  final OsrmClient _client;

  RouteRemoteDataSourceImpl(this._client);

  @override
  Future<OsrmRouteResult> getRoute({
    required LatLng start,
    required LatLng destination,
  }) {
    return _client.getRoute(start: start, end: destination);
  }
}
