import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/api_listing_view.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/student_business_details.dart';
import '../../students/model/student_model.dart';
import '../../students/providers/students_providers.dart';
import '../model/room_model.dart';
import '../providers/rooms_providers.dart';
import '../widgets/room_form_sheet.dart';

class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});
  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  final key = GlobalKey<ApiListingViewState>();
  Future<void> _edit([RoomModel? room]) async {
    if (await showRoomFormSheet(context, room: room) && mounted) {
      key.currentState?.reload();
      ref.invalidate(roomsProvider);
      ref.invalidate(roomsListProvider);
    }
  }

  Future<void> _occupants(int id) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: _RoomOccupants(id: id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rooms')),
    floatingActionButton: FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('Add room'),
      onPressed: () => _edit(),
    ),
    body: ApiListingView(
      key: key,
      endpoint: ApiEndpoints.rooms,
      filters: roomFilters,
      itemBuilder: (context, row, reload) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room ${row['roomNumber']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Capacity: ${row['capacity']} | Occupied: ${row['occupied']} | Remaining: ${row['remaining']}',
              ),
              Chip(
                label: Text(
                  (row['remaining'] as num? ?? 0) > 0 ? 'Vacant' : 'Full',
                ),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () => _edit(RoomModel.fromJson(row)),
                    child: const Text('Edit room'),
                  ),
                  TextButton(
                    onPressed: () => _occupants((row['id'] as num).toInt()),
                    child: const Text('View occupants'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final _occupantsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final response = await ref
          .watch(dioProvider)
          .get(ApiEndpoints.roomById(id));
      return response.data['data'] as Map<String, dynamic>;
    });

class _RoomOccupants extends ConsumerWidget {
  const _RoomOccupants({required this.id});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(_occupantsProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              TextButton(
                onPressed: () => ref.invalidate(_occupantsProvider(id)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (room) {
          final occupants = (room['studentProfiles'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Room ${room['roomNumber']} occupants',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (occupants.isEmpty) const Text('No occupants'),
              for (final occupant in occupants)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: StudentBusinessDetails(
                    student: StudentModel.fromJson({
                      'id': 0,
                      ...occupant,
                      'room': {'roomNumber': room['roomNumber']},
                    }),
                  ),
                ),
            ],
          );
        },
      );
}
