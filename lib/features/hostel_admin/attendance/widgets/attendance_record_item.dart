import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_download_url.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../model/attendance_records_model.dart';
import 'attendance_record_details_sheet.dart';

/// Compact attendance row. The captured check-in image leads, matching the
/// identity verification that the administrator is reviewing.
class AttendanceRecordItem extends ConsumerWidget {
  const AttendanceRecordItem({super.key, required this.record});
  final PresentAttendanceRecord record;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final local = record.reportedTime == null
        ? null
        : DateTime.tryParse(record.reportedTime!);
    final time = local == null ? '—' : toDisplayTime(indiaWallTime(local));
    final percent = record.faceMatchingPercentage;
    final matchColor = percent == null
        ? c.inkMuted
        : percent < 80
        ? c.warning
        : c.success;
    final distance = record.locationDeviationFromHostel;
    final match = percent == null ? null : '${percent.round()}%';
    final image = record.capturedImageKey;
    final url = image == null || image.isEmpty
        ? null
        : ref.watch(mediaDownloadUrlProvider(image)).valueOrNull;
    return Material(
      color: c.surfaceRaised,
      child: InkWell(
        onTap: () => showPresentAttendanceDetails(context, record),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: c.infoSoft,
                backgroundImage: url == null ? null : NetworkImage(url),
                onBackgroundImageError: url == null ? null : (_, _) {},
                child: url == null
                    ? Text(
                        _initials(record.studentName),
                        style: TextStyle(
                          color: c.info,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          _label(record.roomNumber!, c.surfaceSunken, c.ink),
                      ],
                    ),
                    if (!record.isLocatedWithinHostelRadius) ...[
                      const SizedBox(height: 5),
                      _label(
                        distance == null
                            ? 'Outside radius'
                            : '${distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km'} away',
                        c.warningSoft,
                        c.warning,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (match != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 38,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (percent! / 100).clamp(0, 1),
                          minHeight: 3,
                          backgroundColor: c.line,
                          color: matchColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match,
                      style: TextStyle(
                        color: matchColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty
        ? '?'
        : '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
              .toUpperCase();
  }

  static Widget _label(
    String text,
    Color background,
    Color foreground, {
    IconData? icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
