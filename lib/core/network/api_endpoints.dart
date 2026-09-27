import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for the backend base URL and endpoint paths.
/// [baseUrl] is read from the `.env` file (see [BASE_URL]) so it can differ
/// per environment without a code change.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static const String login = '/auth/login';

  /// Sets a student's first password from the emailed setup link token.
  static const String setupNewPassword = '/students/setup-new-password';

  static const String studentHomeScreen = '/students/home';

  /// Returns a presigned S3 PUT url + object key for an attendance capture.
  static const String attendanceImageUploadUrl = '/uploads/attendance_image/upload_url';

  static const String attendanceRecords = '/attendance_records';

  /// Returns a presigned S3 GET url for a captured attendance image
  /// (`?imageKey=<capturedImageKey>`).
  static const String attendanceImageDownloadUrl = '/uploads/attendance_image/download_url';

  static const String adminDashboard = '/hostel-admin/dashboard';

  static const String students = '/students';

  static String studentById(int id) => '/students/$id';

  static const String departments = '/students/departments';

  static const String rooms = '/rooms';

  /// Returns a presigned S3 PUT url + object key for a student profile photo.
  static const String studentImageUploadUrl = '/uploads/student_image/upload_url';
}
