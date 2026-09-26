import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../model/marked_student_model.dart';

class StudentAttendanceTile extends StatelessWidget {
  const StudentAttendanceTile({super.key, required this.student});

  final MarkedStudentModel student;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              student.initials,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
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
                  student.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Roll ${student.rollNumber} · Room ${student.roomNumber}',
                  style: TextStyle(
                    color: AppColors.navyAlpha(0.55),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: AppColors.navyAlpha(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      '${student.faceMatch}% match',
                      style: TextStyle(
                        color: AppColors.navyAlpha(0.5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_outlined, size: 13, color: AppColors.navyAlpha(0.45)),
                    const SizedBox(width: 3),
                    Text(
                      'View on map',
                      style: TextStyle(
                        color: AppColors.navyAlpha(0.5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
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
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Present',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                student.time,
                style: TextStyle(
                  color: AppColors.navyAlpha(0.45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
