/// Route path constants, kept separate from [app_router.dart] so screens
/// can reference a path without importing the router (and its screen imports).
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String setupPassword = '/setup-password';
  static String setupPasswordWithToken(String token, {bool forgotPassword = false}) => Uri(
        path: setupPassword,
        queryParameters: {'token': token, if (forgotPassword) 'forgotPassword': 'true'},
      ).toString();
  static const String forgotPassword = '/forgot-password';
  static const String studentHome = '/student/home';
  static const String adminHome = '/admin/home';
  static const String adminStudents = '/admin/students';
  static const String adminStudentCreate = '$adminStudents/new';
  static String adminStudentDetail(int id) => '$adminStudents/$id';
  static const String adminRooms = '/admin/rooms';
  static const String studentLeaveApplications = '/student/leave-applications';
  static const String adminLeaveApplications = '/admin/leave-applications';
  static String adminLeaveApplicationDetail(int id) => '$adminLeaveApplications/$id';
  static const String studentEvents = '/student/events';
  static String studentEventDetail(int id) => '$studentEvents/$id';
  static const String adminEvents = '/admin/events';
  static const String adminEventCreate = '$adminEvents/new';
  static String adminEventDetail(int id) => '$adminEvents/$id';
  static String adminEventEdit(int id) => '$adminEvents/$id/edit';
}
