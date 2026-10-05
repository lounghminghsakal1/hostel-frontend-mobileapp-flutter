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

  static const String attendanceRecords = '/attendance_records';

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

  /// The signed-in student's own applications.
  static const String myLeaveApplications = '$leaveApplications/student/my_leave_applications';

  static String myLeaveApplicationById(int id) => '$myLeaveApplications/$id';

  static const String upcomingEvents = '/upcoming_events';

  static String upcomingEventById(int id) => '$upcomingEvents/$id';

  /// Presigned S3 PUT url + object key for any upload
  /// (`?media_for=<MediaFor.queryValue>`).
  static const String mediaUploadUrl = '/media/upload_url';

  /// Presigned S3 GET url for any uploaded object (`?image_key=<key>`).
  static const String mediaDownloadUrl = '/media/download_url';
}
