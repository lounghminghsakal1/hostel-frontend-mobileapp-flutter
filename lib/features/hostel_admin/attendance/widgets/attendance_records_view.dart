import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../home/widgets/stat_card.dart';
import '../model/attendance_records_model.dart';
import '../providers/admin_attendance_providers.dart';
import 'attendance_tables.dart';

const _pageSize = 20;

/// Attendance records for the admin's hostel: present/absent toggle, date or
/// date-range filter, summary counts and a paginated table. Scrollable and
/// pull-to-refresh; [leading] widgets are shown above the filters.
class AttendanceRecordsView extends ConsumerStatefulWidget {
  const AttendanceRecordsView({super.key, this.leading = const []});

  final List<Widget> leading;

  @override
  ConsumerState<AttendanceRecordsView> createState() => _AttendanceRecordsViewState();
}

class _AttendanceRecordsViewState extends ConsumerState<AttendanceRecordsView> {
  AttendanceStatusFilter _status = AttendanceStatusFilter.present;

  /// Single-day filter; ignored while [_range] is set.
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  DateTimeRange? _range;
  int _page = 1;

  AttendanceQuery get _query => (
    date: _range == null ? toIsoDate(_date) : null,
    fromDate: _range == null ? null : toIsoDate(_range!.start),
    toDate: _range == null ? null : toIsoDate(_range!.end),
    status: _status,
    page: _page,
    pageSize: _pageSize,
  );

  String get _dateLabel {
    if (_range != null) return '${toDisplayDate(_range!.start)} – ${toDisplayDate(_range!.end)}';
    return DateUtils.isSameDay(_date, DateTime.now()) ? 'Today · ${toDisplayDate(_date)}' : toDisplayDate(_date);
  }

  Future<void> _chooseDateFilter() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              leading: const Icon(Icons.date_range_rounded, color: AppColors.navy),
              title: const Text('Pick a date range'),
              onTap: () => Navigator.of(context).pop('range'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    final today = DateUtils.dateOnly(DateTime.now());
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

    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: () => ref.refresh(attendanceRecordsProvider(query).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          ...widget.leading,
          const Text(
            'Attendance Records',
            style: TextStyle(color: AppColors.navy, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
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
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.navy,
              selectedForegroundColor: AppColors.white,
              foregroundColor: AppColors.navy,
            ),
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
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: BorderSide(color: AppColors.navyAlpha(0.18)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          ...resultAsync.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
              ),
            ],
            error: (error, _) => [
              _ErrorState(message: error.toString(), onRetry: () => ref.invalidate(attendanceRecordsProvider(query))),
            ],
            data: (result) => _content(result),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(AttendanceRecordsResult result) {
    final isRange = _range != null;
    final isAbsent = _status == AttendanceStatusFilter.absent;
    final isEmpty = isAbsent ? result.absentRecords.isEmpty : result.presentRecords.isEmpty;

    return [
      Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total Students',
              value: '${result.summary.totalStudents}',
              icon: Icons.groups_2_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Marked Present',
              value: '${result.summary.presentCount}',
              icon: Icons.check_circle_outline_rounded,
              filled: true,
            ),
          ),
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
      ),
      const SizedBox(height: 22),
      Text(
        isAbsent ? (isRange ? 'Students absent at least one day' : 'Absent students') : 'Attendance marked students',
        style: const TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      if (isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              isAbsent ? 'No absent students for this period' : 'No attendance marked for this period',
              style: TextStyle(color: AppColors.navyAlpha(0.5)),
            ),
          ),
        )
      else if (isAbsent)
        AbsentRecordsTable(records: result.absentRecords)
      else
        PresentRecordsTable(records: result.presentRecords, showDate: isRange),
      if (result.pagination.totalPages > 1) ...[
        const SizedBox(height: 14),
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
  const _Pager({required this.page, required this.totalPages, required this.onPageChanged});

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
            style: TextStyle(color: AppColors.navyAlpha(0.65), fontSize: 13, fontWeight: FontWeight.w600),
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
    );
  }
}
