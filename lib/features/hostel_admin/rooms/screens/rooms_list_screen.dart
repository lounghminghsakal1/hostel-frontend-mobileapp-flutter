import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../students/providers/students_providers.dart';
import '../model/room_model.dart';
import '../providers/rooms_providers.dart';
import '../widgets/room_form_sheet.dart';

/// Admin-only list of rooms; tap a room to edit it, or add a new one.
class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});

  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  String _query = '';

  List<RoomModel> _filter(List<RoomModel> rooms) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return rooms;
    return rooms.where((r) => r.roomNumber.toLowerCase().contains(q)).toList();
  }

  Future<void> _openForm({RoomModel? room}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showRoomFormSheet(context, room: room);
    if (!saved || !mounted) return;
    ref.invalidate(roomsListProvider);
    // The student forms' room dropdown loads the same list.
    ref.invalidate(roomsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(room == null ? 'Room created' : 'Room updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Rooms'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add room'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search by room number',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.navyAlpha(0.5), size: 20),
              ),
            ),
          ),
          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              ),
              error: (error, _) => _RoomsError(
                message: error.toString(),
                onRetry: () => ref.invalidate(roomsListProvider),
              ),
              data: (rooms) {
                final visible = _filter(rooms);
                return RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: () => ref.refresh(roomsListProvider.future),
                  child: visible.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                rooms.isEmpty ? 'No rooms yet' : 'No rooms match your search',
                                style: TextStyle(color: AppColors.navyAlpha(0.5)),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          // Bottom padding keeps the last tile clear of the add button.
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                          itemCount: visible.length,
                          itemBuilder: (context, index) => _RoomTile(
                            room: visible[index],
                            onTap: () => _openForm(room: visible[index]),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.onTap});

  final RoomModel room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final capacity = room.capacity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.meeting_room_outlined, color: AppColors.navy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.roomNumber}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (capacity != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Capacity $capacity',
                          style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, color: AppColors.navyAlpha(0.35), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomsError extends StatelessWidget {
  const _RoomsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navyAlpha(0.6)),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
