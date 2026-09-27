import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../model/attendance_records_model.dart';
import '../providers/admin_attendance_providers.dart';

/// Absent dates beyond this many collapse into a "+N more" popup.
const _maxInlineAbsentDates = 2;

const _headerStyle = TextStyle(color: AppColors.navy, fontSize: 12.5, fontWeight: FontWeight.w700);
const _cellStyle = TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w500);

/// Horizontally scrollable table shell shared by both record tables.
class _RecordsTable extends StatelessWidget {
  const _RecordsTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(AppColors.navySoft),
          headingTextStyle: _headerStyle,
          dataTextStyle: _cellStyle,
          columnSpacing: 22,
          horizontalMargin: 16,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          columns: [for (final c in columns) DataColumn(label: Text(c))],
          rows: rows,
        ),
      ),
    );
  }
}

class PresentRecordsTable extends StatelessWidget {
  const PresentRecordsTable({super.key, required this.records, required this.showDate});

  final List<PresentAttendanceRecord> records;

  /// Show a date column, for range filters where a student can appear once per day.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return _RecordsTable(
      columns: [
        'Student name',
        'Roll no.',
        'Room',
        if (showDate) 'Date',
        'Captured image',
        'Face match',
        'Distance from hostel',
        'Location',
      ],
      rows: [
        for (final r in records)
          DataRow(cells: [
            DataCell(Text(r.studentName)),
            DataCell(Text(r.rollNumber)),
            DataCell(Text(r.roomNumber ?? '—')),
            if (showDate) DataCell(Text(r.attendanceDate == null ? '—' : apiDateToDisplay(r.attendanceDate!))),
            DataCell(_CapturedImageButton(imageKey: r.capturedImageKey, studentName: r.studentName)),
            DataCell(Text(r.faceMatchingPercentage == null ? '—' : '${r.faceMatchingPercentage!.toStringAsFixed(1)}%')),
            DataCell(_DeviationText(record: r)),
            DataCell(_MapLinkButton(uri: r.mapUri)),
          ]),
      ],
    );
  }
}

class AbsentRecordsTable extends StatelessWidget {
  const AbsentRecordsTable({super.key, required this.records});

  final List<AbsentAttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return _RecordsTable(
      columns: const ['Student name', 'Roll no.', 'Room', 'Department', 'Absent dates'],
      rows: [
        for (final r in records)
          DataRow(cells: [
            DataCell(Text(r.studentName)),
            DataCell(Text(r.rollNumber)),
            DataCell(Text(r.roomNumber ?? '—')),
            DataCell(Text(r.departmentName ?? '—')),
            DataCell(_AbsentDatesCell(record: r)),
          ]),
      ],
    );
  }
}

class _CapturedImageButton extends StatelessWidget {
  const _CapturedImageButton({required this.imageKey, required this.studentName});

  final String? imageKey;
  final String studentName;

  @override
  Widget build(BuildContext context) {
    if (imageKey == null || imageKey!.isEmpty) {
      return Tooltip(
        message: 'No image captured',
        child: Icon(Icons.visibility_off_outlined, color: AppColors.navyAlpha(0.3), size: 20),
      );
    }
    return IconButton(
      tooltip: 'View captured image',
      icon: const Icon(Icons.visibility_outlined, color: AppColors.navy, size: 22),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _CapturedImageDialog(imageKey: imageKey!, studentName: studentName),
      ),
    );
  }
}

/// Requests the presigned download url when opened, then shows the image.
class _CapturedImageDialog extends ConsumerStatefulWidget {
  const _CapturedImageDialog({required this.imageKey, required this.studentName});

  final String imageKey;
  final String studentName;

  @override
  ConsumerState<_CapturedImageDialog> createState() => _CapturedImageDialogState();
}

class _CapturedImageDialogState extends ConsumerState<_CapturedImageDialog> {
  late Future<String> _urlFuture = _fetchUrl();

  Future<String> _fetchUrl() =>
      ref.read(adminAttendanceRepositoryProvider).getAttendanceImageDownloadUrl(widget.imageKey);

  void _retry() => setState(() => _urlFuture = _fetchUrl());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 6, 8),
            child: Row(
              children: [
                Expanded(child: Text(widget.studentName, style: _headerStyle.copyWith(fontSize: 15))),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: AppColors.navy),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: FutureBuilder<String>(
              future: _urlFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _message(snapshot.error.toString());
                if (!snapshot.hasData) return _loading();
                return Image.network(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null ? child : _loading(),
                  errorBuilder: (_, _, _) => _message('Could not load the image'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );

  Widget _message(String text) => SizedBox(
        height: 240,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, color: AppColors.navyAlpha(0.4), size: 36),
                const SizedBox(height: 10),
                Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.navyAlpha(0.6))),
                const SizedBox(height: 8),
                TextButton(onPressed: _retry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
}

class _DeviationText extends StatelessWidget {
  const _DeviationText({required this.record});

  final PresentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final deviation = record.locationDeviationFromHostel;
    final within = record.isLocatedWithinHostelRadius;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          within ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          size: 16,
          color: within ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
        const SizedBox(width: 6),
        Text(deviation == null ? (within ? 'Within radius' : '—') : _formatDistance(deviation)),
      ],
    );
  }

  static String _formatDistance(double metres) =>
      metres >= 1000 ? '${(metres / 1000).toStringAsFixed(2)} km' : '${metres.round()} m';
}

class _MapLinkButton extends StatelessWidget {
  const _MapLinkButton({required this.uri});

  final Uri? uri;

  @override
  Widget build(BuildContext context) {
    if (uri == null) return const Text('—');
    return TextButton.icon(
      onPressed: () async {
        bool opened;
        try {
          opened = await launchUrl(uri!, mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false;
        }
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps'), behavior: SnackBarBehavior.floating),
          );
        }
      },
      icon: const Icon(Icons.map_outlined, size: 18),
      label: const Text('View on map'),
    );
  }
}

class _AbsentDatesCell extends StatelessWidget {
  const _AbsentDatesCell({required this.record});

  final AbsentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final dates = record.absentDates.map(apiDateToDisplay).toList();
    if (dates.isEmpty) return const Text('—');
    if (dates.length <= _maxInlineAbsentDates) return Text(dates.join(', '));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(dates.take(_maxInlineAbsentDates).join(', ')),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('${record.studentName} · ${dates.length} days absent'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dates.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: Icon(Icons.event_busy_rounded, color: AppColors.navyAlpha(0.5), size: 20),
                    title: Text(dates[i], style: _cellStyle),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ],
            ),
          ),
          child: Text('+${dates.length - _maxInlineAbsentDates} more'),
        ),
      ],
    );
  }
}
