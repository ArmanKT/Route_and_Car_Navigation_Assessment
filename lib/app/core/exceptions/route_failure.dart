sealed class RouteFailure implements Exception {
  final String message;
  const RouteFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NoRouteFoundException extends RouteFailure {
  const NoRouteFoundException([
    super.message = 'No drivable route found between the selected coordinates.',
  ]);
}

class NetworkFailureException extends RouteFailure {
  const NetworkFailureException([
    super.message = 'Network connection failed. Please check your internet connection.',
  ]);
}

class RouteTimeoutException extends RouteFailure {
  const RouteTimeoutException([
    super.message = 'Routing service request timed out.',
  ]);
}

class ServerRateLimitException extends RouteFailure {
  const ServerRateLimitException([
    super.message = 'Public routing server rate limit reached. Please wait a moment before trying again.',
  ]);
}

class InvalidRouteCoordinatesException extends RouteFailure {
  const InvalidRouteCoordinatesException([
    super.message = 'Route coordinates provided are invalid or identical.',
  ]);
}
