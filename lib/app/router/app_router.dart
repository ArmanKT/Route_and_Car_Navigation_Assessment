import 'package:flutter/material.dart';
import '../features/navigation/presentation/screens/navigation_screen.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
      default:
        return MaterialPageRoute(
          builder: (_) => const NavigationScreen(),
          settings: settings,
        );
    }
  }
}
