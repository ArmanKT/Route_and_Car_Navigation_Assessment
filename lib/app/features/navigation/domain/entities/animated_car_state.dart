import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum AnimationPlayStatus {
  idle,
  playing,
  paused,
  completed,
}

enum SpeedMultiplier {
  x1(1.0, '1x'),
  x2(2.0, '2x'),
  x5(5.0, '5x');

  final double value;
  final String label;
  const SpeedMultiplier(this.value, this.label);
}

class AnimatedCarState extends Equatable {
  final LatLng position;
  final double bearing;
  final double progress; // 0.0 to 1.0
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final AnimationPlayStatus playStatus;
  final SpeedMultiplier speedMultiplier;

  const AnimatedCarState({
    required this.position,
    required this.bearing,
    required this.progress,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.playStatus,
    required this.speedMultiplier,
  });

  AnimatedCarState copyWith({
    LatLng? position,
    double? bearing,
    double? progress,
    double? remainingDistanceMeters,
    double? remainingDurationSeconds,
    AnimationPlayStatus? playStatus,
    SpeedMultiplier? speedMultiplier,
  }) {
    return AnimatedCarState(
      position: position ?? this.position,
      bearing: bearing ?? this.bearing,
      progress: progress ?? this.progress,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      remainingDurationSeconds:
          remainingDurationSeconds ?? this.remainingDurationSeconds,
      playStatus: playStatus ?? this.playStatus,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
    );
  }

  @override
  List<Object?> get props => [
        position,
        bearing,
        progress,
        remainingDistanceMeters,
        remainingDurationSeconds,
        playStatus,
        speedMultiplier,
      ];
}
