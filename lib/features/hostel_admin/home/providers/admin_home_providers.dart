import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/admin_home_repository.dart';
import '../model/admin_dashboard_model.dart';
import '../model/marked_student_model.dart';

final adminHomeRepositoryProvider = Provider<AdminHomeRepository>((ref) {
  return AdminHomeRepository(ref.watch(dioProvider));
});

// TODO: switch back to `adminHomeRepositoryProvider.getDashboard()` once the
// dashboard API is ready. Placeholder data until then.
final adminDashboardProvider = FutureProvider<AdminDashboardModel>((ref) async {
  return _dummyDashboard;
});

const _dummyDashboard = AdminDashboardModel(
  hostelName: 'Boys Hostel A',
  dateLabel: 'Today',
  totalStudents: 120,
  markedPresent: 96,
  notMarked: 24,
  markedStudents: [
    MarkedStudentModel(
      name: 'Arjun Kumar',
      rollNumber: '21CS045',
      roomNumber: '204',
      time: '08:12 PM',
      faceMatch: 97,
      initials: 'AK',
    ),
    MarkedStudentModel(
      name: 'Rahul Sharma',
      rollNumber: '21EC012',
      roomNumber: '118',
      time: '08:05 PM',
      faceMatch: 94,
      initials: 'RS',
    ),
    MarkedStudentModel(
      name: 'Vikram Reddy',
      rollNumber: '22ME031',
      roomNumber: '311',
      time: '07:58 PM',
      faceMatch: 91,
      initials: 'VR',
    ),
  ],
);
