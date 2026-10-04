import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/leave_applications_repository.dart';
import '../model/leave_application_model.dart';

final leaveApplicationsRepositoryProvider = Provider<LeaveApplicationsRepository>((ref) {
  return LeaveApplicationsRepository(ref.watch(dioProvider));
});

final leaveApplicationsProvider = FutureProvider.autoDispose<List<LeaveApplicationModel>>((ref) {
  return ref.watch(leaveApplicationsRepositoryProvider).getLeaveApplications();
});

final leaveApplicationDetailProvider =
    FutureProvider.autoDispose.family<LeaveApplicationModel, int>((ref, id) {
  return ref.watch(leaveApplicationsRepositoryProvider).getLeaveApplication(id);
});
