/// Route path constants, kept separate from [app_router.dart] so screens
/// can reference a path without importing the router (and its screen imports).
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String setupPassword = '/setup-password';
  static String setupPasswordWithToken(String token) =>
      Uri(path: setupPassword, queryParameters: {'token': token}).toString();
  static const String studentHome = '/student/home';
  static const String adminHome = '/admin/home';
  static const String adminStudents = '/admin/students';
  static const String adminStudentCreate = '$adminStudents/new';
  static String adminStudentDetail(int id) => '$adminStudents/$id';
}
