import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/api_exception.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/dio_client.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/router/app_router.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/router/app_routes.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/theme/hostel_colors.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/utils/date_format.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/announcements/model/announcement_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/announcements/data/announcements_repository.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/announcements/providers/announcements_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/announcements/screens/announcement_form_screen.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/upcoming_events/providers/upcoming_events_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/model/student_home_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/widgets/attendance_action_card.dart';

Map<String, dynamic> notice(
  int id, {
  bool important = false,
  String status = 'ACTIVE',
  String start = '2020-01-01',
  String end = '2099-12-31',
}) => {
  'id': id,
  'title': 'Notice $id',
  'description': 'Details for notice $id',
  'status': status,
  'startDate': start,
  'endDate': end,
  'announcementType': 'HOSTEL_ANNOUNCEMENT',
  'isImportant': important,
  'pushNotification': false,
  'createdAt': '2026-10-26T10:00:00.000Z',
};
Dio fakeDio(
  Object Function(RequestOptions) respond,
  List<RequestOptions> calls,
) => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (r, h) {
        calls.add(r);
        h.resolve(
          Response(requestOptions: r, statusCode: 200, data: respond(r)),
        );
      },
    ),
  );

void main() {
  test('Student notices paginate, filter publication dates, and prioritize important', () async {
    final calls = <RequestOptions>[];
    final repo = AnnouncementsRepository(
      fakeDio(
        (r) => {
          'status': 'success',
          'data': {
            'announcements': r.queryParameters['page'] == '1'
                ? [
                    notice(1),
                    notice(2, end: '2020-01-01'),
                    notice(3, start: '2099-01-01'),
                  ]
                : [notice(4, important: true), notice(5, status: 'INACTIVE')],
            'totalAnnouncementsCount': 21,
          },
        },
        calls,
      ),
    );
    expect((await repo.studentAnnouncements()).map((a) => a.id), [4, 1]);
    expect(calls.length, 2);
    expect(
      calls.every(
        (r) =>
            r.path == '/announcements' &&
            r.queryParameters['by_status'] == 'ACTIVE',
      ),
      isTrue,
    );
    expect(calls.last.queryParameters['page'], '2');
  });
  test(
    'Create sends schema names, date-only strings, booleans and optional URL',
    () async {
      final calls = <RequestOptions>[];
      final repo = AnnouncementsRepository(
        fakeDio((r) => {'status': 'success', 'data': {}}, calls),
      );
      await repo.create(
        AnnouncementInput(
          title: '  Water notice  ',
          description: ' Details ',
          status: 'ACTIVE',
          startDate: DateTime(2026, 10, 27),
          endDate: DateTime(2026, 10, 28),
          pushNotification: true,
          isImportant: false,
          announcementType: 'COLLEGE_ANNOUNCEMENT',
        ),
      );
      expect(calls.single.method, 'POST');
      expect(calls.single.data, {
        'title': 'Water notice',
        'description': 'Details',
        'status': 'ACTIVE',
        'startDate': '2026-10-27',
        'endDate': '2026-10-28',
        'pushNotification': true,
        'isImportant': false,
        'announcementType': 'COLLEGE_ANNOUNCEMENT',
      });
      calls.clear();
      await repo.update(7, {'isImportant': true});
      expect(calls.single.method, 'PATCH');
      expect(calls.single.path, '/announcements/7');
      expect(calls.single.data, {'isImportant': true});
    },
  );
  test(
    'Admin detail unwraps an announcement and preserves calendar dates',
    () async {
      final calls = <RequestOptions>[];
      final repo = AnnouncementsRepository(
        fakeDio(
          (r) => {
            'status': 'success',
            'data': {
              'announcement': notice(3, start: '2026-10-27T00:00:00.000Z'),
            },
          },
          calls,
        ),
      );
      final a = await repo.get(3);
      expect(a.startDate, DateTime(2026, 10, 27));
      expect(a.category, 'Hostel');
      expect(calls.single.path, '/announcements/3');
    },
  );
  test('Announcement request failures are surfaced', () async {
    final repo = AnnouncementsRepository(
      fakeDio((r) => {'status': 'failure', 'message': 'Forbidden'}, []),
    );
    await expectLater(repo.get(1), throwsA(isA<ApiException>()));
    await expectLater(repo.list(), throwsA(isA<ApiException>()));
  });
  test(
    'Attendance state uses evidence and does not label an unknown state missed',
    () {
      final now = DateTime.utc(2026, 10, 26, 15);
      expect(
        const StudentHomeModel(canMarkAttendance: false).attendanceState(now),
        AttendanceCardState.unavailable,
      );
      expect(
        const StudentHomeModel(canMarkAttendance: true).attendanceState(now),
        AttendanceCardState.open,
      );
      expect(
        const StudentHomeModel(
          canMarkAttendance: false,
          hasProfilePhoto: false,
        ).attendanceState(now),
        AttendanceCardState.photoNeeded,
      );
      expect(
        StudentHomeModel(
          canMarkAttendance: false,
          windowOpensAt: now.add(const Duration(hours: 1)),
        ).attendanceState(now),
        AttendanceCardState.upcoming,
      );
      expect(
        StudentHomeModel(
          canMarkAttendance: false,
          windowClosesAt: now,
        ).attendanceState(now),
        AttendanceCardState.missed,
      );
      expect(
        StudentHomeModel(
          canMarkAttendance: false,
          markedAt: now,
        ).attendanceState(now),
        AttendanceCardState.marked,
      );
      expect(
        const StudentHomeModel(canMarkAttendance: false).attendanceState(
          now,
          locallyMarkedAt: now.subtract(const Duration(days: 1)),
        ),
        AttendanceCardState.unavailable,
      );
    },
  );
  testWidgets(
    'All attendance card states fit a compact screen with larger text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = DateTime.now();
      final models = [
        const StudentHomeModel(canMarkAttendance: true),
        const StudentHomeModel(canMarkAttendance: false, isMarkedToday: true),
        StudentHomeModel(
          canMarkAttendance: false,
          windowOpensAt: now.add(const Duration(hours: 1)),
        ),
        StudentHomeModel(
          canMarkAttendance: false,
          windowClosesAt: now.subtract(const Duration(hours: 1)),
        ),
        const StudentHomeModel(
          canMarkAttendance: false,
          hasProfilePhoto: false,
        ),
      ];
      for (final home in models) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AttendanceActionCard(
                      home: home,
                      onMark: () {},
                      onRefresh: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'Student home and Notices fetch separately; student detail uses list GET',
    (tester) async {
      final calls = <RequestOptions>[];
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            fakeDio((r) {
              if (r.path == '/students/home') {
                return {
                  'status': 'success',
                  'data': {
                    'canMarkAttendance': true,
                    'studentName': 'Arun Kumar',
                    'roomNumber': 'NH-3-118',
                    'announcementsData': [
                      {'title': 'Embedded notice must be ignored'},
                    ],
                  },
                };
              }
              return {
                'status': 'success',
                'data': [notice(1, important: true)],
              };
            }, calls),
          ),
          upcomingEventsProvider.overrideWith((ref) async => []),
        ],
      );
      final router = container.read(appRouterProvider)
        ..go(AppRoutes.studentHome);
      addTearDown(() {
        router.dispose();
        container.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(extensions: const [HostelColors.light]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Arun Kumar'), findsOneWidget);
      expect(find.text('Notice 1'), findsOneWidget);
      expect(find.text('Embedded notice must be ignored'), findsNothing);
      expect(calls.any((r) => r.path == '/students/home'), isTrue);
      expect(calls.any((r) => r.path == '/announcements'), isTrue);
      await tester.tap(find.text('Notices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notice 1'));
      await tester.pumpAndSettle();
      expect(find.text('Details for notice 1'), findsOneWidget);
      expect(calls.any((r) => r.path == '/announcements/1'), isFalse);
      expect(find.text('Edit'), findsNothing);
    },
  );
  testWidgets('Admin edit patches only changed fields', (tester) async {
    final calls = <RequestOptions>[];
    final repo = AnnouncementsRepository(
      fakeDio(
        (r) => r.method == 'GET'
            ? {'status': 'success', 'data': notice(1)}
            : {'status': 'success', 'data': {}},
        calls,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [announcementsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AnnouncementFormScreen(id: 1),
                  ),
                ),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Updated title');
    await tester.scrollUntilVisible(
      find.text('Save announcement'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save announcement'));
    await tester.pumpAndSettle();
    final patch = calls.singleWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/announcements/1');
    expect(patch.data, {'title': 'Updated title'});
    expect(find.text('Open editor'), findsOneWidget);
  });
  test('Publication end date is inclusive in the hostel calendar', () {
    final a = AnnouncementModel.fromJson(
      notice(1, start: '2026-10-26', end: '2026-10-27'),
    );
    expect(
      a.visibleOn(indiaWallTime(DateTime.utc(2026, 10, 27, 18, 29))),
      isTrue,
    );
    expect(
      a.visibleOn(indiaWallTime(DateTime.utc(2026, 10, 27, 18, 30))),
      isFalse,
    );
  });
}
