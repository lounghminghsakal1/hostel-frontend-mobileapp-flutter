import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/student_business_details.dart';
import '../../students/model/student_model.dart';
import '../../students/providers/students_providers.dart';
import '../model/room_model.dart';
import '../providers/rooms_providers.dart';
import '../widgets/room_form_sheet.dart';
import '../widgets/room_occupancy_card.dart';

enum _Availability { all, free, full }

class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});
  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  _Availability _availability = _Availability.all;
  int _minimumFreeBeds = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(roomsListProvider);
    if (_search.isNotEmpty) {
      ref.invalidate(roomsMatchingStudentProvider(_search));
    }
    await ref.read(roomsListProvider.future);
    if (_search.isNotEmpty) {
      await ref.read(roomsMatchingStudentProvider(_search).future);
    }
  }

  Future<void> _edit([RoomModel? room]) async {
    if (await showRoomFormSheet(context, room: room) && mounted) {
      ref.invalidate(roomsProvider);
      await _refresh();
    }
  }

  Future<void> _occupants(RoomModel room) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.roomNumber,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _edit(room);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit room'),
                    ),
                  ],
                ),
              ),
              Expanded(child: _RoomOccupants(id: room.id)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final roomsAsync = ref.watch(roomsListProvider);
    final rooms = roomsAsync.valueOrNull ?? const <RoomModel>[];
    final matches = _search.isEmpty
        ? const AsyncData<Set<int>>({})
        : ref.watch(roomsMatchingStudentProvider(_search));
    final searchText = _search.toLowerCase();
    final matchingRooms = rooms
        .where(
          (room) =>
              searchText.isEmpty ||
              room.roomNumber.toLowerCase().contains(searchText) ||
              (matches.valueOrNull?.contains(room.id) ?? false),
        )
        .toList();
    final visible = matchingRooms.where((room) {
      if (_minimumFreeBeds > 0 && (room.freeBeds ?? 0) < _minimumFreeBeds) {
        return false;
      }
      return switch (_availability) {
        _Availability.all => true,
        _Availability.free => room.hasFreeBeds,
        _Availability.full => room.isFull,
      };
    }).toList();
    final freeCount = matchingRooms.where((room) => room.hasFreeBeds).length;
    final fullCount = matchingRooms.where((room) => room.isFull).length;
    final bedsKnown = rooms.every((room) => room.freeBeds != null);
    final freeBeds = rooms.fold<int>(
      0,
      (count, room) => count + (room.freeBeds ?? 0),
    );
    final loading = roomsAsync.isLoading || matches.isLoading;
    final error = roomsAsync.error ?? matches.error;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Rooms',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            if (roomsAsync.hasValue)
              Text(
                '${rooms.length} rooms${bedsKnown ? ' \u00b7 $freeBeds beds free' : ''}',
                style: TextStyle(color: c.inkMuted, fontSize: 11.5),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add room',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _edit(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchChanged,
                      decoration: InputDecoration(
                        hintText: 'Room number or student',
                        hintStyle: TextStyle(color: c.inkMuted, fontSize: 13),
                        prefixIcon: Icon(
                          Icons.search,
                          color: c.inkMuted,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _debounce?.cancel();
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        filled: true,
                        fillColor: c.surfaceRaised,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.lineStrong),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.focus, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: OutlinedButton(
                    onPressed: _filters,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.surfaceRaised,
                      foregroundColor: c.ink,
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: c.lineStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 21),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _chip('All', matchingRooms.length, _Availability.all, c),
                const SizedBox(width: 8),
                _chip('Has free beds', freeCount, _Availability.free, c),
                const SizedBox(width: 8),
                _chip('Full', fullCount, _Availability.full, c),
              ],
            ),
          ),
          if (_minimumFreeBeds > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'At least $_minimumFreeBeds free beds',
                style: TextStyle(color: c.inkMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: loading || error != null || visible.isEmpty
                    ? 1
                    : (visible.length / 2).ceil(),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (loading) {
                    return const Padding(
                      padding: EdgeInsets.all(64),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text('$error', textAlign: TextAlign.center),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (visible.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No rooms match these filters',
                          style: TextStyle(color: c.inkMuted),
                        ),
                      ),
                    );
                  }
                  final first = visible[index * 2];
                  final second = index * 2 + 1 < visible.length
                      ? visible[index * 2 + 1]
                      : null;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: RoomOccupancyCard(
                            room: first,
                            onTap: () => _occupants(first),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: second == null
                              ? const SizedBox.shrink()
                              : RoomOccupancyCard(
                                  room: second,
                                  onTap: () => _occupants(second),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, _Availability value, HostelColors c) {
    final selected = _availability == value;
    return Material(
      color: selected ? c.brand : c.surfaceRaised,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.brand : c.lineStrong),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => setState(() {
          _availability = value;
          _minimumFreeBeds = 0;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '$label  $count',
            style: TextStyle(
              color: selected ? c.onBrand : c.ink,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _filters() async {
    var selection = _availability;
    var minimum = _minimumFreeBeds;
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: c.surfaceRaised,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter rooms',
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in const {
                      _Availability.all: 'All',
                      _Availability.free: 'Has free beds',
                      _Availability.full: 'Full',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: selection == entry.key,
                        onSelected: (_) => update(() {
                          selection = entry.key;
                          if (selection == _Availability.full) minimum = 0;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey(minimum),
                  initialValue: minimum,
                  decoration: const InputDecoration(
                    labelText: 'Minimum free beds',
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Any')),
                    for (var i = 1; i <= 6; i++)
                      DropdownMenuItem(value: i, child: Text('$i or more')),
                  ],
                  onChanged: (value) => update(() {
                    minimum = value ?? 0;
                    if (minimum > 0) selection = _Availability.free;
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => update(() {
                        selection = _Availability.all;
                        minimum = 0;
                      }),
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _availability = selection;
                          _minimumFreeBeds = minimum;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Apply filters'),
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
