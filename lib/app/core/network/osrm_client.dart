import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/core/exceptions/route_failure.dart';
import 'package:route_and_car_navigation/app/core/network/api_client.dart';

class OsrmRouteResult {
  final List<LatLng> coordinates;
  final double distanceMeters;
  final double durationSeconds;

  const OsrmRouteResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class OsrmClient {
  final ApiClient _apiClient;

  OsrmClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches driving route from [start] to [end] using ApiClient.
  /// Note: OSRM expects coordinates in {lng},{lat} order.
  Future<OsrmRouteResult> getRoute({
    required LatLng start,
    required LatLng end,
    CancelToken? cancelToken,
  }) async {
    final startCoord = '${start.longitude},${start.latitude}';
    final endCoord = '${end.longitude},${end.latitude}';
    final path = '/route/v1/driving/$startCoord;$endCoord?overview=full&geometries=polyline';

    final response = await _apiClient.get(path, cancelToken: cancelToken);
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw const NoRouteFoundException();
    }

    final code = data['code'] as String?;
    if (code != 'Ok') {
      throw const NoRouteFoundException();
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const NoRouteFoundException();
    }

    final route = routes.first as Map<String, dynamic>;
    final encodedPolyline = route['geometry'] as String?;
    final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
    final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;

    if (encodedPolyline == null || encodedPolyline.isEmpty) {
      throw const NoRouteFoundException();
    }

    final coordinates = decodePolyline(encodedPolyline);
    if (coordinates.isEmpty) {
      throw const NoRouteFoundException();
    }

    return OsrmRouteResult(
      coordinates: coordinates,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  /// Decodes standard Google/OSRM Polyline (precision 1e5) into `List<LatLng>`.
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
