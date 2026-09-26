import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/student_home_repository.dart';
import '../model/student_home_model.dart';

final studentHomeRepositoryProvider = Provider<StudentHomeRepository>((ref) {
  return StudentHomeRepository(ref.watch(dioProvider));
});

final studentHomeProvider = FutureProvider<StudentHomeModel>((ref) {
  return ref.watch(studentHomeRepositoryProvider).getHomeScreen();
});
