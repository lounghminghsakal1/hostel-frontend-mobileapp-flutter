import '../../../../core/widgets/student_business_details.dart';
import '../../students/model/student_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/media_download_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../model/attendance_records_model.dart';

/// Absent dates beyond this many collapse into a "+N more" popup.
const _maxInlineAbsentDates = 2;

/// Present/absent attendance records, as a scannable card-per-record list —
/// a horizontally scrolling table reads poorly at phone width once there are
/// this many columns (name, roll no, room, image, face match, location).
class PresentRecordsTable extends StatelessWidget {
  const PresentRecordsTable({
    super.key,
    required this.records,
    required this.showDate,
  });

  final List<PresentAttendanceRecord> records;

  /// Show a date row, for range filters where a student can appear once per day.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in records) ...[
          _PresentRecordCard(record: r, showDate: showDate),
          if (r != records.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class AbsentRecordsTable extends StatelessWidget {
  const AbsentRecordsTable({super.key, required this.records});

  final List<AbsentAttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in records) ...[
          _AbsentRecordCard(key: ValueKey(r.rollNumber), record: r),
          if (r != records.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Shared card shell: white surface, soft navy border, generous padding.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: child,
    );
  }
}

/// Soft-tinted status pill — same pattern as [LeaveStatusChip]: tinted
/// background, solid icon/text, pill shape, no border.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.positive,
  });

  final String label;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final background = positive ? AppColors.successSoft : AppColors.errorSoft;
    final foreground = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Name + roll no. + room header row, shared by both card kinds.
class _RecordHeader extends StatelessWidget {
  const _RecordHeader({
    required this.studentName,
    required this.rollNumber,
    required this.roomNumber,
    this.trailing,
  });

  final String studentName;
  final String rollNumber;
  final String? roomNumber;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                roomNumber == null
                    ? 'Roll no. $rollNumber'
                    : 'Roll no. $rollNumber · Room $roomNumber',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.navyAlpha(0.6),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class _PresentRecordCard extends StatelessWidget {
  const _PresentRecordCard({required this.record, required this.showDate});

  final PresentAttendanceRecord record;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final within = record.isLocatedWithinHostelRadius;

    return _RecordCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentBusinessDetails(
            student: StudentModel(
              id: 0,
              studentName: record.studentName,
              email: '',
              rollNumber: record.rollNumber,
              contactNumber: record.contactNumber ?? '',
              parentMobileNumber: record.parentMobileNumber ?? '',
              departmentId: null,
              departmentName: record.departmentName,
              roomNumber: record.roomNumber,
              studentImageKey: record.studentImageKey,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Captured attendance photo'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CapturedImageThumbnail(
                imageKey: record.capturedImageKey,
                studentName: record.studentName,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _RecordHeader(
                  studentName: record.studentName,
                  rollNumber: record.rollNumber,
                  roomNumber: record.roomNumber,
                  trailing: const _StatusPill(
                    label: 'Present',
                    icon: Icons.check_circle_rounded,
                    positive: true,
                  ),
                ),
              ),
            ],
          ),
          if (record.attendanceDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              apiDateToDisplay(record.attendanceDate!),
              style: TextStyle(
                color: AppColors.navyAlpha(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Text('Reported at: ${instantToDisplay(record.reportedTime)}'),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FaceMatchBadge(percentage: record.faceMatchingPercentage),
              _StatusPill(
                label: _deviationLabel(record),
                icon: within
                    ? Icons.my_location_rounded
                    : Icons.warning_amber_rounded,
                positive: within,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MapLinkButton(uri: record.mapUri),
        ],
      ),
    );
  }

  static String _deviationLabel(PresentAttendanceRecord record) {
    final deviation = record.locationDeviationFromHostel;
    if (deviation == null) {
      return record.isLocatedWithinHostelRadius
          ? 'Within radius'
          : 'Outside radius';
    }
    final distance = '${deviation.toStringAsFixed(1)} m';
    return record.isLocatedWithinHostelRadius
        ? 'Within radius · $distance'
        : 'Outside radius · $distance';
  }
}

class _AbsentRecordCard extends StatelessWidget {
  const _AbsentRecordCard({super.key, required this.record});

  final AbsentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return _RecordCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentBusinessDetails(
            student: StudentModel(
              id: 0,
              studentName: record.studentName,
              email: '',
              rollNumber: record.rollNumber,
              contactNumber: record.contactNumber ?? '',
              parentMobileNumber: record.parentMobileNumber ?? '',
              departmentId: null,
              departmentName: record.departmentName,
              roomNumber: record.roomNumber,
              studentImageKey: record.studentImageKey,
            ),
          ),
          _RecordHeader(
            studentName: record.studentName,
            rollNumber: record.rollNumber,
            roomNumber: record.roomNumber,
            trailing: const _StatusPill(
              label: 'Absent',
              icon: Icons.person_off_rounded,
              positive: false,
            ),
          ),
          if (record.departmentName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              record.departmentName!,
              style: TextStyle(
                color: AppColors.navyAlpha(0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Text('${record.absentDates.length} missed dates'),
          _AbsentDatesCell(record: record),
        ],
      ),
    );
  }
}

/// Small rounded thumbnail of the captured attendance photo; fetches its
/// presigned url lazily and shows a loading/error placeholder meanwhile. Tap
/// opens the full-size image.
class _CapturedImageThumbnail extends ConsumerWidget {
  const _CapturedImageThumbnail({
    required this.imageKey,
    required this.studentName,
  });

  final String? imageKey;
  final String studentName;

  static const double _size = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(AppRadius.sm);
    final key = imageKey;

    Widget placeholder(IconData icon) => Container(
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: radius,
      ),
      child: Icon(icon, color: AppColors.navyAlpha(0.35), size: 20),
    );

    if (key == null || key.isEmpty) {
      return SizedBox(
        width: _size,
        height: _size,
        child: Tooltip(
          message: 'No image captured',
          child: placeholder(Icons.no_photography_outlined),
        ),
      );
    }

    final urlAsync = ref.watch(mediaDownloadUrlProvider(key));

    return SizedBox(
      width: _size,
      height: _size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) =>
                _CapturedImageDialog(imageKey: key, studentName: studentName),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: urlAsync.when(
              loading: () => Container(
                color: AppColors.navySoft,
                child: const Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
              error: (_, _) => placeholder(Icons.broken_image_outlined),
              data: (url) => Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppColors.navySoft,
                        child: const Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                errorBuilder: (_, _, _) =>
                    placeholder(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Requests the presigned download url when opened, then shows the image.
class _CapturedImageDialog extends ConsumerWidget {
  const _CapturedImageDialog({
    required this.imageKey,
    required this.studentName,
  });

  final String imageKey;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() => ref.invalidate(mediaDownloadUrlProvider(imageKey));

    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: AppColors.navy),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: ref
                .watch(mediaDownloadUrlProvider(imageKey))
                .when(
                  loading: _loading,
                  error: (error, _) => _message(error.toString(), retry),
                  data: (url) => Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _loading(),
                    errorBuilder: (_, _, _) =>
                        _message('Could not load the image', retry),
                  ),
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

  Widget _message(String text, VoidCallback onRetry) => SizedBox(
    height: 240,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: AppColors.navyAlpha(0.4),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navyAlpha(0.6)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}

class _FaceMatchBadge extends StatelessWidget {
  const _FaceMatchBadge({required this.percentage});

  final double? percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.face_retouching_natural_rounded,
          size: 16,
          color: AppColors.navyAlpha(0.55),
        ),
        const SizedBox(width: 5),
        Text(
          percentage == null
              ? 'Face match —'
              : 'Face match ${percentage!.toStringAsFixed(1)}%',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MapLinkButton extends StatelessWidget {
  const _MapLinkButton({required this.uri});

  final Uri? uri;

  @override
  Widget build(BuildContext context) {
    if (uri == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 16,
            color: AppColors.navyAlpha(0.35),
          ),
          const SizedBox(width: 5),
          Text(
            'No location data',
            style: TextStyle(color: AppColors.navyAlpha(0.45), fontSize: 12.5),
          ),
        ],
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () async {
          bool opened;
          try {
            opened = await launchUrl(
              uri!,
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {
            opened = false;
          }
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open maps'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.brassDeep,
              ),
              const SizedBox(width: 5),
              Text(
                'View on map',
                style: TextStyle(
                  color: AppColors.brassDeep,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.brassDeep.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
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

    final inline = dates.take(_maxInlineAbsentDates).toList();
    final overflow = dates.length - inline.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final d in inline) _AbsentDateChip(label: d),
        if (overflow > 0)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  '${record.studentName} · ${dates.length} days absent',
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dates.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.event_busy_rounded,
                        color: AppColors.navyAlpha(0.5),
                        size: 20,
                      ),
                      title: Text(
                        dates[i],
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: Text('+$overflow more'),
          ),
      ],
    );
  }
}

class _AbsentDateChip extends StatelessWidget {
  const _AbsentDateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 13, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
