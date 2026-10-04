import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:route_and_car_navigation/app/core/exceptions/location_failure.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
  unknown,
}

class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? bearing;
  final double? speed;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.bearing,
    this.speed,
    required this.timestamp,
  });

  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      bearing: (map['bearing'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, accuracy, bearing, speed, timestamp];
}

abstract class LocationService {
  Future<LocationPermissionStatus> checkPermission();
  Future<LocationPermissionStatus> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<bool> openAppSettings();
  Future<LocationData> getCurrentLocation();
  Stream<LocationData> getLocationStream();
  void dispose();
}

class PlatformLocationService implements LocationService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.akt.navigation/location_method');
  static const EventChannel _eventChannel =
      EventChannel('com.akt.navigation/location_event');

  Stream<LocationData>? _locationStream;

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const PlatformNotSupportedException();
    }

    try {
      final status = await _methodChannel.invokeMethod<String>('checkPermission');
      return _parsePermissionStatus(status);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const PlatformNotSupportedException();
    }

    try {
      final status = await _methodChannel.invokeMethod<String>('requestPermission');
      return _parsePermissionStatus(status);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const PlatformNotSupportedException();
    }

    try {
      final isEnabled =
          await _methodChannel.invokeMethod<bool>('isLocationServiceEnabled');
      return isEnabled ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const PlatformNotSupportedException();
    }

    try {
      final opened = await _methodChannel.invokeMethod<bool>('openAppSettings');
      return opened ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const PlatformNotSupportedException();
    }

    try {
      final data =
          await _methodChannel.invokeMapMethod<dynamic, dynamic>('getCurrentLocation');
      if (data == null) {
        throw const UnknownLocationException('Native returned null location data');
      }
      return LocationData.fromMap(data);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Stream<LocationData> getLocationStream() {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return Stream.error(const PlatformNotSupportedException());
    }

    _locationStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          if (event is Map) {
            return LocationData.fromMap(event);
          }
          throw const UnknownLocationException('Unexpected event format from native');
        })
        .handleError((error) {
          if (error is PlatformException) {
            throw _mapPlatformException(error);
          }
          throw error;
        });

    return _locationStream!;
  }

  @override
  void dispose() {
    _locationStream = null;
  }

  static LocationPermissionStatus _parsePermissionStatus(String? status) {
    switch (status) {
      case 'granted':
        return LocationPermissionStatus.granted;
      case 'denied':
        return LocationPermissionStatus.denied;
      case 'permanentlyDenied':
        return LocationPermissionStatus.permanentlyDenied;
      case 'servicesDisabled':
        return LocationPermissionStatus.servicesDisabled;
      default:
        return LocationPermissionStatus.unknown;
    }
  }

  static LocationFailure _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
        return LocationPermissionDeniedException(e.message ?? 'Permission denied');
      case 'PERMISSION_PERMANENTLY_DENIED':
        return LocationPermissionPermanentlyDeniedException(
          e.message ?? 'Permission permanently denied',
        );
      case 'SERVICES_DISABLED':
        return LocationServicesDisabledException(
          e.message ?? 'Location services disabled',
        );
      case 'LOCATION_TIMEOUT':
        return LocationTimeoutException(e.message ?? 'Location acquisition timed out');
      case 'PLATFORM_NOT_SUPPORTED':
        return PlatformNotSupportedException(e.message ?? 'Platform not supported');
      default:
        return UnknownLocationException(e.message ?? e.toString());
    }
  }
}
