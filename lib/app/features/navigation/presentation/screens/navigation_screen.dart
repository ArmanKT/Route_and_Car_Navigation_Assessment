import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_and_car_navigation/app/components/dev_banner.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/entities/animated_car_state.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/car_animation/car_animation_bloc.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/car_animation/car_animation_event.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/car_animation/car_animation_state.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/location/location_bloc.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/location/location_event.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/location/location_state.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/route/route_bloc.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/route/route_event.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/route/route_state.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/widgets/car_marker.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/widgets/map_recenter_button.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/widgets/navigation_controls_sheet.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/widgets/permission_primer_dialog.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/widgets/route_info_card.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with WidgetsBindingObserver {
  late final MapController _mapController;
  bool _isFollowingCar = true;
  bool _hasInitialFixCentered = false;
  LatLng? _manualStartFallback;

  static const LatLng _defaultCenter = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);

    context.read<LocationBloc>().add(const LocationCheckRequested());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<CarAnimationBloc>().add(CarAppLifecycleChanged(state));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && _isFollowingCar) {
      setState(() {
        _isFollowingCar = false;
      });
    }
  }

  void _recenterOnCarOrLocation() {
    final animState = context.read<CarAnimationBloc>().state;
    if (animState is CarAnimationActive) {
      _mapController.move(animState.carState.position, _mapController.camera.zoom);
      setState(() {
        _isFollowingCar = true;
      });
      return;
    }

    final locState = context.read<LocationBloc>().state;
    if (locState is LocationReady) {
      _mapController.move(locState.location.position, 16.0);
      setState(() {
        _isFollowingCar = true;
      });
    }
  }

  void _handleDestinationLongPress(LatLng tappedPoint) {
    final locState = context.read<LocationBloc>().state;
    LatLng? startPoint;

    if (locState is LocationReady) {
      startPoint = locState.location.position;
    } else if (_manualStartFallback != null) {
      startPoint = _manualStartFallback;
    }

    if (startPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Acquiring your location fix. You can also tap the map to set a start point.',
          ),
          backgroundColor: const Color(0xFF1E293B),
          action: SnackBarAction(
            label: 'Use Default',
            textColor: const Color(0xFF60A5FA),
            onPressed: () {
              setState(() {
                _manualStartFallback = _defaultCenter;
              });
              context.read<RouteBloc>().add(
                    DestinationSelected(
                      start: _defaultCenter,
                      destination: tappedPoint,
                    ),
                  );
            },
          ),
        ),
      );
      return;
    }

    context.read<RouteBloc>().add(
          DestinationSelected(
            start: startPoint,
            destination: tappedPoint,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return DevBanner(
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<LocationBloc, LocationState>(
              listener: (context, state) {
                if (state is LocationPermissionPromptRequired) {
                  _showPermissionPrimer();
                } else if (state is LocationPermissionPermanentlyDenied) {
                  _showPermanentlyDeniedDialog();
                } else if (state is LocationServicesDisabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable location services on your device.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                } else if (state is LocationReady) {
                  if (!_hasInitialFixCentered) {
                    _hasInitialFixCentered = true;
                    _mapController.move(state.location.position, 16.0);
                  }
                } else if (state is LocationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              },
            ),
            BlocListener<RouteBloc, RouteState>(
              listener: (context, state) {
                if (state is RouteLoaded) {
                  final waypoints = state.route.waypoints;
                  if (waypoints.isNotEmpty) {
                    final bounds = LatLngBounds.fromPoints(waypoints);
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.only(
                          left: 48,
                          right: 48,
                          top: 80,
                          bottom: 220,
                        ),
                      ),
                    );
                  }

                  context
                      .read<CarAnimationBloc>()
                      .add(CarRouteInitialized(state.route));
                  setState(() {
                    _isFollowingCar = true;
                  });
                } else if (state is RouteInitial) {
                  context
                      .read<CarAnimationBloc>()
                      .add(const CarRouteCleared());
                } else if (state is RouteError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              },
            ),
            BlocListener<CarAnimationBloc, CarAnimationState>(
              listener: (context, state) {
                if (state is CarAnimationActive && _isFollowingCar) {
                  final car = state.carState;
                  if (car.playStatus == AnimationPlayStatus.playing) {
                    _mapController.move(car.position, _mapController.camera.zoom);
                  }
                }
              },
            ),
          ],
          child: Stack(
            children: [
              BlocBuilder<LocationBloc, LocationState>(
                builder: (context, locState) {
                  final initialPos = locState is LocationReady
                      ? locState.location.position
                      : _defaultCenter;

                  return BlocBuilder<RouteBloc, RouteState>(
                    builder: (context, routeState) {
                      return BlocBuilder<CarAnimationBloc, CarAnimationState>(
                        builder: (context, animState) {
                          return FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: initialPos,
                              initialZoom: 15.0,
                              onLongPress: (tapPosition, point) =>
                                  _handleDestinationLongPress(point),
                              onPositionChanged: _onMapPositionChanged,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.akt.navigation.route_and_car_navigation',
                              ),
                              const RichAttributionWidget(
                                attributions: [
                                  TextSourceAttribution(
                                    '© OpenStreetMap contributors',
                                  ),
                                ],
                              ),
                              if (routeState is RouteLoaded)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routeState.route.waypoints,
                                      strokeWidth: 6.0,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    Polyline(
                                      points: routeState.route.waypoints,
                                      strokeWidth: 2.0,
                                      color: Colors.white.withAlpha(180),
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: _buildMarkers(
                                  locState: locState,
                                  routeState: routeState,
                                  animState: animState,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: BlocBuilder<RouteBloc, RouteState>(
                    builder: (context, routeState) {
                      if (routeState is RouteLoading) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withAlpha(220),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Calculating optimal driving route...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (routeState is RouteLoaded) {
                        return RouteInfoCard(
                          route: routeState.route,
                          onClear: () {
                            context.read<RouteBloc>().add(const RouteCleared());
                            context
                                .read<CarAnimationBloc>()
                                .add(const CarRouteCleared());
                            setState(() {
                              _isFollowingCar = false;
                            });
                          },
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withAlpha(210),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.touch_app_rounded,
                              color: Color(0xFF60A5FA),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Long-press on map to select destination',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<CarAnimationBloc, CarAnimationState>(
                  builder: (context, animState) {
                    final bool hasControls = animState is CarAnimationActive;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16, bottom: 12),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: !_isFollowingCar
                                ? MapRecenterButton(
                                    key: const ValueKey('recenter_btn'),
                                    isVisible: true,
                                    onPressed: _recenterOnCarOrLocation,
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('recenter_empty'),
                                  ),
                          ),
                        ),
                        if (hasControls)
                          NavigationControlsSheet(
                            carState: animState.carState,
                            onStart: () {
                              setState(() {
                                _isFollowingCar = true;
                              });
                              _mapController.move(
                                animState.carState.position,
                                _mapController.camera.zoom,
                              );
                              context
                                  .read<CarAnimationBloc>()
                                  .add(const CarAnimationStarted());
                            },
                            onPause: () => context
                                .read<CarAnimationBloc>()
                                .add(const CarAnimationPaused()),
                            onResume: () {
                              setState(() {
                                _isFollowingCar = true;
                              });
                              _mapController.move(
                                animState.carState.position,
                                _mapController.camera.zoom,
                              );
                              context
                                  .read<CarAnimationBloc>()
                                  .add(const CarAnimationResumed());
                            },
                            onReset: () {
                              setState(() {
                                _isFollowingCar = true;
                              });
                              context
                                  .read<CarAnimationBloc>()
                                  .add(const CarAnimationReset());
                              final routeState =
                                  context.read<RouteBloc>().state;
                              if (routeState is RouteLoaded &&
                                  routeState.route.waypoints.isNotEmpty) {
                                _mapController.move(
                                  routeState.route.waypoints.first,
                                  _mapController.camera.zoom,
                                );
                              }
                            },
                            onSpeedChanged: (speed) => context
                                .read<CarAnimationBloc>()
                                .add(CarSpeedChanged(speed)),
                          )
                        else
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 16,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers({
    required LocationState locState,
    required RouteState routeState,
    required CarAnimationState animState,
  }) {
    final List<Marker> markers = [];

    if (locState is LocationReady) {
      markers.add(
        Marker(
          point: locState.location.position,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withAlpha(80),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (routeState is RouteLoaded) {
      markers.add(
        Marker(
          point: routeState.route.destination,
          width: 36,
          height: 36,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_pin,
            color: Color(0xFFEF4444),
            size: 36,
          ),
        ),
      );
    } else if (routeState is RouteLoading) {
      markers.add(
        Marker(
          point: routeState.destination,
          width: 36,
          height: 36,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_pin,
            color: Color(0xFFF59E0B),
            size: 36,
          ),
        ),
      );
    }

    if (animState is CarAnimationActive) {
      final car = animState.carState;
      markers.add(
        Marker(
          point: car.position,
          width: 48,
          height: 48,
          child: CarMarkerWidget(bearing: car.bearing),
        ),
      );
    }

    return markers;
  }

  void _showPermissionPrimer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PermissionPrimerDialog(
        onAllow: () {
          Navigator.of(dialogCtx).pop();
          context.read<LocationBloc>().add(const LocationPermissionRequested());
        },
        onDismiss: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => LocationPermanentlyDeniedDialog(
        onOpenSettings: () {
          Navigator.of(dialogCtx).pop();
          context
              .read<LocationBloc>()
              .add(const LocationSettingsOpenRequested());
        },
        onDismiss: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }
}
