import 'package:flutter/material.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/widgets/leave_status_chip.dart';

String studentLeaveDateRangeLabel(DateTime from, DateTime to) {
  if (DateUtils.isSameDay(from, to)) return toDisplayDate(from);
  if (from.year == to.year && from.month == to.month) {
    return '${from.day} \u2013 ${toDisplayDate(to)}';
  }
  if (from.year == to.year) {
    final label = toDisplayDate(from);
    return '${label.substring(0, label.length - 5)} \u2013 ${toDisplayDate(to)}';
  }
  return '${toDisplayDate(from)} \u2013 ${toDisplayDate(to)}';
}

String leaveWeekday(DateTime date) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

class StudentLeaveCard extends StatelessWidget {
  const StudentLeaveCard({
    super.key,
    required this.application,
    this.onTap,
    this.actions = const [],
  });
  final LeaveApplicationModel application;
  final VoidCallback? onTap;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final a = application;
    return Material(
      color: c.surfaceRaised,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          size: 21,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentLeaveDateRangeLabel(a.fromDate, a.toDate),
                              style: TextStyle(
                                color: c.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${leaveWeekday(a.fromDate)} to ${leaveWeekday(a.toDate)} \u00b7 ${a.days} ${a.days == 1 ? 'day' : 'days'}',
                              style: TextStyle(
                                color: c.inkMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            if (compact)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: LeaveStatusChip(status: a.status),
                              ),
                          ],
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        LeaveStatusChip(status: a.status),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                a.leaveReason,
                style: TextStyle(color: c.inkMuted, fontSize: 13, height: 1.5),
              ),
              if (a.status == LeaveStatus.rejected &&
                  a.rejectionReason != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.dangerSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note from hostel admin',
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.rejectionReason!,
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
