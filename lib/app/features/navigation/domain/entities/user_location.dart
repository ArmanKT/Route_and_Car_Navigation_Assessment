import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class UserLocation extends Equatable {
  final LatLng position;
  final double? accuracy;
  final double? bearing;
  final double? speed;
  final DateTime timestamp;

  const UserLocation({
    required this.position,
    this.accuracy,
    this.bearing,
    this.speed,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [position, accuracy, bearing, speed, timestamp];
}
