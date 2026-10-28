import 'package:flutter/material.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../model/student_home_model.dart';

class AttendanceActionCard extends StatelessWidget {
  const AttendanceActionCard({
    super.key,
    required this.home,
    required this.onMark,
    required this.onRefresh,
    this.isBusy = false,
    this.locallyMarkedAt,
  });
  final StudentHomeModel home;
  final VoidCallback onMark, onRefresh;
  final bool isBusy;
  final DateTime? locallyMarkedAt;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final state = home.attendanceState(
      DateTime.now(),
      locallyMarkedAt: locallyMarkedAt,
    );
    String time(DateTime value) => toDisplayTime(indiaWallTime(value));
    if (state == AttendanceCardState.open) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.brand,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c.scrim.withValues(alpha: .16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: c.marigold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    home.windowClosesAt == null
                        ? 'Window open'
                        : 'Window open \u00b7 closes ${time(home.windowClosesAt!)}',
                    style: TextStyle(
                      color: c.onBrandMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              "Mark tonight's attendance",
              style: TextStyle(
                color: c.onBrand,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Takes a selfie and your location. About 10 seconds.',
              style: TextStyle(
                color: c.onBrandMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isBusy ? null : onMark,
              style: FilledButton.styleFrom(
                backgroundColor: c.marigold,
                foregroundColor: c.onMarigold,
                disabledBackgroundColor: c.marigold,
                disabledForegroundColor: c.onMarigold,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isBusy
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.onMarigold,
                      ),
                    )
                  : const Icon(
                      Icons.face_retouching_natural_outlined,
                      size: 20,
                    ),
              label: Text(isBusy ? 'Submitting...' : 'Mark attendance'),
            ),
          ],
        ),
      );
    }
    final (eyebrow, title, body, icon, color, background) = switch (state) {
      AttendanceCardState.marked => (
        'Marked for today',
        "You're in for tonight",
        home.markedAt != null || locallyMarkedAt != null
            ? 'Marked at ${time(home.markedAt ?? locallyMarkedAt!)} \u00b7 at the hostel'
            : 'Your attendance has been recorded.',
        Icons.check_rounded,
        c.success,
        c.successSoft,
      ),
      AttendanceCardState.upcoming => (
        'Opens at ${time(home.windowOpensAt!)}',
        "Attendance isn't open yet",
        home.windowClosesAt == null
            ? 'The button appears here when the window opens.'
            : "Tonight's window is ${time(home.windowOpensAt!)} \u2013 ${time(home.windowClosesAt!)}. The button appears here when it opens.",
        Icons.schedule_outlined,
        c.inkMuted,
        c.surfaceRaised,
      ),
      AttendanceCardState.missed => (
        'Closed at ${time(home.windowClosesAt!)}',
        "You missed tonight's attendance",
        'Your hostel admin can see this. Talk to them if you were in the hostel.',
        Icons.cancel_outlined,
        c.danger,
        c.surfaceRaised,
      ),
      AttendanceCardState.photoNeeded => (
        'Photo needed',
        'Ask the hostel office to add your photo',
        'Attendance compares your selfie with your profile photo. You can mark it once your photo is on file.',
        Icons.photo_camera_outlined,
        c.warning,
        c.warningSoft,
      ),
      _ => (
        'Attendance',
        'Attendance is unavailable right now',
        'Refresh to check the latest attendance status.',
        Icons.schedule_outlined,
        c.inkMuted,
        c.surfaceRaised,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: background == c.surfaceRaised
            ? Border.all(color: c.line)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: state == AttendanceCardState.marked
                ? c.success
                : state == AttendanceCardState.missed
                ? c.dangerSoft
                : c.surfaceSunken,
            child: Icon(
              icon,
              color: state == AttendanceCardState.marked ? c.onSuccess : color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: c.inkMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (state == AttendanceCardState.unavailable)
                  TextButton(
                    onPressed: isBusy ? null : onRefresh,
                    child: const Text('Refresh status'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
