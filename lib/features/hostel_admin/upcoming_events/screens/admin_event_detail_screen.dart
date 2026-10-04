import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../common/upcoming_events/screens/event_detail_screen.dart';

/// The shared event details, plus an edit button for the admin.
class AdminEventDetailScreen extends StatelessWidget {
  const AdminEventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context) {
    return EventDetailScreen(
      eventId: eventId,
      onEdit: (context) async {
        final messenger = ScaffoldMessenger.of(context);
        final saved = await context.push<bool>(AppRoutes.adminEventEdit(eventId));
        if (saved != true) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Event updated'), behavior: SnackBarBehavior.floating),
        );
      },
    );
  }
}
