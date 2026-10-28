import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/network/s3_upload_service.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/announcements/providers/announcements_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/upcoming_events/providers/upcoming_events_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/attendance/data/attendance_repository.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/attendance/providers/attendance_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/attendance/screens/attendance_success_screen.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/model/student_home_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/providers/student_home_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/home/screens/student_home_screen.dart';

class _AttendanceRepository extends AttendanceRepository {
  _AttendanceRepository({this.fail = false})
    : super(Dio(), S3UploadService(Dio()));
  final bool fail;
  int uploads = 0, submissions = 0;
  @override
  Future<String> uploadAttendanceImage(String path) async {
    uploads++;
    return 'attendance/photo.jpg';
  }

  @override
  Future<void> submitAttendanceRecord({
    required String capturedImageKey,
    required double latitude,
    required double longitude,
  }) async {
    submissions++;
    expect(latitude, 12.0);
    expect(longitude, 77.0);
    if (fail) throw StateError('Attendance could not be verified');
  }
}

class _CaptureObserver extends NavigatorObserver {
  _CaptureObserver({this.afterCapture});
  final VoidCallback? afterCapture;
  int captures = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == '/attendance/photo') {
      captures++;
      // Stand in for a hardware camera returning a captured image.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        afterCapture?.call();
        route.navigator?.pop('captured.jpg');
      });
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const camera = MethodChannel('flutter.baseflow.com/permissions/methods');
  const location = MethodChannel('flutter.baseflow.com/geolocator');
  const cameraHardware = MethodChannel('plugins.flutter.io/camera');
  var cameraPermission = 1, locationPermission = 2;
  var locationEnabled = true;
  setUp(() {
    cameraPermission = 1;
    locationPermission = 2;
    locationEnabled = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(camera, (call) async {
      if (call.method == 'checkPermissionStatus') return cameraPermission;
      if (call.method == 'requestPermissions') return {1: cameraPermission};
      return null;
    });
    messenger.setMockMethodCallHandler(
      location,
      (call) async => switch (call.method) {
        'isLocationServiceEnabled' => locationEnabled,
        'checkPermission' || 'requestPermission' => locationPermission,
        'getCurrentPosition' => {
          'latitude': 12.0,
          'longitude': 77.0,
          'accuracy': 5.0,
        },
        _ => null,
      },
    );
    messenger.setMockMethodCallHandler(cameraHardware, (call) async => []);
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [camera, location, cameraHardware]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });
  Future<void> pumpHome(
    WidgetTester tester,
    _AttendanceRepository repository,
    _CaptureObserver observer, {
    VoidCallback? onFetch,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(repository),
          studentHomeProvider.overrideWith((ref) async {
            onFetch?.call();
            return StudentHomeModel(
              canMarkAttendance: repository.submissions == 0,
              isMarkedToday: repository.submissions > 0 && !repository.fail,
            );
          }),
          studentAnnouncementsProvider.overrideWith((ref) async => []),
          upcomingEventsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const StudentHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scenario in [
    'camera denied',
    'location denied',
    'GPS disabled',
    'location unknown',
  ]) {
    testWidgets('$scenario prevents capture and attendance submission', (
      tester,
    ) async {
      if (scenario == 'camera denied') cameraPermission = 0;
      if (scenario == 'location denied') locationPermission = 0;
      if (scenario == 'GPS disabled') locationEnabled = false;
      if (scenario == 'location unknown') locationPermission = 4;
      final repository = _AttendanceRepository();
      final observer = _CaptureObserver();
      await pumpHome(tester, repository, observer);
      await tester.tap(find.text('Mark attendance'));
      await tester.pumpAndSettle();
      expect(observer.captures, 0);
      expect(repository.uploads, 0);
      expect(repository.submissions, 0);
      expect(find.byType(AttendanceSuccessScreen), findsNothing);
    });
  }
  testWidgets(
    'Successful submission shows confirmation, refreshes home, and returns after 3 seconds',
    (tester) async {
      final repository = _AttendanceRepository();
      final observer = _CaptureObserver();
      var fetches = 0;
      await pumpHome(tester, repository, observer, onFetch: () => fetches++);
      await tester.tap(find.text('Mark attendance'));
      await tester.pumpAndSettle();
      expect(find.text('Attendance marked'), findsOneWidget);
      expect(repository.submissions, 1);
      expect(repository.uploads, 1);
      expect(fetches, greaterThanOrEqualTo(2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceSuccessScreen), findsNothing);
      expect(find.text("You're in for tonight"), findsOneWidget);
      expect(fetches, greaterThanOrEqualTo(3));
    },
  );
  testWidgets(
    'Permission revoked during capture blocks upload and submission',
    (tester) async {
      final repository = _AttendanceRepository();
      final observer = _CaptureObserver(
        afterCapture: () => cameraPermission = 0,
      );
      await pumpHome(tester, repository, observer);
      await tester.tap(find.text('Mark attendance'));
      await tester.pumpAndSettle();
      expect(observer.captures, 1);
      expect(repository.uploads, 0);
      expect(repository.submissions, 0);
      expect(find.byType(AttendanceSuccessScreen), findsNothing);
    },
  );
  testWidgets('Server rejection shows an error and never displays success', (
    tester,
  ) async {
    final repository = _AttendanceRepository(fail: true);
    await pumpHome(tester, repository, _CaptureObserver());
    await tester.tap(find.text('Mark attendance'));
    await tester.pumpAndSettle();
    expect(repository.submissions, 1);
    expect(find.byType(AttendanceSuccessScreen), findsNothing);
    expect(
      find.textContaining('Attendance could not be verified'),
      findsOneWidget,
    );
  });
  testWidgets('Manual return cancels the success timer without a second pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                PageRouteBuilder<void>(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (_, a, b) => AttendanceSuccessScreen(
                    markedAt: DateTime.utc(2026, 10, 26, 15),
                  ),
                ),
              ),
              child: const Text('Show success'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show success'));
    await tester.pumpAndSettle();
    expect(find.text("Tonight's window"), findsNothing);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Show success'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
