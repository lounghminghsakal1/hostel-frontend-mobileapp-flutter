import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/common/auth/screens/login_screen.dart';
import '../../features/common/auth/screens/set_new_password_page.dart';
import '../../features/hostel_admin/home/screens/admin_home_screen.dart';
import '../../features/hostel_admin/students/screens/create_student_screen.dart';
import '../../features/hostel_admin/students/screens/student_detail_screen.dart';
import '../../features/hostel_admin/students/screens/students_list_screen.dart';
import '../../features/student/home/screens/student_home_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupPassword,
        builder: (context, state) => SetNewPasswordPage(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudents,
        builder: (context, state) => const StudentsListScreen(),
        routes: [
          // Must come before `:id` so "new" isn't parsed as a student id.
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateStudentScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => StudentDetailScreen(
              studentId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
});
