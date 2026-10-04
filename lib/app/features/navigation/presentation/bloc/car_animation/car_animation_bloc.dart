import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/core/utils/geo_math.dart';
import 'package:route_and_car_navigation/app/core/utils/shortest_bearing.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/animated_car_state.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/navigation_route.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/car_animation/car_animation_event.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/car_animation/car_animation_state.dart';

class CarAnimationBloc extends Bloc<CarAnimationEvent, CarAnimationState> {
  static const double defaultBaseSpeedMps = 25.0; // ~90 km/h for crisp visual pace
  static const int tickRateMs = 33; // ~30 frames/sec

  final double baseSpeedMps;
  Timer? _ticker;

  NavigationRoute? _route;
  NavigationRoute? get currentRoute => _route;
  List<LatLng> _sanitizedWaypoints = [];
  List<double> _cumulativeDistances = [];
  double _totalDistanceMeters = 0.0;
  double _traveledDistanceMeters = 0.0;
  double _currentBearing = 0.0;
  SpeedMultiplier _speedMultiplier = SpeedMultiplier.x1;
  AnimationPlayStatus _playStatus = AnimationPlayStatus.idle;
  bool _wasPlayingBeforeBackground = false;

  CarAnimationBloc({this.baseSpeedMps = defaultBaseSpeedMps})
      : super(const CarAnimationInitial()) {
    on<CarRouteInitialized>(_onRouteInitialized);
    on<CarAnimationStarted>(_onStarted);
    on<CarAnimationPaused>(_onPaused);
    on<CarAnimationResumed>(_onResumed);
    on<CarAnimationReset>(_onReset);
    on<CarRouteCleared>(_onRouteCleared);
    on<CarSpeedChanged>(_onSpeedChanged);
    on<CarAnimationTicked>(_onTicked);
    on<CarAppLifecycleChanged>(_onAppLifecycleChanged);
  }

  void _onRouteCleared(
    CarRouteCleared event,
    Emitter<CarAnimationState> emit,
  ) {
    _stopTicker();
    _route = null;
    _sanitizedWaypoints = [];
    _cumulativeDistances = [];
    _totalDistanceMeters = 0.0;
    _traveledDistanceMeters = 0.0;
    _playStatus = AnimationPlayStatus.idle;
    emit(const CarAnimationInitial());
  }

  void _onRouteInitialized(
    CarRouteInitialized event,
    Emitter<CarAnimationState> emit,
  ) {
    _stopTicker();
    _route = event.route;
    _buildSanitizedGeometry(event.route.waypoints);

    _traveledDistanceMeters = 0.0;
    _playStatus = AnimationPlayStatus.idle;

    if (_sanitizedWaypoints.isEmpty) {
      emit(const CarAnimationInitial());
      return;
    }

    if (_sanitizedWaypoints.length >= 2) {
      _currentBearing = GeoMath.bearingBetween(
        _sanitizedWaypoints[0],
        _sanitizedWaypoints[1],
      );
    } else {
      _currentBearing = 0.0;
    }

    final carState = AnimatedCarState(
      position: _sanitizedWaypoints.first,
      bearing: _currentBearing,
      progress: 0.0,
      remainingDistanceMeters: _totalDistanceMeters,
      remainingDurationSeconds: _calculateRemainingDuration(
        _totalDistanceMeters,
        _speedMultiplier,
      ),
      playStatus: AnimationPlayStatus.idle,
      speedMultiplier: _speedMultiplier,
    );

    emit(CarAnimationActive(carState));
  }

  void _onStarted(
    CarAnimationStarted event,
    Emitter<CarAnimationState> emit,
  ) {
    if (_sanitizedWaypoints.isEmpty || _totalDistanceMeters <= 0.0) return;

    if (_playStatus == AnimationPlayStatus.completed) {
      _traveledDistanceMeters = 0.0;
    }

    _playStatus = AnimationPlayStatus.playing;
    _startTicker();
    _emitActiveState(emit);
  }

  void _onPaused(
    CarAnimationPaused event,
    Emitter<CarAnimationState> emit,
  ) {
    if (_playStatus != AnimationPlayStatus.playing) return;
    _stopTicker();
    _playStatus = AnimationPlayStatus.paused;
    _emitActiveState(emit);
  }

  void _onResumed(
    CarAnimationResumed event,
    Emitter<CarAnimationState> emit,
  ) {
    if (_playStatus != AnimationPlayStatus.paused) return;
    _playStatus = AnimationPlayStatus.playing;
    _startTicker();
    _emitActiveState(emit);
  }

  void _onReset(
    CarAnimationReset event,
    Emitter<CarAnimationState> emit,
  ) {
    _stopTicker();
    _traveledDistanceMeters = 0.0;
    _playStatus = AnimationPlayStatus.idle;

    if (_sanitizedWaypoints.isNotEmpty) {
      if (_sanitizedWaypoints.length >= 2) {
        _currentBearing = GeoMath.bearingBetween(
          _sanitizedWaypoints[0],
          _sanitizedWaypoints[1],
        );
      }
      _emitActiveState(emit);
    } else {
      emit(const CarAnimationInitial());
    }
  }

  void _onSpeedChanged(
    CarSpeedChanged event,
    Emitter<CarAnimationState> emit,
  ) {
    _speedMultiplier = event.speed;
    if (state is CarAnimationActive) {
      _emitActiveState(emit);
    }
  }

  void _onTicked(
    CarAnimationTicked event,
    Emitter<CarAnimationState> emit,
  ) {
    if (_playStatus != AnimationPlayStatus.playing || _totalDistanceMeters <= 0.0) {
      return;
    }

    final double effectiveSpeedMps = baseSpeedMps * _speedMultiplier.value;
    final double stepMeters = effectiveSpeedMps * event.deltaSeconds;

    _traveledDistanceMeters += stepMeters;

    if (_traveledDistanceMeters >= _totalDistanceMeters) {
      _traveledDistanceMeters = _totalDistanceMeters;
      _playStatus = AnimationPlayStatus.completed;
      _stopTicker();
    }

    _emitActiveState(emit);
  }

  void _onAppLifecycleChanged(
    CarAppLifecycleChanged event,
    Emitter<CarAnimationState> emit,
  ) {
    switch (event.lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (_playStatus == AnimationPlayStatus.playing) {
          _wasPlayingBeforeBackground = true;
          add(const CarAnimationPaused());
        }
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforeBackground) {
          _wasPlayingBeforeBackground = false;
          add(const CarAnimationResumed());
        }
        break;
      case AppLifecycleState.detached:
        _stopTicker();
        break;
    }
  }

  void _emitActiveState(Emitter<CarAnimationState> emit) {
    if (_sanitizedWaypoints.isEmpty) return;

    final progress = _totalDistanceMeters > 0
        ? (_traveledDistanceMeters / _totalDistanceMeters).clamp(0.0, 1.0)
        : 1.0;

    final currentPosition = _calculatePositionAtDistance(_traveledDistanceMeters);
    final remainingDistance = (_totalDistanceMeters - _traveledDistanceMeters).clamp(0.0, _totalDistanceMeters);
    final remainingDuration = _calculateRemainingDuration(remainingDistance, _speedMultiplier);

    final carState = AnimatedCarState(
      position: currentPosition,
      bearing: _currentBearing,
      progress: progress,
      remainingDistanceMeters: remainingDistance,
      remainingDurationSeconds: remainingDuration,
      playStatus: _playStatus,
      speedMultiplier: _speedMultiplier,
    );

    emit(CarAnimationActive(carState));
  }

  LatLng _calculatePositionAtDistance(double targetDistance) {
    if (_sanitizedWaypoints.length == 1 || targetDistance <= 0.0) {
      return _sanitizedWaypoints.first;
    }

    if (targetDistance >= _totalDistanceMeters) {
      return _sanitizedWaypoints.last;
    }

    int low = 0;
    int high = _cumulativeDistances.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (_cumulativeDistances[mid] <= targetDistance) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final int segIndex = (low - 1).clamp(0, _sanitizedWaypoints.length - 2);
    final double segStartDist = _cumulativeDistances[segIndex];
    final double segEndDist = _cumulativeDistances[segIndex + 1];
    final double segLength = segEndDist - segStartDist;

    final p1 = _sanitizedWaypoints[segIndex];
    final p2 = _sanitizedWaypoints[segIndex + 1];

    if (segLength < 1e-4) {
      return p1;
    }

    final double segT = ((targetDistance - segStartDist) / segLength).clamp(0.0, 1.0);
    final targetPosition = GeoMath.interpolate(p1, p2, segT);

    final targetBearing = GeoMath.bearingBetween(p1, p2, fallbackBearing: _currentBearing);
    _currentBearing = ShortestBearing.interpolateAngle(_currentBearing, targetBearing, 0.4);

    return targetPosition;
  }

  double _calculateRemainingDuration(double remainingMeters, SpeedMultiplier speed) {
    final effectiveSpeed = baseSpeedMps * speed.value;
    if (effectiveSpeed <= 0.0) return 0.0;
    return remainingMeters / effectiveSpeed;
  }

  void _buildSanitizedGeometry(List<LatLng> rawPoints) {
    _sanitizedWaypoints = [];
    _cumulativeDistances = [];
    _totalDistanceMeters = 0.0;

    if (rawPoints.isEmpty) return;

    _sanitizedWaypoints.add(rawPoints.first);
    _cumulativeDistances.add(0.0);

    for (int i = 1; i < rawPoints.length; i++) {
      final prev = _sanitizedWaypoints.last;
      final current = rawPoints[i];
      final dist = GeoMath.distanceBetween(prev, current);

      if (dist >= 0.5) {
        _sanitizedWaypoints.add(current);
        _totalDistanceMeters += dist;
        _cumulativeDistances.add(_totalDistanceMeters);
      }
    }

    if (_sanitizedWaypoints.length == 1 && rawPoints.length > 1) {
      final last = rawPoints.last;
      final dist = GeoMath.distanceBetween(_sanitizedWaypoints.first, last);
      _sanitizedWaypoints.add(last);
      _totalDistanceMeters = dist;
      _cumulativeDistances.add(dist);
    }
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(milliseconds: tickRateMs), (_) {
      add(const CarAnimationTicked(tickRateMs / 1000.0));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
