import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/admin_attendance_repository.dart';
import '../model/attendance_records_model.dart';

final adminAttendanceRepositoryProvider = Provider<AdminAttendanceRepository>((ref) {
  return AdminAttendanceRepository(ref.watch(dioProvider));
});

final attendanceRecordsProvider =
    FutureProvider.autoDispose.family<AttendanceRecordsResult, AttendanceQuery>((ref, query) {
  return ref.watch(adminAttendanceRepositoryProvider).getAttendanceRecords(query);
});
