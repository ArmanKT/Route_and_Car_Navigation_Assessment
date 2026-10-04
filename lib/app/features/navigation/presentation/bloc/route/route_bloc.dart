import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:route_and_car_navigation/app/core/exceptions/route_failure.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/usecases/get_route_usecase.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/route/route_event.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/route/route_state.dart';
import 'package:stream_transform/stream_transform.dart';

const Duration _debounceDuration = Duration(milliseconds: 600);

EventTransformer<E> _debounceRestartable<E>() {
  return (events, mapper) {
    return restartable<E>().call(events.debounce(_debounceDuration), mapper);
  };
}

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final GetRouteUseCase getRouteUseCase;

  RouteBloc({required this.getRouteUseCase})
      : super(const RouteInitial()) {
    on<DestinationSelected>(
      _onDestinationSelected,
      transformer: _debounceRestartable(),
    );
    on<RouteCleared>(_onRouteCleared);
  }

  Future<void> _onDestinationSelected(
    DestinationSelected event,
    Emitter<RouteState> emit,
  ) async {
    emit(RouteLoading(destination: event.destination));

    try {
      final route = await getRouteUseCase(
        start: event.start,
        destination: event.destination,
      );
      emit(RouteLoaded(route: route));
    } on RouteFailure catch (e) {
      emit(RouteError(message: e.message, destination: event.destination));
    } catch (e) {
      emit(RouteError(
        message: 'Unexpected error fetching route: $e',
        destination: event.destination,
      ));
    }
  }

  void _onRouteCleared(RouteCleared event, Emitter<RouteState> emit) {
    emit(const RouteInitial());
  }
}
