import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';

class AdminLeaveRequestDetails extends StatelessWidget {
  const AdminLeaveRequestDetails({super.key, required this.application});

  final LeaveApplicationModel application;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final student = application.student;
    final studentName =
        application.studentName ?? student?.studentName ?? 'Student';
    final rollNumber = application.rollNumber ?? student?.rollNumber ?? '';
    final roomNumber = application.roomNumber ?? student?.roomNumber;
    final departmentName =
        application.departmentName ?? student?.departmentName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _StudentCard(
          name: studentName,
          rollNumber: rollNumber,
          roomNumber: roomNumber,
          departmentName: departmentName,
          studentNumber: application.contactNumber ?? student?.contactNumber,
          parentNumber:
              application.parentMobileNumber ?? student?.parentMobileNumber,
          colors: c,
        ),
        const SizedBox(height: 14),
        _LeaveDetailsCard(application: application, colors: c),
        const SizedBox(height: 12),
        Text(
          'Earlier this term',
          style: TextStyle(
            color: c.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.name,
    required this.rollNumber,
    required this.roomNumber,
    required this.departmentName,
    required this.studentNumber,
    required this.parentNumber,
    required this.colors,
  });

  final String name;
  final String rollNumber;
  final String? roomNumber, departmentName, studentNumber, parentNumber;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => _CardShell(
    colors: colors,
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.marigoldSoft,
              child: Text(
                _initials(name),
                style: TextStyle(
                  color: colors.marigoldInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (rollNumber.isNotEmpty)
                        Text(
                          rollNumber,
                          style: TextStyle(
                            color: colors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      if (roomNumber?.isNotEmpty == true)
                        _Tag(label: roomNumber!, colors: colors),
                    ],
                  ),
                  if (departmentName?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      departmentName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.inkMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CallButton(
                label: 'Call student',
                number: studentNumber,
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CallButton(
                label: 'Call parent',
                number: parentNumber,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LeaveDetailsCard extends StatelessWidget {
  const _LeaveDetailsCard({required this.application, required this.colors});

  final LeaveApplicationModel application;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => _CardShell(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateColumn(
                label: 'From',
                value: _date(application.fromDate),
                colors: colors,
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: colors.inkMuted, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: _DateColumn(
                label: 'To',
                value: _date(application.toDate),
                colors: colors,
              ),
            ),
            const SizedBox(width: 6),
            _Tag(label: _daysLabel(application), colors: colors),
          ],
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: colors.line),
        const SizedBox(height: 14),
        Text('Reason', style: TextStyle(color: colors.inkMuted, fontSize: 12)),
        const SizedBox(height: 7),
        Text(
          application.leaveReason,
          style: TextStyle(color: colors.ink, fontSize: 14, height: 1.5),
        ),
        if (application.createdAt != null) ...[
          const SizedBox(height: 14),
          Text(
            'Applied ${_appliedAt(application.createdAt!)}',
            style: TextStyle(color: colors.inkMuted, fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({
    required this.label,
    required this.value,
    required this.colors,
  });
  final String label, value;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: colors.inkMuted, fontSize: 12)),
      const SizedBox(height: 6),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.number,
    required this.colors,
  });
  final String label;
  final String? number;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: number?.trim().isNotEmpty == true
        ? () => _confirmCall(context, label, number!.trim())
        : null,
    icon: const Icon(Icons.call_outlined, size: 18),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: colors.ink,
      side: BorderSide(color: colors.lineStrong),
      minimumSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

Future<void> _confirmCall(
  BuildContext context,
  String label,
  String number,
) async {
  final call = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$label?'),
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
  if (call != true) return;
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

class _CardShell extends StatelessWidget {
  const _CardShell({required this.colors, required this.child});
  final HostelColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.surfaceRaised,
      border: Border.all(color: colors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.colors});
  final String label;
  final HostelColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: colors.surfaceSunken,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: colors.ink,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _date(DateTime value) {
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
  return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]}';
}

String _daysLabel(LeaveApplicationModel application) =>
    application.days == 1 ? '1 day' : '${application.days} days';

String _appliedAt(DateTime instant) {
  final wallTime = indiaWallTime(instant);
  return '${_date(wallTime)} · ${toDisplayTime(wallTime)}';
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
