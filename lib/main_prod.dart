import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'app/core/di/app_bloc_observer.dart';
import 'app/core/di/injection_container.dart';
import 'environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Environment.init(
    const Environment(
      flavor: AppFlavor.prod,
      appName: 'NavTest',
      routingBaseUrl: 'https://router.project-osrm.org',
      showDevBanner: false,
    ),
  );

  Bloc.observer = AppBlocObserver();
  await initDependencyInjection();

  runApp(const NavTestApp());
}
