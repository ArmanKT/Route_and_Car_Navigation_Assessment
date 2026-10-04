import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/animated_car_state.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/navigation_route.dart';

abstract class CarAnimationEvent extends Equatable {
  const CarAnimationEvent();

  @override
  List<Object?> get props => [];
}

class CarRouteInitialized extends CarAnimationEvent {
  final NavigationRoute route;

  const CarRouteInitialized(this.route);

  @override
  List<Object?> get props => [route];
}

class CarAnimationStarted extends CarAnimationEvent {
  const CarAnimationStarted();
}

class CarAnimationPaused extends CarAnimationEvent {
  const CarAnimationPaused();
}

class CarAnimationResumed extends CarAnimationEvent {
  const CarAnimationResumed();
}

class CarAnimationReset extends CarAnimationEvent {
  const CarAnimationReset();
}

class CarRouteCleared extends CarAnimationEvent {
  const CarRouteCleared();
}

class CarSpeedChanged extends CarAnimationEvent {
  final SpeedMultiplier speed;

  const CarSpeedChanged(this.speed);

  @override
  List<Object?> get props => [speed];
}

class CarAnimationTicked extends CarAnimationEvent {
  final double deltaSeconds;

  const CarAnimationTicked(this.deltaSeconds);

  @override
  List<Object?> get props => [deltaSeconds];
}

class CarAppLifecycleChanged extends CarAnimationEvent {
  final AppLifecycleState lifecycleState;

  const CarAppLifecycleChanged(this.lifecycleState);

  @override
  List<Object?> get props => [lifecycleState];
}
