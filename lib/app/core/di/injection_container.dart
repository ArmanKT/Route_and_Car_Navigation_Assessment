import 'package:get_it/get_it.dart';
import 'package:route_and_car_navigation/app/core/network/api_client.dart';
import 'package:route_and_car_navigation/app/core/network/osrm_client.dart';
import 'package:route_and_car_navigation/app/core/service/location_service.dart';
import 'package:route_and_car_navigation/app/features/navigation/data/datasources/route_remote_datasource.dart';
import 'package:route_and_car_navigation/app/features/navigation/data/repositories/location_repository_impl.dart';
import 'package:route_and_car_navigation/app/features/navigation/data/repositories/route_repository_impl.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/location_repository.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/repositories/route_repository.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/usecases/get_current_location_usecase.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/usecases/get_route_usecase.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/usecases/request_location_permission_usecase.dart';
import 'package:route_and_car_navigation/app/features/navigation/domain/usecases/watch_location_updates_usecase.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/car_animation/car_animation_bloc.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/location/location_bloc.dart';
import 'package:route_and_car_navigation/app/features/navigation/presentation/bloc/route/route_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  // Core Network & Services
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<LocationService>(() => PlatformLocationService());
  sl.registerLazySingleton<OsrmClient>(() => OsrmClient(apiClient: sl()));

  // Data Sources
  sl.registerLazySingleton<RouteRemoteDataSource>(
    () => RouteRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCurrentLocationUseCase(sl()));
  sl.registerLazySingleton(() => RequestLocationPermissionUseCase(sl()));
  sl.registerLazySingleton(() => WatchLocationUpdatesUseCase(sl()));
  sl.registerLazySingleton(() => GetRouteUseCase(sl()));

  // Blocs
  sl.registerFactory(() => LocationBloc(repository: sl()));
  sl.registerFactory(() => RouteBloc(getRouteUseCase: sl()));
  sl.registerFactory(() => CarAnimationBloc());
}
