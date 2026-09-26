import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ensures camera permission is granted before proceeding with a
/// camera-dependent flow (e.g. attendance face capture).
///
/// Returns `true` only when permission is already/now granted. If the user
/// denies it, `false` is returned and a follow-up call (e.g. tapping the
/// same button again) will re-prompt. If permanently denied, the user is
/// guided to the app settings instead, since the OS will no longer show
/// the permission dialog on request.
Future<bool> ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;
  if (status.isGranted) return true;

  if (status.isPermanentlyDenied) {
    if (context.mounted) await _showSettingsDialog(context);
    return false;
  }

  final result = await Permission.camera.request();
  if (result.isGranted) return true;

  if (!context.mounted) return false;
  if (result.isPermanentlyDenied) {
    await _showSettingsDialog(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera permission is required to mark attendance.')),
    );
  }
  return false;
}

Future<void> _showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Camera permission required'),
      content: const Text(
        'Camera access was denied. Please enable it from app settings to mark attendance.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
