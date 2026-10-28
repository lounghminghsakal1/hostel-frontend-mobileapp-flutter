import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/listing_api.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../model/student_model.dart';
import '../providers/students_providers.dart';
import '../widgets/student_avatar.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  CancelToken? _cancelToken;
  int _generation = 0;
  int _page = 1;
  ListingPage? _result;
  Object? _error;
  bool _loading = true;
  bool _floorThreeSelected = false;
  bool _noPhotoSelected = false;
  bool _activationPendingSelected = false;
  bool _showAdvancedFilters = false;
  Map<String, String> _filters = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _cancelToken?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> get _requestFilters {
    final filters = Map<String, String>.of(_filters);
    final search = _searchController.text.trim();
    filters.remove('by_student_name');
    filters.remove('by_roll_number');
    if (search.isNotEmpty) {
      filters[RegExp(r'^\d').hasMatch(search)
              ? 'by_roll_number'
              : 'by_student_name'] =
          search;
    }
    return filters;
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _page = 1;
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_generation;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ListingApi(ref.read(dioProvider)).fetch(
        ApiEndpoints.students,
        page: _page,
        filters: _requestFilters,
        cancelToken: _cancelToken,
      );
      if (!mounted || request != _generation) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<StudentModel> get _students =>
      (_result?.rows ?? const []).map(StudentModel.fromJson).toList();

  List<StudentModel> get _visibleStudents => _students.where((student) {
    if (_floorThreeSelected && _floorOf(student.roomNumber) != 3) return false;
    if (_noPhotoSelected && _hasPhoto(student)) return false;
    if (_activationPendingSelected && !_isActivationPending(student)) {
      return false;
    }
    return true;
  }).toList();

  int get _noPhotoCount =>
      _students.where((student) => !_hasPhoto(student)).length;
  int get _pendingCount => _students.where(_isActivationPending).length;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final visible = _visibleStudents;
    final totalCount = _result?.totalCount;
    final totalPages = _result?.totalPages ?? 1;
    final countLabel =
        totalCount ?? (totalPages == 1 ? _students.length : null);
    final countCaption = _requestFilters.isEmpty ? 'in hostel' : 'matching';
    final activeFilters =
        _filters.length +
        <bool>[
          _floorThreeSelected,
          _noPhotoSelected,
          _activationPendingSelected,
        ].where((active) => active).length;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Students',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              countLabel == null ? '' : '$countLabel $countCaption',
              style: TextStyle(color: c.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        icon: const Icon(Icons.add),
        label: const Text('Add student'),
        onPressed: () async {
          await context.push(AppRoutes.adminStudentCreate);
          ref.invalidate(studentsListProvider);
          _load();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Name or roll number',
                        prefixIcon: Icon(Icons.search, color: c.inkMuted),
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
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => setState(
                      () => _showAdvancedFilters = !_showAdvancedFilters,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: c.surfaceRaised,
                      side: BorderSide(
                        color: _showAdvancedFilters ? c.primary : c.lineStrong,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.tune_rounded, color: c.ink, size: 20),
                        if (activeFilters > 0)
                          Positioned(
                            top: -11,
                            right: -10,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: c.brand,
                              child: Text(
                                '$activeFilters',
                                style: TextStyle(
                                  color: c.onBrand,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showAdvancedFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListingFilters(
                fields: const [
                  ListingFilter(
                    'by_department_id',
                    'Department',
                    lookup: 'department',
                  ),
                  ListingFilter('by_room_id', 'Room', lookup: 'room'),
                ],
                values: _filters,
                onChanged: (filters) {
                  setState(() {
                    _filters = filters;
                    _page = 1;
                  });
                  _load();
                },
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _quickFilter(
                  label: 'Floor 3',
                  selected: _floorThreeSelected,
                  onTap: () => setState(
                    () => _floorThreeSelected = !_floorThreeSelected,
                  ),
                  colors: c,
                  clearable: _floorThreeSelected,
                ),
                const SizedBox(width: 8),
                _quickFilter(
                  label: 'No photo',
                  count: _noPhotoCount,
                  selected: _noPhotoSelected,
                  onTap: () =>
                      setState(() => _noPhotoSelected = !_noPhotoSelected),
                  colors: c,
                ),
                const SizedBox(width: 8),
                _quickFilter(
                  label: 'Activation pending',
                  count: _pendingCount,
                  selected: _activationPendingSelected,
                  onTap: () => setState(
                    () => _activationPendingSelected =
                        !_activationPendingSelected,
                  ),
                  colors: c,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _floorThreeSelected
                    ? '${visible.length} shown on floor 3'
                    : '${visible.length} shown on this page',
                style: TextStyle(color: c.inkMuted, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 150),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text('$_error', textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : visible.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Center(
                          child: Text(
                            'No students match these filters',
                            style: TextStyle(color: c.inkMuted),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: c.line, indent: 58),
                      itemBuilder: (context, index) => _StudentRow(
                        student: visible[index],
                        onTap: () async {
                          await context.push(
                            AppRoutes.adminStudentDetail(visible[index].id),
                          );
                          ref.invalidate(studentsListProvider);
                          _load();
                        },
                        colors: c,
                      ),
                    ),
            ),
          ),
          if (!_loading && _error == null && totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_page of $totalPages'),
                  IconButton(
                    onPressed: _page < totalPages
                        ? () {
                            setState(() => _page++);
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickFilter({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required HostelColors colors,
    int? count,
    bool clearable = false,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? colors.brand : colors.surfaceRaised,
        border: selected ? null : Border.all(color: colors.lineStrong),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count == null ? label : '$label  $count',
            style: TextStyle(
              color: selected ? colors.onBrand : colors.ink,
              fontSize: 12,
            ),
          ),
          if (clearable) ...[
            const SizedBox(width: 4),
            Icon(Icons.close_rounded, color: colors.onBrand, size: 15),
          ],
        ],
      ),
    ),
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.onTap,
    required this.colors,
  });

  final StudentModel student;
  final VoidCallback onTap;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) {
    final noPhoto = !_hasPhoto(student);
    final pending = _isActivationPending(student);
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              StudentAvatar(student: student, size: 44, circular: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          student.rollNumber,
                          style: TextStyle(
                            color: colors.inkMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (student.roomNumber?.isNotEmpty == true)
                          _RoomTag(room: student.roomNumber!, colors: colors),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (noPhoto)
                _StatusTag(
                  label: 'No photo',
                  icon: Icons.photo_camera_outlined,
                  background: colors.warningSoft,
                  foreground: colors.warning,
                )
              else if (pending)
                _StatusTag(
                  label: 'Activation pending',
                  icon: Icons.mail_outline_rounded,
                  background: colors.infoSoft,
                  foreground: colors.info,
                )
              else
                Icon(Icons.chevron_right_rounded, color: colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomTag extends StatelessWidget {
  const _RoomTag({required this.room, required this.colors});
  final String room;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: colors.surfaceSunken,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(room, style: TextStyle(color: colors.ink, fontSize: 10.5)),
  );
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
  final String label;
  final IconData icon;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: foreground),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

bool _hasPhoto(StudentModel student) =>
    (student.studentImageUrl?.trim().isNotEmpty ?? false) ||
    (student.studentImageKey?.trim().isNotEmpty ?? false);

bool _isActivationPending(StudentModel student) =>
    switch (student.status?.toUpperCase()) {
      'PENDING' || 'ACTIVATION_PENDING' || 'WAITING_FOR_ACTIVATION' => true,
      _ => false,
    };

int? _floorOf(String? roomNumber) {
  final match = RegExp(r'-(\d+)-').firstMatch(roomNumber ?? '');
  return match == null ? null : int.tryParse(match.group(1)!);
}
