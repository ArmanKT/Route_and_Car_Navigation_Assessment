import 'package:equatable/equatable.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/animated_car_state.dart';

abstract class CarAnimationState extends Equatable {
  const CarAnimationState();

  @override
  List<Object?> get props => [];
}

class CarAnimationInitial extends CarAnimationState {
  const CarAnimationInitial();
}

class CarAnimationActive extends CarAnimationState {
  final AnimatedCarState carState;

  const CarAnimationActive(this.carState);

  @override
  List<Object?> get props => [carState];
}
