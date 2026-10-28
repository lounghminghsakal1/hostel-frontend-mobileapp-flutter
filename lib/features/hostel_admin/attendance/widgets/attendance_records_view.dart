import 'dart:async';
import 'dart:convert';

import '../../../../core/widgets/listing_filters.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../home/widgets/stat_card.dart';
import '../model/attendance_records_model.dart';
import '../providers/admin_attendance_providers.dart';
import 'attendance_tables.dart';
import 'attendance_record_item.dart';
import 'attendance_record_details_sheet.dart';

const _pageSize = 20;

/// Attendance records for the admin's hostel: present/absent toggle, date or
/// date-range filter, summary counts and a paginated table. Scrollable and
/// pull-to-refresh; [leading] widgets are shown above the filters.
class AttendanceRecordsView extends ConsumerStatefulWidget {
  const AttendanceRecordsView({super.key, this.isAdminHome = false});

  final bool isAdminHome;

  @override
  ConsumerState<AttendanceRecordsView> createState() =>
      _AttendanceRecordsViewState();
}

class _AttendanceRecordsViewState extends ConsumerState<AttendanceRecordsView> {
  AttendanceStatusFilter _status = AttendanceStatusFilter.present;

  /// Single-day filter; ignored while [_range] is set.
  DateTime _date = DateUtils.dateOnly(indiaWallTime(DateTime.now()));
  DateTimeRange? _range;
  int _page = 1;
  Map<String, String> _filters = {};
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _homeFilter = 'All';
  bool _filtersExpanded = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _filters = _withSearch(_filters, value);
        _page = 1;
      });
    });
  }

  Map<String, String> _withSearch(
    Map<String, String> filters, [
    String? searchText,
  ]) {
    final next = Map<String, String>.of(filters)
      ..remove('by_student_name')
      ..remove('by_roll_number');
    final value = (searchText ?? _searchController.text).trim();
    if (value.isNotEmpty) {
      final key = RegExp(r'^\d').hasMatch(value)
          ? 'by_roll_number'
          : 'by_student_name';
      next[key] = value;
    }
    return next;
  }

  AttendanceQuery get _query => (
    date: _range == null ? toIsoDate(_date) : null,
    fromDate: _range == null ? null : toIsoDate(_range!.start),
    toDate: _range == null ? null : toIsoDate(_range!.end),
    status: _status,
    page: _page,
    pageSize: _pageSize,
    filters: jsonEncode(
      Map.of(_filters)..removeWhere(
        (key, value) =>
            _status == AttendanceStatusFilter.absent &&
            (key == 'by_face_matching_percentage' ||
                key == 'face_matching_operator'),
      ),
    ),
  );

  String get _dateLabel {
    if (_range != null) {
      return '${toDisplayDate(_range!.start)} – ${toDisplayDate(_range!.end)}';
    }
    return DateUtils.isSameDay(_date, indiaWallTime(DateTime.now()))
        ? 'Today · ${toDisplayDate(_date)}'
        : toDisplayDate(_date);
  }

  Future<void> _chooseDateFilter() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.today_rounded, color: AppColors.navy),
              title: const Text('Today'),
              onTap: () => Navigator.of(context).pop('today'),
            ),
            ListTile(
              leading: const Icon(Icons.event_rounded, color: AppColors.navy),
              title: const Text('Pick a date'),
              onTap: () => Navigator.of(context).pop('date'),
            ),
            ListTile(
              leading: const Icon(
                Icons.date_range_rounded,
                color: AppColors.navy,
              ),
              title: const Text('Pick a date range'),
              onTap: () => Navigator.of(context).pop('range'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    final today = DateUtils.dateOnly(indiaWallTime(DateTime.now()));
    final firstDate = DateTime(today.year - 2);
    switch (choice) {
      case 'today':
        setState(() {
          _date = today;
          _range = null;
          _page = 1;
        });
      case 'date':
        final picked = await showDatePicker(
          context: context,
          initialDate: _range?.start ?? _date,
          firstDate: firstDate,
          lastDate: today,
        );
        if (picked != null) {
          setState(() {
            _date = picked;
            _range = null;
            _page = 1;
          });
        }
      case 'range':
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: _range ?? DateTimeRange(start: _date, end: _date),
          firstDate: firstDate,
          lastDate: today,
        );
        if (picked != null) {
          setState(() {
            _range = picked;
            _page = 1;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final resultAsync = ref.watch(attendanceRecordsProvider(query));
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final today =
        DateUtils.isSameDay(_date, indiaWallTime(DateTime.now())) &&
        _range == null;
    final date = _range == null
        ? (today ? 'Today' : _dateChipLabel(_date))
        : '${_range!.start.day} ${_month(_range!.start.month)} – ${_range!.end.day} ${_month(_range!.end.month)} · ${_range!.end.difference(_range!.start).inDays + 1} days';
    return RefreshIndicator(
      color: c.primary,
      onRefresh: () => ref.refresh(attendanceRecordsProvider(query).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, widget.isAdminHome ? 16 : 20, 16, 24),
        children: [
          if (widget.isAdminHome) ...[
            OutlinedButton.icon(
              onPressed: _chooseDateFilter,
              icon: Icon(Icons.calendar_today_outlined, size: 17, color: c.ink),
              label: Row(
                children: [
                  Expanded(
                    child: Text(
                      date,
                      style: TextStyle(color: c.ink, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: c.ink,
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: c.surfaceRaised,
                side: BorderSide(color: c.lineStrong),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...resultAsync.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(attendanceRecordsProvider(query)),
              ),
            ],
            data: (result) => widget.isAdminHome
                ? _homeContent(result, c)
                : _attendanceContent(result),
          ),
        ],
      ),
    );
  }

  List<Widget> _homeContent(AttendanceRecordsResult result, HostelColors c) {
    final summary = result.summary;
    final isAbsent = _status == AttendanceStatusFilter.absent;
    final rangeDays = _range == null
        ? 1
        : _range!.end.difference(_range!.start).inDays + 1;
    final absentCount =
        result.pagination.totalCount ?? result.absentRecords.length;
    final outsideCount = result.presentRecords
        .where((r) => !r.isLocatedWithinHostelRadius)
        .length;
    final lowMatchCount = result.presentRecords
        .where((r) => (r.faceMatchingPercentage ?? 100) < 80)
        .length;
    final shown = result.presentRecords.where((r) {
      if (_homeFilter == 'Outside radius') {
        return !r.isLocatedWithinHostelRadius;
      }
      if (_homeFilter == 'Low match') {
        return (r.faceMatchingPercentage ?? 100) < 80;
      }
      return true;
    }).toList();
    final shownAbsent = result.absentRecords.where((record) {
      if (_homeFilter != 'Missed every day') return true;
      return record.absentDates.length >= rangeDays;
    }).toList();
    return [
      _homeSummary(result, c),
      const SizedBox(height: 14),
      if (isAbsent && _range != null) ...[
        _rangeAbsenceNote(summary.absentCount, rangeDays, c),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _statusTab('Present', summary.presentCount, true, c),
            ),
            Expanded(child: _statusTab('Absent', absentCount, false, c)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Name or roll number',
                  prefixIcon: Icon(Icons.search, color: c.inkMuted, size: 21),
                  filled: true,
                  fillColor: c.surfaceRaised,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              onPressed: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              style: OutlinedButton.styleFrom(
                backgroundColor: c.surfaceRaised,
                padding: EdgeInsets.zero,
                side: BorderSide(
                  color: _filtersExpanded ? c.primary : c.lineStrong,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(Icons.tune_rounded, color: c.ink, size: 20),
            ),
          ),
        ],
      ),
      if (_filtersExpanded) ...[
        const SizedBox(height: 4),
        ListingFilters(
          fields: attendanceFilters,
          values: _filters,
          onChanged: (filters) => setState(() {
            _filters = _withSearch(filters);
            _page = 1;
          }),
        ),
      ],
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (isAbsent) ...[
              _filterPill('All', absentCount, c),
              const SizedBox(width: 8),
              _filterPill('Missed every day', summary.absentCount, c),
              const SizedBox(width: 8),
              _filterPill('Filters', null, c),
            ] else ...[
              _filterPill('All', null, c),
              const SizedBox(width: 8),
              _filterPill('Outside radius', outsideCount, c),
              const SizedBox(width: 8),
              _filterPill('Low match', lowMatchCount, c),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: !isAbsent
              ? shown.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(22),
                        child: Text(
                          'No matching attendance records',
                          style: TextStyle(color: c.inkMuted),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < shown.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: c.line),
                            AttendanceRecordItem(
                              key: ValueKey('${shown[i].rollNumber}-$i'),
                              record: shown[i],
                            ),
                          ],
                        ],
                      )
              : shownAbsent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    'No absent students for this date',
                    style: TextStyle(color: c.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < shownAbsent.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.line),
                      AttendanceAbsentHomeItem(
                        key: ValueKey('absent-${shownAbsent[i].rollNumber}'),
                        record: shownAbsent[i],
                      ),
                    ],
                  ],
                ),
        ),
      ),
      if (result.pagination.totalPages > 1) ...[
        const SizedBox(height: 12),
        _Pager(
          page: _page,
          totalPages: result.pagination.totalPages,
          onPageChanged: (page) => setState(() => _page = page),
        ),
      ],
    ];
  }

  Widget _homeSummary(AttendanceRecordsResult result, HostelColors c) {
    final values = [
      result.summary.totalStudents,
      result.summary.presentCount,
      result.summary.absentCount,
    ];
    final labels = [
      'Students',
      'Present',
      _range == null
          ? 'Absent'
          : 'Absent all ${_range!.end.difference(_range!.start).inDays + 1} days',
    ];
    final colors = [c.inkMuted, c.success, c.danger];
    final percentage = result.attendancePercentage;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : Border(left: BorderSide(color: c.line)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${values[i]}',
                            style: TextStyle(
                              color: c.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (i != 0)
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: colors[i],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (i != 0) const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  labels[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.inkMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 5,
                      backgroundColor: c.surfaceSunken,
                      color: c.success,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${percentage.round()}%',
                  style: TextStyle(color: c.inkMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeAbsenceNote(
    int fullyAbsent,
    int days,
    HostelColors c,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: c.surfaceRaised,
      border: Border.all(color: c.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: c.info, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '$fullyAbsent missed all $days days. The list shows everyone who missed at least one day.',
            style: TextStyle(color: c.inkMuted, fontSize: 11.5, height: 1.35),
          ),
        ),
      ],
    ),
  );

  Widget _statusTab(String label, int count, bool present, HostelColors c) {
    final selected = (_status == AttendanceStatusFilter.present) == present;
    return Material(
      color: selected ? c.brand : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() {
          _status = present
              ? AttendanceStatusFilter.present
              : AttendanceStatusFilter.absent;
          _homeFilter = 'All';
          _page = 1;
        }),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              '$label  $count',
              style: TextStyle(
                color: selected ? c.onBrand : c.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterPill(String label, int? count, HostelColors c) {
    final selected = _homeFilter == label;
    return InkWell(
      onTap: () => setState(() {
        if (label == 'Filters') {
          _filtersExpanded = !_filtersExpanded;
        } else {
          _homeFilter = label;
        }
      }),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.brand : c.surfaceRaised,
          border: selected ? null : Border.all(color: c.lineStrong),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          count == null ? label : '$label  $count',
          style: TextStyle(
            color: selected ? c.onBrand : c.ink,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Widget> _attendanceContent(AttendanceRecordsResult result) => [
    const Text(
      'Attendance Records',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 16),
    SegmentedButton<AttendanceStatusFilter>(
      segments: const [
        ButtonSegment(
          value: AttendanceStatusFilter.present,
          label: Text('Present'),
          icon: Icon(Icons.how_to_reg_rounded),
        ),
        ButtonSegment(
          value: AttendanceStatusFilter.absent,
          label: Text('Absent'),
          icon: Icon(Icons.person_off_outlined),
        ),
      ],
      selected: {_status},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => setState(() {
        _status = selection.first;
        _page = 1;
      }),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _chooseDateFilter,
      icon: const Icon(Icons.calendar_month_rounded, size: 18),
      label: Row(
        children: [
          Expanded(child: Text(_dateLabel, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.expand_more_rounded, size: 20),
        ],
      ),
    ),
    ListingFilters(
      fields: [
        ...attendanceFilters,
        if (_status == AttendanceStatusFilter.present) ...[
          const ListingFilter(
            'by_face_matching_percentage',
            'Face match threshold (%)',
            percentage: true,
          ),
          const ListingFilter(
            'face_matching_operator',
            'Threshold comparison',
            options: {'lte': 'At most (<=)', 'gte': 'At least (>=)'},
          ),
        ],
      ],
      onChanged: (filters) => setState(() {
        _filters = filters;
        _page = 1;
      }),
    ),
    const SizedBox(height: 18),
    ..._content(result),
  ];

  static String _shortDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  static String _dateChipLabel(DateTime date) => _shortDate(date);

  static String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  List<Widget> _content(AttendanceRecordsResult result) {
    final isRange = _range != null;
    final isAbsent = _status == AttendanceStatusFilter.absent;
    final isEmpty = isAbsent
        ? result.absentRecords.isEmpty
        : result.presentRecords.isEmpty;

    return [
      Row(
        children: [
          Expanded(
            child: StatCard(
              label: _filters.keys.any((key) => !key.contains('face_matching'))
                  ? 'Matching students'
                  : 'Total Students',
              value: '${result.summary.totalStudents}',
              icon: Icons.groups_2_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label:
                  (_status == AttendanceStatusFilter.present &&
                      _filters.containsKey('by_face_matching_percentage'))
                  ? 'Matching present'
                  : 'Marked Present',
              value: '${result.summary.presentCount}',
              icon: Icons.check_circle_outline_rounded,
              filled: true,
            ),
          ),
          if (!(_status == AttendanceStatusFilter.present &&
              _filters.containsKey('by_face_matching_percentage'))) ...[
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                // Over a range this counts students absent on every day.
                label: isRange ? 'Absent All Days' : 'Absent',
                value: '${result.summary.absentCount}',
                icon: Icons.person_off_outlined,
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      Text(
        isAbsent
            ? (isRange ? 'Students absent at least one day' : 'Absent students')
            : 'Attendance marked students',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.md),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: isEmpty
            ? AppEmptyState(
                key: ValueKey('empty-$isAbsent'),
                icon: isAbsent
                    ? Icons.person_off_outlined
                    : Icons.how_to_reg_rounded,
                title: isAbsent ? 'No absent students' : 'No attendance marked',
                message: isAbsent
                    ? 'No absent students for this period.'
                    : 'No attendance marked for this period.',
              )
            : Container(
                key: ValueKey('records-$isAbsent-$_page'),
                child: isAbsent
                    ? AbsentRecordsTable(records: result.absentRecords)
                    : PresentRecordsTable(
                        records: result.presentRecords,
                        showDate: isRange,
                      ),
              ),
      ),
      if (result.pagination.totalPages > 1) ...[
        const SizedBox(height: AppSpacing.md),
        _Pager(
          page: _page,
          totalPages: result.pagination.totalPages,
          onPageChanged: (page) => setState(() => _page = page),
        ),
      ],
    ];
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.navy,
        ),
        Expanded(
          child: Text(
            'Page $page of $totalPages',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navyAlpha(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.navy,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.navyAlpha(0.4),
            size: 40,
          ),
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
    );
  }
}
