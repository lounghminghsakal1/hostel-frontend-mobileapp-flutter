import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';
import '../../../common/upcoming_events/widgets/event_card.dart';
import '../../../common/upcoming_events/widgets/event_image.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({super.key, required this.events});
  final List<UpcomingEventModel> events;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final visible = events.where((e) => e.isActive && !e.hasEnded).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming events',
              style: TextStyle(
                color: c.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.studentEvents),
              style: TextButton.styleFrom(foregroundColor: c.primary),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No upcoming events yet',
              style: TextStyle(color: c.inkMuted),
            ),
          )
        else
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final e = visible[i],
                    date = indiaWallTime(visible[i].startingAt);
                const months = [
                  'JAN',
                  'FEB',
                  'MAR',
                  'APR',
                  'MAY',
                  'JUN',
                  'JUL',
                  'AUG',
                  'SEP',
                  'OCT',
                  'NOV',
                  'DEC',
                ];
                return SizedBox(
                  width: 248,
                  child: Material(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () =>
                          context.push(AppRoutes.studentEventDetail(e.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 104,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (e.eventImageKey != null ||
                                    e.eventImageUrl != null)
                                  EventImage(event: e)
                                else
                                  ColoredBox(
                                    color: i.isEven ? c.brand : c.brandRaised,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        Icons.celebration_outlined,
                                        size: 100,
                                        color: c.brandRaised,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    width: 48,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surfaceRaised,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          months[date.month - 1],
                                          style: TextStyle(
                                            color: c.marigoldInk,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            color: c.ink,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.eventName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  eventTimeLabel(e),
                                  style: TextStyle(
                                    color: c.inkMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
