import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../model/leave_application_model.dart';
import 'leave_status_chip.dart';

/// `3 Oct 2026` for a single day, `3 Oct – 5 Oct 2026` within a year.
String leaveDateRangeLabel(LeaveApplicationModel application) {
  final from = application.fromDate;
  final to = application.toDate;
  if (DateUtils.isSameDay(from, to)) return toDisplayDate(from);
  if (from.year == to.year) {
    final fromLabel = toDisplayDate(from);
    return '${fromLabel.substring(0, fromLabel.length - 5)} – ${toDisplayDate(to)}';
  }
  return '${toDisplayDate(from)} – ${toDisplayDate(to)}';
}

String leaveDaysLabel(LeaveApplicationModel application) =>
    application.days == 1 ? '1 day' : '${application.days} days';

/// One leave application in a list. With [showStudent] (admin), the
/// student's name and room lead the card. [actions] sit below a divider.
class LeaveApplicationCard extends StatelessWidget {
  const LeaveApplicationCard({
    super.key,
    required this.application,
    this.showStudent = false,
    this.onTap,
    this.actions = const [],
  });

  final LeaveApplicationModel application;
  final bool showStudent;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final rejectionReason = application.rejectionReason;
    final studentSubtitle = [
      if (application.rollNumber != null) application.rollNumber!,
      if (application.roomNumber != null) 'Room ${application.roomNumber}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: AppColors.navy, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showStudent
                                ? (application.studentName ?? 'Student')
                                : leaveDateRangeLabel(application),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            showStudent
                                ? [leaveDateRangeLabel(application), if (studentSubtitle.isNotEmpty) studentSubtitle]
                                    .join('\n')
                                : leaveDaysLabel(application),
                            style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LeaveStatusChip(status: application.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  application.leaveReason,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.navyAlpha(0.8), fontSize: 13, height: 1.4),
                ),
                if (rejectionReason != null && application.status == LeaveStatus.rejected) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navySoftAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Reason for rejection: $rejectionReason',
                      style: TextStyle(color: AppColors.navyAlpha(0.75), fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
                if (actions.isEmpty)
                  const SizedBox(height: 4)
                else ...[
                  const SizedBox(height: 6),
                  Divider(height: 1, color: AppColors.navyAlpha(0.08)),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
