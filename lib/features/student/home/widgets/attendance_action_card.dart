import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Top-center "Mark Attendance" action shown to students while the
/// attendance window is open (driven by `canMarkAttendance` from the home API).
class AttendanceActionCard extends StatefulWidget {
  const AttendanceActionCard({
    super.key,
    required this.canMarkAttendance,
    required this.onTap,
    this.isBusy = false,
    this.isComplete = false,
    this.inactiveMessage = 'Attendance window is closed right now',
  });

  final bool canMarkAttendance;
  final VoidCallback onTap;

  /// True while a capture/upload/submit flow is already in flight, so the
  /// card shows progress instead of accepting another tap.
  final bool isBusy;
  final bool isComplete;

  /// Message shown on the inactive (tappable-to-refresh) variant of the
  /// card, e.g. to distinguish "window closed" from "already marked today".
  final String inactiveMessage;

  @override
  State<AttendanceActionCard> createState() => _AttendanceActionCardState();
}

class _AttendanceActionCardState extends State<AttendanceActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confirmController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    value: widget.isComplete ? 1 : 0,
  );
  late final Animation<double> _confirmScale = CurvedAnimation(
    parent: _confirmController,
    curve: Curves.elasticOut,
  );

  @override
  void didUpdateWidget(covariant AttendanceActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The one deliberate animated moment in this feature area: a satisfying
    // pop when attendance just got marked. Every other transition here is
    // static by design.
    if (widget.isComplete && !oldWidget.isComplete) {
      _confirmController.forward(from: 0);
    } else if (!widget.isComplete && oldWidget.isComplete) {
      _confirmController.value = 0;
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canMarkAttendance) {
      final background = widget.isComplete
          ? AppColors.successSoft
          : AppColors.navySoft;
      final foreground = widget.isComplete
          ? AppColors.success
          : AppColors.navyAlpha(0.5);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: widget.isBusy ? null : widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: widget.isComplete
                      ? _confirmScale
                      : const AlwaysStoppedAnimation(1),
                  child: Icon(
                    widget.isComplete
                        ? Icons.check_circle_rounded
                        : Icons.lock_clock_rounded,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.inactiveMessage,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: widget.isComplete
                              ? AppColors.success
                              : AppColors.navyAlpha(0.6),
                        ),
                  ),
                ),
                Icon(
                  Icons.refresh_rounded,
                  color: AppColors.navyAlpha(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl + 2),
        onTap: widget.isBusy ? null : widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl + 2),
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
                child: widget.isBusy
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: AppColors.brassSoft,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(
                        Icons.face_retouching_natural_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.isBusy ? 'Submitting…' : 'Mark Attendance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.isBusy
                    ? 'Please wait while we verify you'
                    : 'Attendance window is open · tap to scan',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.78),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
