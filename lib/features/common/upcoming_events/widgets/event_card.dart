import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../model/upcoming_event_model.dart';
import 'event_image.dart';

const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/// Small brass-accented date tile — day number over month — for an event's
/// start date. The one deliberate spot this screen uses the "room key"
/// accent, since a date is naturally what it should highlight.
class EventDateBadge extends StatelessWidget {
  const EventDateBadge({super.key, required this.date, this.compact = false});

  final DateTime date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.brass, width: 1.2),
        boxShadow: [BoxShadow(color: AppColors.navyAlpha(0.15), blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            _months[date.month - 1],
            style: TextStyle(
              color: AppColors.brassDeep,
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// `3 Oct 2026 · 5:00 PM – 8:00 PM` within a day, otherwise both full
/// date-times.
String eventTimeLabel(UpcomingEventModel event) {
  final start = event.startingAt;
  final end = event.endingAt;
  if (DateUtils.isSameDay(start, end)) {
    return '${toDisplayDate(start)} · ${toDisplayTime(start)} – ${toDisplayTime(end)}';
  }
  return '${toDisplayDateTime(start)} – ${toDisplayDateTime(end)}';
}

/// Small pill for an event's state: hidden from students, ongoing or ended.
/// Returns an empty box for an active, not-yet-started event.
class EventStateBadge extends StatelessWidget {
  const EventStateBadge({super.key, required this.event});

  final UpcomingEventModel event;

  @override
  Widget build(BuildContext context) {
    final (label, icon, filled) = !event.isActive
        ? ('Hidden', Icons.visibility_off_outlined, false)
        : event.hasEnded
            ? ('Ended', Icons.history_rounded, false)
            : event.isOngoing
                ? ('Happening now', Icons.bolt_rounded, true)
                : (null, null, false);
    if (label == null) return const SizedBox.shrink();

    final foreground = filled ? AppColors.white : AppColors.navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.navyAlpha(0.15), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// One event in a list: banner on top, name, time and description below.
/// With [compact], sized for a horizontal carousel.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap, this.compact = false});

  final UpcomingEventModel event;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dimmed = !event.isActive || event.hasEnded;
    final banner = Stack(
      fit: StackFit.expand,
      children: [
        EventImage(event: event, iconSize: compact ? 28 : 36),
        Positioned(top: AppSpacing.sm, left: AppSpacing.sm, child: EventStateBadge(event: event)),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: EventDateBadge(date: event.startingAt, compact: compact),
        ),
      ],
    );

    return Container(
      margin: compact ? null : const EdgeInsets.only(bottom: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: dimmed ? 0.7 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed height when compact, so the carousel's height holds
                // whatever the card's width.
                if (compact)
                  SizedBox(height: 110, width: double.infinity, child: banner)
                else
                  AspectRatio(aspectRatio: 16 / 7, child: banner),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: AppColors.navyAlpha(0.5)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              eventTimeLabel(event),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.navyAlpha(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!compact && event.eventDescription.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.eventDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.navyAlpha(0.7), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
