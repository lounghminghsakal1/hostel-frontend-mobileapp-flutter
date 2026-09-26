import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Top-center "Mark Attendance" action shown to students while the
/// attendance window is open (driven by `canMarkAttendance` from the home API).
class AttendanceActionCard extends StatelessWidget {
  const AttendanceActionCard({
    super.key,
    required this.canMarkAttendance,
    required this.onTap,
    this.isBusy = false,
    this.inactiveMessage = 'Attendance window is closed right now',
  });

  final bool canMarkAttendance;
  final VoidCallback onTap;

  /// True while a capture/upload/submit flow is already in flight, so the
  /// card shows progress instead of accepting another tap.
  final bool isBusy;

  /// Message shown on the inactive (tappable-to-refresh) variant of the
  /// card, e.g. to distinguish "window closed" from "already marked today".
  final String inactiveMessage;

  @override
  Widget build(BuildContext context) {
    if (!canMarkAttendance) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isBusy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.navySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: AppColors.navyAlpha(0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    inactiveMessage,
                    style: TextStyle(
                      color: AppColors.navyAlpha(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Icon(Icons.refresh_rounded, color: AppColors.navyAlpha(0.4), size: 20),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isBusy ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyAlpha(0.3),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(
                        Icons.face_retouching_natural_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                isBusy ? 'Submitting…' : 'Mark Attendance',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBusy
                    ? 'Please wait while we verify you'
                    : 'Attendance window is open · tap to scan',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
