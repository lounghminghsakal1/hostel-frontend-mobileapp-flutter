import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/common/auth/screens/forgot_password_screen.dart';
import '../../features/common/auth/screens/login_screen.dart';
import '../../features/common/auth/screens/set_new_password_page.dart';
import '../../features/hostel_admin/home/screens/admin_home_screen.dart';
import '../../features/hostel_admin/leave_applications/screens/admin_leave_application_detail_screen.dart';
import '../../features/hostel_admin/leave_applications/screens/admin_leave_applications_screen.dart';
import '../../features/hostel_admin/rooms/screens/rooms_list_screen.dart';
import '../../features/hostel_admin/upcoming_events/screens/admin_event_detail_screen.dart';
import '../../features/hostel_admin/upcoming_events/screens/admin_events_screen.dart';
import '../../features/hostel_admin/upcoming_events/screens/event_form_screen.dart';
import '../../features/hostel_admin/students/screens/create_student_screen.dart';
import '../../features/hostel_admin/students/screens/student_detail_screen.dart';
import '../../features/hostel_admin/students/screens/students_list_screen.dart';
import '../../features/student/home/screens/student_home_screen.dart';
import '../../features/common/upcoming_events/screens/event_detail_screen.dart';
import '../../features/student/leave_applications/screens/student_leave_application_detail_screen.dart';
import '../../features/student/leave_applications/screens/student_leave_applications_screen.dart';
import '../../features/student/upcoming_events/screens/student_events_screen.dart';
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
          forgotPassword: state.uri.queryParameters['forgotPassword'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        // `extra` optionally carries the email typed on the login screen.
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentLeaveApplications,
        builder: (context, state) => const StudentLeaveApplicationsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => StudentLeaveApplicationDetailScreen(
              applicationId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.studentEvents,
        builder: (context, state) => const StudentEventsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => EventDetailScreen(
              eventId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRooms,
        builder: (context, state) => const RoomsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLeaveApplications,
        builder: (context, state) => const AdminLeaveApplicationsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => AdminLeaveApplicationDetailScreen(
              applicationId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminEvents,
        builder: (context, state) => const AdminEventsScreen(),
        routes: [
          // Must come before `:id` so "new" isn't parsed as an event id.
          GoRoute(
            path: 'new',
            builder: (context, state) => const EventFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => AdminEventDetailScreen(
              eventId: int.parse(state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => EventFormScreen(
                  eventId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
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
