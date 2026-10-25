import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/api_listing_view.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';
import '../../../common/upcoming_events/widgets/event_card.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});
  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final key = GlobalKey<ApiListingViewState>();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Upcoming Events')),
    floatingActionButton: FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('Add event'),
      onPressed: () async {
        await context.push(AppRoutes.adminEventCreate);
        key.currentState?.reload();
      },
    ),
    body: ApiListingView(
      key: key,
      endpoint: ApiEndpoints.upcomingEvents,
      events: true,
      defaults: const {'is_active': 'false'},
      filters: eventFilters,

      itemBuilder: (context, row, reload) => EventCard(
        event: UpcomingEventModel.fromJson(row),
        onTap: () async {
          await context.push(
            AppRoutes.adminEventDetail((row['id'] as num).toInt()),
          );
          reload();
        },
      ),
    ),
  );
}
