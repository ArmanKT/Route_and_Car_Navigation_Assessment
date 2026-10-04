import 'dart:math' as math;
import 'package:flutter/material.dart';

class CarMarkerWidget extends StatelessWidget {
  final double bearing; // in degrees

  const CarMarkerWidget({
    super.key,
    required this.bearing,
  });

  @override
  Widget build(BuildContext context) {
    // Rotate car marker to face travel direction
    final radians = (bearing * (math.pi / 180.0));

    return Transform.rotate(
      angle: radians,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
