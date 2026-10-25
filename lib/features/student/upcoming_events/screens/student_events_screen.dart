import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/api_listing_view.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';
import '../../../common/upcoming_events/widgets/event_card.dart';

List<UpcomingEventModel> visibleToStudent(List<UpcomingEventModel> events) =>
    events.where((e) => e.isActive && !e.hasEnded).toList();

class StudentEventsScreen extends StatefulWidget {
  const StudentEventsScreen({super.key});
  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen> {
  final key = GlobalKey<ApiListingViewState>();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Upcoming Events')),

    body: ApiListingView(
      key: key,
      endpoint: ApiEndpoints.upcomingEvents,
      events: true,
      defaults: const {'is_active': 'true'},
      filters: const [ListingFilter('by_event_name', 'Event name')],
      includeRow: (row) => !UpcomingEventModel.fromJson(row).hasEnded,
      itemBuilder: (context, row, reload) => EventCard(
        event: UpcomingEventModel.fromJson(row),
        onTap: () async {
          await context.push(
            AppRoutes.studentEventDetail((row['id'] as num).toInt()),
          );
          reload();
        },
      ),
    ),
  );
}
