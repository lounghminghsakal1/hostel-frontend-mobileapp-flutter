import '../../../../core/widgets/student_business_details.dart';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../model/leave_application_model.dart';
import 'leave_application_card.dart';
import 'leave_status_chip.dart';

/// Scrollable full details of one application. With [showStudent] (admin),
/// the header names the student; otherwise it leads with the dates.
class LeaveApplicationDetails extends StatelessWidget {
  const LeaveApplicationDetails({
    super.key,
    required this.application,
    this.showStudent = false,
  });

  final LeaveApplicationModel application;
  final bool showStudent;

  @override
  Widget build(BuildContext context) {
    final reviewedAt = application.reviewedAt;
    final rejectionReason = application.rejectionReason;
    final studentSubtitle = [
      if (application.rollNumber != null) application.rollNumber!,
      if (application.roomNumber != null) 'Room ${application.roomNumber}',
    ].join(' · ');

    final title = showStudent
        ? (application.studentName ?? 'Student')
        : leaveDateRangeLabel(application);
    final subtitle = showStudent
        ? studentSubtitle
        : leaveDaysLabel(application);

    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  showStudent
                      ? Icons.person_outline_rounded
                      : Icons.event_note_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(fontSize: 16),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle, style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              LeaveStatusChip(status: application.status),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (showStudent)
          _DetailRow(
            icon: Icons.date_range_rounded,
            label: 'Leave dates',
            value:
                '${leaveDateRangeLabel(application)} · ${leaveDaysLabel(application)}',
          ),
        if (showStudent && application.student != null)
          StudentBusinessDetails(student: application.student!),
        _DetailRow(
          icon: Icons.fact_check_outlined,
          label: 'Reviewed at',
          value: reviewedAt == null
              ? '\u2014'
              : instantToDisplay(reviewedAt.toIso8601String()),
        ),
        _DetailRow(
          icon: Icons.notes_rounded,
          label: 'Reason',
          value: application.leaveReason,
        ),
        if (rejectionReason != null &&
            application.status == LeaveStatus.rejected)
          _DetailRow(
            icon: Icons.cancel_outlined,
            label: 'Reason for rejection',
            value: rejectionReason,
            isNegative: true,
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// True for the rejection reason — tinted to read as the status it explains.
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = isNegative ? AppColors.error : AppColors.navyAlpha(0.5);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: isNegative ? AppColors.error : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  color: isNegative ? AppColors.error : AppColors.navy,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!isNegative) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: content,
      ),
    );
  }
}
