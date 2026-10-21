import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
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
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: AppColors.navy, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showStudent
                                ? (application.studentName ?? 'Student')
                                : leaveDateRangeLabel(application),
                            style: textTheme.titleMedium?.copyWith(fontSize: 14.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            showStudent
                                ? [leaveDateRangeLabel(application), if (studentSubtitle.isNotEmpty) studentSubtitle]
                                    .join('\n')
                                : leaveDaysLabel(application),
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    LeaveStatusChip(status: application.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  application.leaveReason,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                if (rejectionReason != null && application.status == LeaveStatus.rejected) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Reason for rejection: $rejectionReason',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
                if (actions.isEmpty)
                  const SizedBox(height: AppSpacing.xs)
                else ...[
                  const SizedBox(height: AppSpacing.sm),
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
