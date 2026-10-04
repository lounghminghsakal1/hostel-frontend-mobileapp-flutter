import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../model/upcoming_event_model.dart';
import '../providers/upcoming_events_providers.dart';
import '../widgets/event_card.dart';
import '../widgets/event_image.dart';

/// Full details of one event, for students and admins. [onEdit] (admin
/// only) adds an edit button to the app bar.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId, this.onEdit});

  final int eventId;
  final void Function(BuildContext context)? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(upcomingEventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Event'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (onEdit != null && eventAsync.hasValue)
            IconButton(
              tooltip: 'Edit event',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => onEdit!(context),
            ),
        ],
      ),
      body: eventAsync.when(
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
                  onPressed: () => ref.invalidate(upcomingEventDetailProvider(eventId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (event) => RefreshIndicator(
          color: AppColors.navy,
          onRefresh: () => ref.refresh(upcomingEventDetailProvider(eventId).future),
          child: _EventDetails(event: event),
        ),
      ),
    );
  }
}

class _EventDetails extends StatelessWidget {
  const _EventDetails({required this.event});

  final UpcomingEventModel event;

  Future<void> _open(BuildContext context, Uri uri) async {
    bool opened;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = event.eventLink;
    final linkUri = link == null ? null : Uri.tryParse(link);
    final contactName = event.contactPersonName;
    final contactPhone = event.contactPersonPhone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(event: event, iconSize: 48),
                Positioned(top: 12, left: 12, child: EventStateBadge(event: event)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          event.eventName,
          style: const TextStyle(color: AppColors.navy, fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _InfoTile(
          icon: Icons.schedule_rounded,
          label: 'When',
          value: eventTimeLabel(event),
        ),
        if (contactName != null || contactPhone != null)
          _InfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Contact',
            value: [?contactName, ?contactPhone].join(' · '),
            actionIcon: contactPhone == null ? null : Icons.call_outlined,
            onAction: contactPhone == null ? null : () => _open(context, Uri(scheme: 'tel', path: contactPhone)),
          ),
        if (linkUri != null)
          _InfoTile(
            icon: Icons.link_rounded,
            label: 'Link',
            value: link!,
            actionIcon: Icons.open_in_new_rounded,
            onAction: () => _open(context, linkUri),
          ),
        const SizedBox(height: 8),
        const Text(
          'About this event',
          style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          event.eventDescription,
          style: TextStyle(color: AppColors.navyAlpha(0.8), fontSize: 14, height: 1.55),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.navySoftAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 11.5)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionIcon != null) Icon(actionIcon, size: 20, color: AppColors.navyAlpha(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
