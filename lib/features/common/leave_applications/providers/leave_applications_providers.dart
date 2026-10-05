import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/leave_applications_repository.dart';
import '../model/leave_application_model.dart';

final leaveApplicationsRepositoryProvider = Provider<LeaveApplicationsRepository>((ref) {
  return LeaveApplicationsRepository(ref.watch(dioProvider));
});

/// Admin: every application in the hostel.
final adminLeaveApplicationsProvider = FutureProvider.autoDispose<List<LeaveApplicationModel>>((ref) {
  return ref.watch(leaveApplicationsRepositoryProvider).getLeaveApplications();
});

final adminLeaveApplicationDetailProvider =
    FutureProvider.autoDispose.family<LeaveApplicationModel, int>((ref, id) {
  return ref.watch(leaveApplicationsRepositoryProvider).getLeaveApplication(id);
});

/// Student: the signed-in student's own applications.
final myLeaveApplicationsProvider = FutureProvider.autoDispose<List<LeaveApplicationModel>>((ref) {
  return ref.watch(leaveApplicationsRepositoryProvider).getMyLeaveApplications();
});

final myLeaveApplicationDetailProvider =
    FutureProvider.autoDispose.family<LeaveApplicationModel, int>((ref, id) {
  return ref.watch(leaveApplicationsRepositoryProvider).getMyLeaveApplication(id);
});
