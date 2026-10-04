import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';
import '../../../common/upcoming_events/providers/upcoming_events_providers.dart';
import '../../../common/upcoming_events/widgets/event_card.dart';

/// Active events that haven't ended yet, soonest first.
List<UpcomingEventModel> visibleToStudent(List<UpcomingEventModel> events) =>
    events.where((e) => e.isActive && !e.hasEnded).toList();

class StudentEventsScreen extends ConsumerWidget {
  const StudentEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
                const SizedBox(height: 14),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.navyAlpha(0.6)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(upcomingEventsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (events) {
          final visible = visibleToStudent(events);
          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () => ref.refresh(upcomingEventsProvider.future),
            child: visible.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.celebration_outlined, color: AppColors.navyAlpha(0.3), size: 44),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No upcoming events right now',
                          style: TextStyle(color: AppColors.navyAlpha(0.5)),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => EventCard(
                      event: visible[index],
                      onTap: () => context.push(AppRoutes.studentEventDetail(visible[index].id)),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
