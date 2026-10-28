import 'package:flutter/material.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../model/leave_application_model.dart';

/// Status pill. Each status reads by hue, like a register: green for
/// approved, amber for pending, red for rejected.
class LeaveStatusChip extends StatelessWidget {
  const LeaveStatusChip({super.key, required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final (icon, background, foreground) = switch (status) {
      LeaveStatus.approved => (
        Icons.check_circle_outline_rounded,
        c.successSoft,
        c.success,
      ),
      LeaveStatus.pending => (Icons.schedule_rounded, c.warningSoft, c.warning),
      LeaveStatus.rejected => (Icons.cancel_outlined, c.dangerSoft, c.danger),
      LeaveStatus.cancelled ||
      LeaveStatus.unknown => (Icons.block_rounded, c.surfaceSunken, c.inkMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.label,
              style: TextStyle(
                color: foreground,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
