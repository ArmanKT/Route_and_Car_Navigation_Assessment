import 'package:flutter/material.dart';
import 'package:route_and_car_navigation/environment.dart';

class DevBanner extends StatelessWidget {
  final Widget child;

  const DevBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!Environment.current.showDevBanner) {
      return child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: 'DEV',
        location: BannerLocation.topStart,
        color: const Color(0xFFE53935),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        child: child,
      ),
    );
  }
}
