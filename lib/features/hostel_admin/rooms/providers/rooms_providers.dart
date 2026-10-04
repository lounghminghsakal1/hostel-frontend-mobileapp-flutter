import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/rooms_repository.dart';
import '../model/room_model.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository(ref.watch(dioProvider));
});

final roomsListProvider = FutureProvider.autoDispose<List<RoomModel>>((ref) {
  return ref.watch(roomsRepositoryProvider).getRooms();
});
