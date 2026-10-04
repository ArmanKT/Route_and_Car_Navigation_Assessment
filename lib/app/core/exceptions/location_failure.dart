sealed class LocationFailure implements Exception {
  final String message;
  const LocationFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class LocationPermissionDeniedException extends LocationFailure {
  const LocationPermissionDeniedException([
    super.message = 'Location permission was denied by the user.',
  ]);
}

class LocationPermissionPermanentlyDeniedException extends LocationFailure {
  const LocationPermissionPermanentlyDeniedException([
    super.message = 'Location permission was permanently denied. Please enable it in App Settings.',
  ]);
}

class LocationServicesDisabledException extends LocationFailure {
  const LocationServicesDisabledException([
    super.message = 'Location services are disabled on this device.',
  ]);
}

class LocationTimeoutException extends LocationFailure {
  const LocationTimeoutException([
    super.message = 'Timed out while acquiring location fix.',
  ]);
}

class PlatformNotSupportedException extends LocationFailure {
  const PlatformNotSupportedException([
    super.message = 'Location is not supported on this platform.',
  ]);
}

class UnknownLocationException extends LocationFailure {
  const UnknownLocationException([
    super.message = 'An unknown location error occurred.',
  ]);
}
