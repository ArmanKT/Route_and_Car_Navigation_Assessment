import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../environment.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/bloc/car_animation/car_animation_bloc.dart';
import 'features/navigation/presentation/bloc/location/location_bloc.dart';
import 'features/navigation/presentation/bloc/route/route_bloc.dart';
import 'router/app_router.dart';

class NavTestApp extends StatelessWidget {
  const NavTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocationBloc>(
          create: (_) => sl<LocationBloc>(),
        ),
        BlocProvider<RouteBloc>(
          create: (_) => sl<RouteBloc>(),
        ),
        BlocProvider<CarAnimationBloc>(
          create: (_) => sl<CarAnimationBloc>(),
        ),
      ],
      child: MaterialApp(
        title: Environment.current.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRouter.initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
