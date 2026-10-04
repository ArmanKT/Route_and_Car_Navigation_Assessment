import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapRecenterButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const MapRecenterButton({
    super.key,
    required this.isVisible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      scale: isVisible ? 1.0 : 0.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: FloatingActionButton.extended(
            heroTag: 'recenter_fab',
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.my_location_rounded, size: 20),
            label: const Text(
              'Recenter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
