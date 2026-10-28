import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../data/rooms_repository.dart';
import '../model/room_model.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository(ref.watch(dioProvider));
});

final roomsListProvider = FutureProvider.autoDispose<List<RoomModel>>((ref) {
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  return ref.watch(roomsRepositoryProvider).getRooms(cancelToken: cancel);
});

/// The rooms API supports separate name and exact-roll searches. Union their
/// results so the single search field also matches occupants.
final roomsMatchingStudentProvider = FutureProvider.autoDispose
    .family<Set<int>, String>((ref, search) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final repository = ref.watch(roomsRepositoryProvider);
      final results = await Future.wait([
        repository.getRooms(
          filters: {'by_student_name': search},
          cancelToken: cancel,
        ),
        repository.getRooms(
          filters: {'by_student_roll_number': search},
          cancelToken: cancel,
        ),
      ]);
      return results.expand((rooms) => rooms).map((room) => room.id).toSet();
    });
