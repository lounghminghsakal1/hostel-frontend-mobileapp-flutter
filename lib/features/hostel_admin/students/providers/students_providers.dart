import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/s3_upload_service.dart';
import '../data/students_repository.dart';
import '../model/select_option.dart';
import '../model/student_model.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepository(ref.watch(dioProvider), ref.watch(s3UploadServiceProvider));
});

final studentsListProvider = FutureProvider.autoDispose<List<StudentModel>>((ref) {
  return ref.watch(studentsRepositoryProvider).getStudents();
});

final studentDetailProvider = FutureProvider.autoDispose.family<StudentModel, int>((ref, id) {
  return ref.watch(studentsRepositoryProvider).getStudent(id);
});

final departmentsProvider = FutureProvider.autoDispose<List<SelectOption>>((ref) {
  return ref.watch(studentsRepositoryProvider).getDepartments();
});

final roomsProvider = FutureProvider.autoDispose<List<SelectOption>>((ref) {
  return ref.watch(studentsRepositoryProvider).getRooms();
});
