import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for the backend base URL and endpoint paths.
/// [baseUrl] is read from the `.env` file (see [BASE_URL]) so it can differ
/// per environment without a code change.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static const String login = '/auth/login';

  /// Sets a student's first password from the emailed setup link token.
  static const String setupNewPassword = '/students/setup_new_password';

  /// Emails a password reset link to a registered address.
  static const String forgotPassword = '/students/forgot_password';

  static const String studentHomeScreen = '/students/home';

  /// Returns a presigned S3 PUT url + object key for an attendance capture.
  static const String attendanceImageUploadUrl = '/media/attendance_image/upload_url';

  static const String attendanceRecords = '/attendance_records';

  /// Returns a presigned S3 GET url for a captured attendance image
  /// (`?imageKey=<capturedImageKey>`).
  static const String attendanceImageDownloadUrl = '/media/attendance_image/download_url';

  static const String adminDashboard = '/hostel-admin/dashboard';

  static const String students = '/students';

  static String studentById(int id) => '/students/$id';

  static const String departments = '/students/departments';

  static const String rooms = '/rooms';

  static String roomById(int id) => '/rooms/$id';

  static const String leaveApplications = '/leave_applications';

  static String leaveApplicationById(int id) => '$leaveApplications/$id';

  static String reviewLeaveApplication(int id) => '$leaveApplications/$id/review';

  static String cancelLeaveApplication(int id) => '$leaveApplications/$id/cancel';

  /// Returns a presigned S3 PUT url + object key for a student profile photo.
  static const String studentImageUploadUrl = '/media/student_image/upload_url';

  /// Generic presigned S3 PUT url + object key (`?media_for=<purpose>`).
  static const String mediaUploadUrl = '/media/upload_url';

  /// `media_for` value for upcoming event banner images.
  static const String upcomingEventMediaFor = 'upcoming_event_image';

  static const String upcomingEvents = '/upcoming_events';

  static String upcomingEventById(int id) => '$upcomingEvents/$id';
}
