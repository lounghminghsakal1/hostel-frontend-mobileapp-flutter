import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Ensures location permission (and the location service itself) is
/// available before proceeding with a location-dependent flow (e.g.
/// attendance geo-tagging).
///
/// Returns `true` only when permission is already/now granted and the
/// location service is on. If the user denies it, `false` is returned and a
/// follow-up call (e.g. tapping the same button again) will re-prompt. If
/// permanently denied, the user is guided to the app settings instead, since
/// the OS will no longer show the permission dialog on request.
Future<bool> ensureLocationPermission(BuildContext context) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn on location services to mark attendance.')),
      );
    }
    return false;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    if (context.mounted) await _showSettingsDialog(context);
    return false;
  }

  if (permission == LocationPermission.denied) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to mark attendance.')),
      );
    }
    return false;
  }

  return true;
}

Future<void> _showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Location permission required'),
      content: const Text(
        'Location access was denied. Please enable it from app settings to mark attendance.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Geolocator.openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
