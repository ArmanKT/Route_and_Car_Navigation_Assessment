import 'package:latlong2/latlong.dart';
import '../entities/navigation_route.dart';

abstract class RouteRepository {
  Future<NavigationRoute> getRoute({
    required LatLng start,
    required LatLng destination,
  });
}
