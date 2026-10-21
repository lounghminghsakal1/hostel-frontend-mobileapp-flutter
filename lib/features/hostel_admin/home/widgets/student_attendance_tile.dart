import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../model/marked_student_model.dart';

/// A single student's entry in an attendance-marking list. Always reflects
/// a present mark (the face-match badge only appears once attendance is
/// recorded), so the status pill uses the success/register colors.
class StudentAttendanceTile extends StatelessWidget {
  const StudentAttendanceTile({super.key, required this.student});

  final MarkedStudentModel student;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              student.initials,
              style: textTheme.titleMedium?.copyWith(color: AppColors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: textTheme.titleMedium?.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  'Roll ${student.rollNumber} · Room ${student.roomNumber}',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm - 2),
                Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: AppColors.navyAlpha(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      '${student.faceMatch}% match',
                      style: textTheme.labelSmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_outlined, size: 13, color: AppColors.navyAlpha(0.45)),
                    const SizedBox(width: 3),
                    Text(
                      'View on map',
                      style: textTheme.labelSmall?.copyWith(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Present',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.success, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                student.time,
                style: textTheme.labelSmall?.copyWith(color: AppColors.navyAlpha(0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
