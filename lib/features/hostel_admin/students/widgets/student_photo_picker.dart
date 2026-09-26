import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/camera_permission.dart';
import '../../../student/attendance/screens/face_capture_screen.dart';

/// Opens the face-framing camera and returns the captured photo's local path,
/// or null if permission was denied or the user backed out.
Future<String?> captureStudentPhoto(BuildContext context) async {
  final granted = await ensureCameraPermission(context);
  if (!granted || !context.mounted) return null;

  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => const FaceCaptureScreen(
        lensDirection: CameraLensDirection.back,
        hint: "Frame the student's face inside the square",
      ),
    ),
  );
}

/// Lets the user pick a photo from the device and returns its local path, or
/// null if they cancelled. Throws a [PlatformException] if the library can't open.
Future<String?> pickStudentPhotoFromDevice() async {
  // A quality below 100 makes the picker re-encode the image as JPEG,
  // matching the `image/jpeg` content type the upload url is signed for.
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1080,
  );
  return file?.path;
}

class PhotoActionButton extends StatelessWidget {
  const PhotoActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: BorderSide(color: AppColors.navyAlpha(0.18)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
