import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../model/leave_application_model.dart';
import 'leave_application_card.dart';
import 'leave_status_chip.dart';

/// Scrollable full details of one application. With [showStudent] (admin),
/// the header names the student; otherwise it leads with the dates.
class LeaveApplicationDetails extends StatelessWidget {
  const LeaveApplicationDetails({super.key, required this.application, this.showStudent = false});

  final LeaveApplicationModel application;
  final bool showStudent;

  @override
  Widget build(BuildContext context) {
    final createdAt = application.createdAt;
    final reviewedAt = application.reviewedAt;
    final rejectionReason = application.rejectionReason;
    final studentSubtitle = [
      if (application.rollNumber != null) application.rollNumber!,
      if (application.roomNumber != null) 'Room ${application.roomNumber}',
    ].join(' · ');

    final title = showStudent ? (application.studentName ?? 'Student') : leaveDateRangeLabel(application);
    final subtitle = showStudent ? studentSubtitle : leaveDaysLabel(application);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  showStudent ? Icons.person_outline_rounded : Icons.event_note_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppColors.navyAlpha(0.6), fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              LeaveStatusChip(status: application.status),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (showStudent)
          _DetailRow(
            icon: Icons.date_range_rounded,
            label: 'Leave dates',
            value: '${leaveDateRangeLabel(application)} · ${leaveDaysLabel(application)}',
          ),
        if (createdAt != null)
          _DetailRow(
            icon: Icons.send_outlined,
            label: 'Applied on',
            value: toDisplayDate(createdAt),
          ),
        if (reviewedAt != null)
          _DetailRow(
            icon: Icons.fact_check_outlined,
            label: 'Reviewed on',
            value: toDisplayDate(reviewedAt),
          ),
        _DetailRow(
          icon: Icons.notes_rounded,
          label: 'Reason',
          value: application.leaveReason,
        ),
        if (rejectionReason != null && application.status == LeaveStatus.rejected)
          _DetailRow(
            icon: Icons.cancel_outlined,
            label: 'Reason for rejection',
            value: rejectionReason,
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.navyAlpha(0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.navy, fontSize: 14.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
