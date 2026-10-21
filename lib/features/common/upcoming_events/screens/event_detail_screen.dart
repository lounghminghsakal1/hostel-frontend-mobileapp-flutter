import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(event: event, iconSize: 48),
                Positioned(top: AppSpacing.md, left: AppSpacing.md, child: EventStateBadge(event: event)),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: EventDateBadge(date: event.startingAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          event.eventName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.sm),
        Text(
          'About this event',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          event.eventDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.navySoftAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.navySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.navy),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
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
