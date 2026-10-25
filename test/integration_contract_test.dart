import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/api_exception.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/dio_client.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/listing_api.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/s3_upload_service.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/utils/date_format.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/widgets/api_listing_view.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/widgets/listing_filters.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/leave_applications/data/leave_applications_repository.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/upcoming_events/data/upcoming_events_repository.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/attendance/model/attendance_records_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/students/data/students_repository.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/students/providers/students_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/hostel_admin/students/screens/student_detail_screen.dart';

Dio fakeDio(
  Object Function(RequestOptions) respond,
  List<RequestOptions> requests,
) => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: respond(options),
          ),
        );
      },
    ),
  );

Map<String, dynamic> envelope(
  List<Map<String, dynamic>> rows, {
  int page = 1,
  int pages = 1,
}) => {
  'status': 'success',
  'data': rows,
  'meta': {'page': page, 'pageSize': 20, 'totalPages': pages},
};

void main() {
  testWidgets(
    'student edit sends changed fields and reports an ignored roll-number update',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final requests = <RequestOptions>[];
      final dio = fakeDio(
        (o) => {
          'status': 'success',
          'data': {
            'id': 1,
            'studentName': 'Ravi',
            'rollNumber': '00123',
            'contactNumber': '9000000001',
            'parentMobileNumber': '9000000002',
            'departmentId': 1,
            'roomId': null,
          },
        },
        requests,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            departmentsProvider.overrideWith((ref) async => []),
            roomsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: StudentDetailScreen(studentId: 1)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Roll number'),
        '00125',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(requests.where((o) => o.method == 'PATCH').single.data, {
        'rollNumber': '00125',
      });
      expect(requests.where((o) => o.method == 'GET').length, greaterThan(1));
      expect(
        find.textContaining('Roll number was not saved by the backend'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('IST moments and calendar dates have separate wire contracts', () {
    final instant = indiaPickerToInstant(DateTime(2026, 10, 24, 10));
    expect(toUtcInstant(instant), '2026-10-24T04:30:00.000Z');
    expect(
      toUtcInstant(DateTime.utc(2026, 10, 24, 4, 30, 0, 0, 123)),
      '2026-10-24T04:30:00.000Z',
    );
    expect(
      instantToDisplay('2026-10-24T20:00:00.000Z'),
      '25 Oct 2026, 1:30 AM IST',
    );
    expect(apiDateToDisplay('2026-10-24T00:00:00.000Z'), '24 Oct 2026');
    expect(toIsoDate(DateTime(2026, 10, 24)), '2026-10-24');
    expect(instantToDisplay(null), '—');
  });

  test('lists read top-level meta and preserve roll numbers while omitting unused filters', () async {
    final requests = <RequestOptions>[];
    final dio = fakeDio(
      (o) => envelope(
        [
          {'id': 1},
        ],
        page: 2,
        pages: 4,
      ),
      requests,
    );
    final filters = {'by_roll_number': '00123', 'by_room_id': ''};
    final result = await ListingApi(dio)
        .fetch('/students', page: 2, filters: filters);
    expect(result.page, 2);
    expect(result.pageSize, 20);
    expect(result.totalPages, 4);
    expect(requests.single.queryParameters, {
      'by_roll_number': '00123',
      'page': '2',
      'pageSize': '20',
    });
    expect(filters.containsKey('by_room_id'), isTrue);
  });

  test(
    'leave counts come from statusesCount rather than visible rows',
    () async {
      final dio = fakeDio(
        (o) => {
          'status': 'success',
          'data': {
            'leaveApplications': <Map<String, dynamic>>[],
            'statusesCount': {'APPROVED': 9, 'REJECTED': 4},
          },
          'meta': {'page': 1, 'pageSize': 20, 'totalPages': 1},
        },
        [],
      );
      final result = await ListingApi(dio).fetch('/leave_applications');
      expect(result.rows, isEmpty);
      expect(result.counts['APPROVED'], 9);
    },
  );

  test('room lookup loads all pages for scalar student room IDs', () async {
    final requests = <RequestOptions>[];
    final dio = fakeDio(
      (o) => envelope([
        {
          'id': int.parse(o.queryParameters['page']),
          'roomNumber': 'Room ${o.queryParameters['page']}',
        },
      ], pages: 3),
      requests,
    );
    final options = await StudentsRepository(
      dio,
      S3UploadService(dio),
    ).getRooms();
    expect(options.map((o) => o.id), [1, 2, 3]);
    expect(
      requests.every((o) => o.queryParameters['pageSize'] == '20'),
      isTrue,
    );
  });

  test('event writes serialize exactly milliseconds and lists specify active workaround', () async {
    final requests = <RequestOptions>[];
    final dio = fakeDio(
      (o) => o.method == 'GET' ? envelope([]) : {'status': 'success'},
      requests,
    );
    final repository = UpcomingEventsRepository(dio, S3UploadService(dio));
    await repository.getUpcomingEvents();
    expect(requests.last.queryParameters['is_active'], 'false');
    await repository.createUpcomingEvent((
      eventName: 'Meeting',
      eventDescription: 'Monthly meeting',
      startingAt: DateTime.utc(2026, 10, 24, 12, 30, 0, 0, 123),
      endingAt: DateTime.utc(2026, 10, 24, 13, 30),
      eventImageKey: null,
      eventLink: null,
      contactPersonName: null,
      contactPersonPhone: null,
      isActive: null,
    ));
    expect(requests.last.data['startingAt'], '2026-10-24T12:30:00.000Z');
  });

  test(
    'leave updates reject unpaired or inverted dates before networking',
    () async {
      final requests = <RequestOptions>[];
      final dio = fakeDio((o) => {'status': 'success'}, requests);
      final repository = LeaveApplicationsRepository(dio);
      await expectLater(
        repository.updateLeaveApplication(
          id: 1,
          fromDate: DateTime(2026, 10, 24),
        ),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        repository.updateLeaveApplication(
          id: 1,
          fromDate: DateTime(2026, 10, 24),
          toDate: DateTime(2026, 10, 23),
        ),
        throwsA(isA<ApiException>()),
      );
      expect(requests, isEmpty);
    },
  );

  test('present and absent responses retain different business details', () {
    final present = PresentAttendanceRecord.fromJson({
      'reportedTime': '2026-10-24T15:05:12.345Z',
      'student': {
        'studentName': 'Ravi',
        'rollNumber': '00123',
        'studentImageKey': 'profile/key',
        'contactNumber': '9000000001',
        'department': {'departmentName': 'CS'},
      },
    });
    expect(present.reportedTime, '2026-10-24T15:05:12.345Z');
    expect(present.departmentName, 'CS');
    expect(present.studentImageKey, 'profile/key');
    final absent = AbsentAttendanceRecord.fromJson({
      'studentName': 'Meena',
      'rollNumber': '00124',
      'department': 'CS',
      'parentMobileNumber': '9000000002',
      'absentDates': ['2026-10-24'],
    });
    expect(absent.departmentName, 'CS');
    expect(absent.parentMobileNumber, '9000000002');
    expect(absent.absentDates, ['2026-10-24']);
  });

  testWidgets(
    'server pagination resets on a debounced filter and preserves leading zeros',
    (tester) async {
      final requests = <RequestOptions>[];
      final dio = fakeDio(
        (o) => envelope(
          [
            {'name': 'Result ${o.queryParameters['page']}'},
          ],
          page: int.parse(o.queryParameters['page']),
          pages: 3,
        ),
        requests,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: MaterialApp(
            home: Scaffold(
              body: ApiListingView(
                endpoint: '/students',
                filters: const [
                  ListingFilter('by_roll_number', 'Exact roll number'),
                ],
                itemBuilder: (context, row, reload) =>
                    Text(row['name'] as String),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['page'], '2');
      await tester.tap(find.text('Search and filters'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '00123');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['page'], '1');
      expect(requests.last.queryParameters['by_roll_number'], '00123');
    },
  );

  testWidgets(
    'events paginate the complete response without requesting repeated pages',
    (tester) async {
      final requests = <RequestOptions>[];
      final dio = fakeDio(
        (o) =>
            envelope(List.generate(25, (i) => {'name': 'Event $i'}), pages: 2),
        requests,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: MaterialApp(
            home: Scaffold(
              body: ApiListingView(
                endpoint: '/upcoming_events',
                filters: const [],
                events: true,
                itemBuilder: (context, row, reload) =>
                    SizedBox(height: 20, child: Text(row['name'] as String)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('Event 20'), findsOneWidget);
      expect(find.text('Event 0'), findsNothing);
      expect(requests.length, 1);
      expect(requests.single.queryParameters['is_active'], 'false');
    },
  );
}
