import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/theme/hostel_colors.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/core/utils/date_format.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/leave_applications/data/leave_applications_repository.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/leave_applications/model/leave_application_model.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/common/leave_applications/providers/leave_applications_providers.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/leave_applications/screens/leave_application_form_screen.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/leave_applications/screens/student_leave_applications_screen.dart';
import 'package:hostel_management_frontend_mobile_app_flutter/features/student/leave_applications/widgets/student_leave_card.dart';

LeaveApplicationModel application(int id, LeaveStatus status) {
  final date = DateUtils.dateOnly(indiaWallTime(DateTime.now()))
      .add(const Duration(days: 1));
  return LeaveApplicationModel(
    id: id,
    status: status,
    fromDate: date,
    toDate: date.add(const Duration(days: 3)),
    leaveReason: 'Going home for a family event.',
    rejectionReason: status == LeaveStatus.rejected
        ? 'Apply again after exams.'
        : null,
  );
}

class _Repository extends LeaveApplicationsRepository {
  _Repository(this.items) : super(Dio());
  List<LeaveApplicationModel> items;
  int creates = 0, updates = 0, cancels = 0, fetches = 0;
  String? reason;
  DateTime? from, to;
  Completer<void>? pendingSave;
  @override
  Future<List<LeaveApplicationModel>> getMyLeaveApplications() async {
    fetches++;
    return items;
  }

  @override
  Future<void> createLeaveApplication({
    required String leaveReason,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    creates++;
    reason = leaveReason;
    from = fromDate;
    to = toDate;
    if (pendingSave != null) await pendingSave!.future;
    items = [application(1, LeaveStatus.pending)];
  }

  @override
  Future<void> updateLeaveApplication({
    required int id,
    String? leaveReason,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    updates++;
    reason = leaveReason;
    from = fromDate;
    to = toDate;
  }

  @override
  Future<void> cancelLeaveApplication(int id) async {
    cancels++;
    items = [application(id, LeaveStatus.cancelled)];
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _Repository repo,
  Widget screen,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [leaveApplicationsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [HostelColors.light]),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pickDate(WidgetTester tester, bool from, DateTime value) async {
  await tester.tap(find.byKey(ValueKey(from ? 'leave-from' : 'leave-to')));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Switch to input'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField).last,
    '${value.month}/${value.day}/${value.year}',
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Pending leave displays banner and actions; reviewed leave displays admin note',
    (tester) async {
      final repo = _Repository([
        application(1, LeaveStatus.pending),
        application(2, LeaveStatus.rejected),
        application(3, LeaveStatus.approved),
      ]);
      await _pumpScreen(tester, repo, const StudentLeaveApplicationsScreen());
      expect(find.text('You have a pending request'), findsOneWidget);
      expect(find.text('Apply for leave'), findsNothing);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Cancel request'), findsOneWidget);
      expect(find.text('Note from hostel admin'), findsOneWidget);
      expect(find.text('Apply again after exams.'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    },
  );
  testWidgets(
    'Edit opens full-page form with prefilled reason and inclusive day count',
    (tester) async {
      final repo = _Repository([application(1, LeaveStatus.pending)]);
      await _pumpScreen(tester, repo, const StudentLeaveApplicationsScreen());
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit leave request'), findsOneWidget);
      expect(find.text('4 days of leave'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      await tester.enterText(
        find.byType(TextFormField),
        'Updated family plans',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(repo.updates, 1);
      expect(repo.reason, 'Updated family plans');
      expect(repo.from, isNull);
      expect(repo.to, isNull);
      expect(find.text('You have a pending request'), findsOneWidget);
      expect(repo.fetches, greaterThanOrEqualTo(2));
    },
  );
  testWidgets('Cancellation needs confirmation and refreshes leave actions', (
    tester,
  ) async {
    final repo = _Repository([application(1, LeaveStatus.pending)]);
    await _pumpScreen(tester, repo, const StudentLeaveApplicationsScreen());
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(repo.cancels, 0);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(repo.cancels, 0);
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel leave'));
    await tester.pumpAndSettle();
    expect(repo.cancels, 1);
    expect(find.text('You have a pending request'), findsNothing);
    expect(find.text('Apply for leave'), findsOneWidget);
  });
  testWidgets(
    'Create validates reason and dates before submitting selected calendar dates',
    (tester) async {
      final repo = _Repository([]);
      await _pumpScreen(tester, repo, const StudentLeaveApplicationsScreen());
      await tester.tap(find.text('Apply for leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit request'));
      await tester.pumpAndSettle();
      expect(find.text('Tell us why you need leave'), findsOneWidget);
      expect(repo.creates, 0);
      await tester.enterText(find.byType(TextFormField), 'Going home');
      await tester.tap(find.text('Submit request'));
      await tester.pumpAndSettle();
      expect(find.text('Select the leave dates'), findsOneWidget);
      expect(repo.creates, 0);
      final from = DateUtils.dateOnly(indiaWallTime(DateTime.now()))
          .add(const Duration(days: 2));
      final to = from.add(const Duration(days: 3));
      await pickDate(tester, true, from);
      await pickDate(tester, false, to);
      expect(find.text('4 days of leave'), findsOneWidget);
      await tester.tap(find.text('Submit request'));
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(repo.from, from);
      expect(repo.to, to);
      expect(find.text('You have a pending request'), findsOneWidget);
    },
  );
  testWidgets(
    'Reason is limited to 300 characters and form fits with keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.reset);
      await _pumpScreen(
        tester,
        _Repository([]),
        const LeaveApplicationFormScreen(),
      );
      await tester.enterText(find.byType(TextFormField), 'a' * 310);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .controller
            .text
            .length,
        300,
      );
      expect(find.text('300 / 300'), findsOneWidget);
      expect(tester.getCenter(find.text('Submit request')).dy, lessThan(328));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Leave cards wrap status and actions at larger text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StudentLeaveCard(
                  application: application(1, LeaveStatus.rejected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  test('Date labels include both years when needed', () {
    expect(
      studentLeaveDateRangeLabel(DateTime(2026, 12, 31), DateTime(2027, 1, 2)),
      '31 Dec 2026 \u2013 2 Jan 2027',
    );
    expect(
      studentLeaveDateRangeLabel(
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 30),
      ),
      '27 \u2013 30 Oct 2026',
    );
  });
}
