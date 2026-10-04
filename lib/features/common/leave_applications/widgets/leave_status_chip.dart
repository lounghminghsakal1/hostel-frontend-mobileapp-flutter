import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../model/leave_application_model.dart';

/// Status pill. The palette is navy-only, so each status differs by fill
/// and icon rather than by hue.
class LeaveStatusChip extends StatelessWidget {
  const LeaveStatusChip({super.key, required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground, border) = switch (status) {
      LeaveStatus.approved => (Icons.check_circle_rounded, AppColors.navy, AppColors.white, null),
      LeaveStatus.pending => (Icons.schedule_rounded, AppColors.navySoft, AppColors.navy, null),
      LeaveStatus.rejected => (Icons.cancel_outlined, AppColors.white, AppColors.navy, AppColors.navy),
      LeaveStatus.cancelled ||
      LeaveStatus.unknown =>
        (Icons.block_rounded, AppColors.navyAlpha(0.05), AppColors.navyAlpha(0.5), null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: border == null ? null : Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(color: foreground, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
