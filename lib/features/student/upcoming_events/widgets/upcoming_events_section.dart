import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../common/upcoming_events/providers/upcoming_events_providers.dart';
import '../../../common/upcoming_events/widgets/event_card.dart';
import '../screens/student_events_screen.dart';

/// Home-screen carousel of the next few events, with "See all". Hidden
/// entirely while loading, on error, or when there's nothing coming up.
class UpcomingEventsSection extends ConsumerWidget {
  const UpcomingEventsSection({super.key});

  static const _maxShown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = visibleToStudent(ref.watch(upcomingEventsProvider).valueOrNull ?? const []);
    if (events.isEmpty) return const SizedBox.shrink();
    final shown = events.take(_maxShown).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Upcoming Events',
            trailing: 'See all',
            onTrailingTap: () => context.push(AppRoutes.studentEvents),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Let the cards run to the screen edge past the page padding.
              clipBehavior: Clip.none,
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: shown.length == 1 ? MediaQuery.sizeOf(context).width - 40 : 250,
                child: EventCard(
                  event: shown[index],
                  compact: true,
                  onTap: () => context.push(AppRoutes.studentEventDetail(shown[index].id)),
                ),
              ),
            ),
          ),
          if (events.length > _maxShown) ...[
            const SizedBox(height: 8),
            Text(
              '+${events.length - _maxShown} more',
              style: TextStyle(color: AppColors.navyAlpha(0.5), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
