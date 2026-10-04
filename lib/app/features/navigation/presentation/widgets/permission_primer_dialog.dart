import 'package:flutter/material.dart';

class PermissionPrimerDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback? onDismiss;

  const PermissionPrimerDialog({
    super.key,
    required this.onAllow,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.location_on_rounded, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text('Location Access', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'To show your current position and compute driving routes, NavTest needs access to your device location. Would you like to grant permission now?',
        style: TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: onDismiss,
            child: const Text('Not Now'),
          ),
        FilledButton(
          onPressed: onAllow,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Allow Access'),
        ),
      ],
    );
  }
}

class LocationPermanentlyDeniedDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  const LocationPermanentlyDeniedDialog({
    super.key,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.settings_suggest_rounded, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Text('Permission Required', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Location permission has been permanently denied. Please open App Settings and grant location permission to use live positioning.',
        style: TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onOpenSettings,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
