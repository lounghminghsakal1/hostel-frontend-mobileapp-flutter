import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/media_download_url.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../model/attendance_records_model.dart';

Future<void> showPresentAttendanceDetails(
  BuildContext context,
  PresentAttendanceRecord record,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _PresentAttendanceSheet(record: record),
);

Future<void> showAbsentAttendanceDetails(
  BuildContext context,
  AbsentAttendanceRecord record,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (sheetContext) {
    final c =
        Theme.of(sheetContext).extension<HostelColors>() ?? HostelColors.light;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StudentAvatar(
                name: record.studentName,
                imageKey: record.studentImageKey,
                size: 54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.studentName,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        record.rollNumber,
                        record.roomNumber,
                        record.departmentName,
                      ].where((v) => v != null && v.isNotEmpty).join('  ·  '),
                      style: TextStyle(color: c.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${record.absentDates.length} missed ${record.absentDates.length == 1 ? 'day' : 'days'}',
            style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final date in record.absentDates)
                _AbsentDateChip(label: apiDateToDisplay(date), colors: c),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showAttendanceContactPicker(
              context,
              studentName: record.studentName,
              studentNumber: record.contactNumber,
              parentNumber: record.parentMobileNumber,
            ),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call student or parent'),
          ),
        ],
      ),
    );
  },
);

class AttendanceAbsentHomeItem extends ConsumerWidget {
  const AttendanceAbsentHomeItem({super.key, required this.record});
  final AbsentAttendanceRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final url =
        record.studentImageKey == null || record.studentImageKey!.isEmpty
        ? null
        : ref
              .watch(mediaDownloadUrlProvider(record.studentImageKey!))
              .valueOrNull;
    return Material(
      color: c.surfaceRaised,
      child: InkWell(
        onTap: () => showAbsentAttendanceDetails(context, record),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.surfaceSunken,
                backgroundImage: url == null ? null : NetworkImage(url),
                child: url == null
                    ? Text(
                        _initials(record.studentName),
                        style: TextStyle(
                          color: c.info,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          record.rollNumber,
                          style: TextStyle(color: c.inkMuted, fontSize: 11),
                        ),
                        if (record.roomNumber != null &&
                            record.roomNumber!.isNotEmpty)
                          _SmallTag(
                            label: record.roomNumber!,
                            background: c.surfaceSunken,
                            foreground: c.ink,
                          ),
                      ],
                    ),
                    if (record.absentDates.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          for (final date in record.absentDates.take(3))
                            _AbsentDateChip(
                              label: apiDateToDisplay(date),
                              colors: c,
                            ),
                          if (record.absentDates.length > 3)
                            Text(
                              '+${record.absentDates.length - 3}',
                              style: TextStyle(
                                color: c.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Call student or parent',
                onPressed: () => showAttendanceContactPicker(
                  context,
                  studentName: record.studentName,
                  studentNumber: record.contactNumber,
                  parentNumber: record.parentMobileNumber,
                ),
                icon: Icon(Icons.call_outlined, color: c.ink),
                style: IconButton.styleFrom(
                  side: BorderSide(color: c.lineStrong),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbsentDateChip extends StatelessWidget {
  const _AbsentDateChip({required this.label, required this.colors});
  final String label;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: colors.dangerSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: colors.danger,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.label,
    required this.background,
    required this.foreground,
  });
  final String label;
  final Color background, foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Future<void> showAttendanceContactPicker(
  BuildContext context, {
  required String studentName,
  required String? studentNumber,
  required String? parentNumber,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) {
    final c =
        Theme.of(dialogContext).extension<HostelColors>() ?? HostelColors.light;
    return AlertDialog(
      title: Text('Call $studentName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContactChoice(label: 'Student', number: studentNumber, colors: c),
          const SizedBox(height: 8),
          _ContactChoice(label: 'Parent', number: parentNumber, colors: c),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    );
  },
);

class _ContactChoice extends StatelessWidget {
  const _ContactChoice({
    required this.label,
    required this.number,
    required this.colors,
  });

  final String label;
  final String? number;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) {
    final value = number?.trim() ?? '';
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        title: Text(label),
        subtitle: Text(value.isEmpty ? 'Number unavailable' : value),
        trailing: IconButton(
          tooltip: 'Call $label',
          onPressed: value.isEmpty
              ? null
              : () => _confirmAndCall(context, label, value),
          icon: const Icon(Icons.call_outlined),
        ),
      ),
    );
  }
}

Future<void> _confirmAndCall(
  BuildContext context,
  String label,
  String number,
) async {
  if (number.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label phone number is unavailable')),
    );
    return;
  }
  final shouldCall = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Call $label?'),
      content: Text(number),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.call_rounded),
          label: const Text('Call'),
        ),
      ],
    ),
  );
  if (shouldCall != true) return;

  var opened = false;
  try {
    opened = await launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the phone app')),
    );
  }
}

class _PresentAttendanceSheet extends StatelessWidget {
  const _PresentAttendanceSheet({required this.record});

  final PresentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final match = record.faceMatchingPercentage;
    final date = record.attendanceDate == null
        ? 'Tonight'
        : apiDateToDisplay(record.attendanceDate!);
    final time = record.reportedTime == null
        ? ''
        : toDisplayTime(
            indiaWallTime(
              DateTime.tryParse(record.reportedTime!) ?? DateTime.now(),
            ),
          );
    final distance = record.locationDeviationFromHostel;
    final location = distance == null
        ? (record.isLocatedWithinHostelRadius
              ? 'At the hostel'
              : 'Location unavailable')
        : '${distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km'} from hostel';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.lineStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StudentAvatar(
                    name: record.studentName,
                    imageKey: record.studentImageKey,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.studentName,
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                                record.rollNumber,
                                record.roomNumber,
                                record.departmentName,
                              ]
                              .where(
                                (value) => value != null && value.isNotEmpty,
                              )
                              .join('  ·  '),
                          style: TextStyle(color: c.inkMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: c.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PhotoTile(
                      title: 'Profile photo',
                      imageKey: record.studentImageKey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhotoTile(
                      title: '$date${time.isEmpty ? '' : ' · $time'}',
                      imageKey: record.capturedImageKey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DetailLine(
                icon: Icons.face_retouching_natural_rounded,
                title:
                    'Face match ${match == null ? 'unavailable' : '${match.round()}%'}',
                subtitle: match != null && match < 80
                    ? 'Below your 80% check level'
                    : 'Attendance photo check',
                badge: match != null && match < 80 ? 'Low match' : null,
                colors: c,
              ),
              _DetailLine(
                icon: Icons.location_on_outlined,
                title: location,
                subtitle: record.isLocatedWithinHostelRadius
                    ? 'Within allowed radius'
                    : 'Allowed radius 800 m',
                trailing: record.mapUri == null
                    ? null
                    : IconButton(
                        tooltip: 'Open map',
                        onPressed: () => launchUrl(
                          record.mapUri!,
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      ),
                colors: c,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAndCall(
                        context,
                        'Student',
                        record.contactNumber ?? '',
                      ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call student'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAndCall(
                        context,
                        'Parent',
                        record.parentMobileNumber ?? '',
                      ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call parent'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.title, required this.imageKey});
  final String title;
  final String? imageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final url = imageKey == null || imageKey!.isEmpty
        ? null
        : ref.watch(mediaDownloadUrlProvider(imageKey!)).valueOrNull;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: c.surfaceSunken,
              child: url == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 90,
                      color: c.inkMuted.withValues(alpha: .65),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_rounded,
                        size: 90,
                        color: c.inkMuted,
                      ),
                    ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.ink, fontSize: 10.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.badge,
    this.trailing,
  });
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final Widget? trailing;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: colors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.warningSoft,
          child: Icon(icon, size: 19, color: colors.warning),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: colors.inkMuted, fontSize: 11.5),
              ),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.warningSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: colors.warning,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ?trailing,
      ],
    ),
  );
}

class _StudentAvatar extends ConsumerWidget {
  const _StudentAvatar({
    required this.name,
    required this.imageKey,
    required this.size,
  });
  final String name;
  final String? imageKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final url = imageKey == null || imageKey!.isEmpty
        ? null
        : ref.watch(mediaDownloadUrlProvider(imageKey!)).valueOrNull;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: c.infoSoft,
      backgroundImage: url == null ? null : NetworkImage(url),
      child: url == null
          ? Text(
              _initials(name),
              style: TextStyle(color: c.info, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty
      ? '?'
      : '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
            .toUpperCase();
}
