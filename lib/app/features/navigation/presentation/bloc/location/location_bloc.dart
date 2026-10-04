import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:route_and_car_navigation/app/core/exceptions/location_failure.dart';
import 'package:route_and_car_navigation/app/core/service/location_service.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/location_repository.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/location/location_event.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/location/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository repository;
  StreamSubscription? _locationSubscription;

  LocationBloc({required this.repository})
      : super(const LocationInitial()) {
    on<LocationCheckRequested>(_onCheckRequested);
    on<LocationPermissionRequested>(_onPermissionRequested);
    on<LocationFetchCurrentRequested>(_onFetchCurrentRequested);
    on<LocationUpdatesStarted>(_onUpdatesStarted);
    on<LocationUpdated>(_onLocationUpdated);
    on<LocationSettingsOpenRequested>(_onSettingsOpenRequested);
  }

  Future<void> _onCheckRequested(
    LocationCheckRequested event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final isServicesEnabled = await repository.isLocationServiceEnabled();
      if (!isServicesEnabled) {
        emit(const LocationServicesDisabled());
        return;
      }

      final status = await repository.checkPermission();
      switch (status) {
        case LocationPermissionStatus.granted:
          add(const LocationFetchCurrentRequested());
          break;
        case LocationPermissionStatus.denied:
          emit(const LocationPermissionPromptRequired());
          break;
        case LocationPermissionStatus.permanentlyDenied:
          emit(const LocationPermissionPermanentlyDenied());
          break;
        case LocationPermissionStatus.servicesDisabled:
          emit(const LocationServicesDisabled());
          break;
        case LocationPermissionStatus.unknown:
          emit(const LocationPermissionPromptRequired());
          break;
      }
    } on LocationFailure catch (e) {
      _mapFailureToState(e, emit);
    } catch (e) {
      emit(LocationError('Failed to check location status: $e'));
    }
  }

  Future<void> _onPermissionRequested(
    LocationPermissionRequested event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final status = await repository.requestPermission();
      switch (status) {
        case LocationPermissionStatus.granted:
          add(const LocationFetchCurrentRequested());
          break;
        case LocationPermissionStatus.denied:
          emit(const LocationPermissionDenied());
          break;
        case LocationPermissionStatus.permanentlyDenied:
          emit(const LocationPermissionPermanentlyDenied());
          break;
        case LocationPermissionStatus.servicesDisabled:
          emit(const LocationServicesDisabled());
          break;
        case LocationPermissionStatus.unknown:
          emit(const LocationPermissionDenied());
          break;
      }
    } on LocationFailure catch (e) {
      _mapFailureToState(e, emit);
    } catch (e) {
      emit(LocationError('Failed to request permission: $e'));
    }
  }

  Future<void> _onFetchCurrentRequested(
    LocationFetchCurrentRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationAcquiringFix());
    try {
      final location = await repository.getCurrentLocation();
      emit(LocationReady(location: location));
    } on LocationFailure catch (e) {
      _mapFailureToState(e, emit);
    } catch (e) {
      emit(LocationError('Failed to acquire location: $e'));
    }
  }

  Future<void> _onUpdatesStarted(
    LocationUpdatesStarted event,
    Emitter<LocationState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = repository.watchLocationUpdates().listen(
      (location) {
        add(LocationUpdated(location));
      },
      onError: (error) {
        if (error is LocationFailure) {
          add(const LocationFetchCurrentRequested());
        }
      },
    );
  }

  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) {
    if (state is LocationReady) {
      emit((state as LocationReady).copyWith(
        location: event.location,
        isLiveStreaming: true,
      ));
    } else {
      emit(LocationReady(
        location: event.location,
        isLiveStreaming: true,
      ));
    }
  }

  Future<void> _onSettingsOpenRequested(
    LocationSettingsOpenRequested event,
    Emitter<LocationState> emit,
  ) async {
    await repository.openAppSettings();
  }

  void _mapFailureToState(LocationFailure failure, Emitter<LocationState> emit) {
    if (failure is LocationPermissionDeniedException) {
      emit(const LocationPermissionDenied());
    } else if (failure is LocationPermissionPermanentlyDeniedException) {
      emit(const LocationPermissionPermanentlyDenied());
    } else if (failure is LocationServicesDisabledException) {
      emit(const LocationServicesDisabled());
    } else if (failure is LocationTimeoutException) {
      emit(const LocationError('Acquiring location timed out. Please try again.'));
    } else if (failure is PlatformNotSupportedException) {
      emit(const LocationError('Location is not supported on this platform.'));
    } else {
      emit(LocationError(failure.message));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    return super.close();
  }
}
