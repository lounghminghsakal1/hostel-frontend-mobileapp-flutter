import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';
import '../../../common/upcoming_events/providers/upcoming_events_providers.dart';
import '../../../common/upcoming_events/widgets/event_card.dart';

enum _EventFilter {
  upcoming('Upcoming'),
  past('Past'),
  hidden('Hidden'),
  all('All');

  const _EventFilter(this.label);

  final String label;

  bool matches(UpcomingEventModel event) => switch (this) {
        upcoming => event.isActive && !event.hasEnded,
        past => event.isActive && event.hasEnded,
        hidden => !event.isActive,
        all => true,
      };
}

/// Admin-only list of every event, including past and hidden ones. Tap one
/// to view it, or add a new one.
class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  _EventFilter _filter = _EventFilter.upcoming;

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await context.push<bool>(AppRoutes.adminEventCreate);
    if (saved != true || !mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Event created'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final events = eventsAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add event'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _EventFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _EventFilter.values[index];
                final selected = filter == _filter;
                final count = events.where(filter.matches).length;
                return ChoiceChip(
                  label: Text(eventsAsync.hasValue ? '${filter.label} ($count)' : filter.label),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = filter),
                  backgroundColor: AppColors.navySoftAlt,
                  selectedColor: AppColors.navy,
                  side: BorderSide(color: selected ? AppColors.navy : AppColors.navyAlpha(0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: eventsAsync.when(
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
                var visible = events.where(_filter.matches).toList();
                // Most recent first for past events; soonest first otherwise.
                if (_filter == _EventFilter.past) visible = visible.reversed.toList();
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
                                events.isEmpty
                                    ? 'No events yet'
                                    : 'No ${_filter.label.toLowerCase()} events',
                                style: TextStyle(color: AppColors.navyAlpha(0.5)),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          // Bottom padding keeps the last card clear of the add button.
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                          itemCount: visible.length,
                          itemBuilder: (context, index) => EventCard(
                            event: visible[index],
                            onTap: () => context.push(AppRoutes.adminEventDetail(visible[index].id)),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
