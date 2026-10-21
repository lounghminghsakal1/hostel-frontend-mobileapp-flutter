import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management_frontend_mobile_app_flutter/core/router/app_router.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/router/app_routes.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/widgets/app_search_field.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/widgets/gradient_button.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/auth/model/user_role.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/auth/providers/auth_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/leave_applications/providers/leave_applications_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/upcoming_events/providers/upcoming_events_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/rooms/model/room_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/rooms/providers/rooms_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/students/providers/students_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/model/student_home_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/providers/student_home_providers.dart';

class _TestAuthController extends AuthController {
  int loginCalls = 0;

  @override
  Future<UserRole?> build() async => null;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalls++;
  }
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  String location, {
  _TestAuthController? auth,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth ?? _TestAuthController()),
      studentHomeProvider.overrideWith(
        (ref) async =>
            const StudentHomeModel(canMarkAttendance: true, announcements: []),
      ),
      upcomingEventsProvider.overrideWith((ref) async => []),
      upcomingEventDetailProvider(7)
          .overrideWith((ref) async => throw StateError('Unavailable')),
      myLeaveApplicationsProvider.overrideWith((ref) async => []),
      roomsListProvider.overrideWith(
        (ref) async => const [
          RoomModel(id: 1, roomNumber: '101'),
          RoomModel(id: 2, roomNumber: '202'),
        ],
      ),
      studentsListProvider.overrideWith((ref) async => []),
    ],
  );
  final router = container.read(appRouterProvider);
  router.go(location);
  addTearDown(() {
    router.dispose();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Sign in validates locally before contacting the server', (
    tester,
  ) async {
    final auth = _TestAuthController();
    await _pumpApp(tester, AppRoutes.login, auth: auth);
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(auth.loginCalls, 0);

    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(auth.loginCalls, 0);
  });

  testWidgets('Sign in remains usable with a keyboard on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await _pumpApp(tester, AppRoutes.login);
    await tester.ensureVisible(find.text('Sign in'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('Password visibility has a labeled toggle', (tester) async {
    await _pumpApp(tester, AppRoutes.login);
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );
  });

  testWidgets('Student navigation reaches real sections and returns home', (
    tester,
  ) async {
    final container = await _pumpApp(tester, AppRoutes.studentHome);
    expect(find.text('Mark Attendance'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.studentLeaveApplications,
    );
    expect(find.text('Apply for leave'), findsOneWidget);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.studentEvents,
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Mark Attendance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Admin navigation preserves room search and clear restores results',
    (tester) async {
      await _pumpApp(tester, AppRoutes.adminRooms);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.enterText(find.byType(TextField), '101');
      await tester.pumpAndSettle();
      expect(find.text('1 result'), findsOneWidget);
      await tester.tap(find.text('Students'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rooms').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '101',
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
      expect(find.byTooltip('Clear search'), findsNothing);
      expect(find.text('1 result'), findsNothing);
      expect(find.byType(AppSearchField), findsOneWidget);
    },
  );

  testWidgets(
    'Event details hide navigation and Back returns to the event list',
    (tester) async {
      final container = await _pumpApp(tester, AppRoutes.studentEventDetail(7));
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.studentEvents,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets('Forgot password keeps the email already entered', (
    tester,
  ) async {
    await _pumpApp(tester, AppRoutes.login);
    await tester.enterText(
      find.byType(TextFormField).first,
      'student@example.com',
    );
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot Password'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'student@example.com',
    );
  });

  testWidgets('Loading and disabled buttons reject repeated actions', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GradientButton(
                label: 'Saving',
                isLoading: true,
                onPressed: () => presses++,
              ),
              const GradientButton(label: 'Unavailable', onPressed: null),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.tap(find.byType(FilledButton).last);
    expect(presses, 0);
  });
}
