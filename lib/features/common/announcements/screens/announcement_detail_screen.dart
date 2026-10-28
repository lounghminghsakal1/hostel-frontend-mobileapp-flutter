import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../providers/announcements_providers.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.id,
    this.isAdmin = false,
  });
  final int id;
  final bool isAdmin;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    // Both roles can read details; the backend scopes the result to the
    // authenticated user's hostel.
    final value = ref.watch(announcementDetailProvider(id));
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Announcement'),
        actions: [
          if (isAdmin)
            TextButton(
              onPressed: () async {
                await context.push(AppRoutes.adminAnnouncementEdit(id));
                ref.invalidate(announcementDetailProvider(id));
              },
              child: const Text('Edit'),
            ),
        ],
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('$e', textAlign: TextAlign.center),
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(announcementDetailProvider(id));
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (a) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(a.category, style: TextStyle(color: c.inkMuted)),
            if (a.isImportant)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Important',
                  style: TextStyle(
                    color: c.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              a.title,
              style: TextStyle(
                color: c.ink,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(a.dateLabel, style: TextStyle(color: c.inkMuted)),
            const SizedBox(height: 24),
            SelectableText(
              a.description,
              style: TextStyle(color: c.ink, fontSize: 15, height: 1.6),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Text('Status: ${a.status == 'ACTIVE' ? 'Active' : 'Inactive'}'),
              Text(
                '${toDisplayDate(a.startDate)} \u2013 ${toDisplayDate(a.endDate)}',
              ),
              Text(
                'Push notification: ${a.pushNotification ? 'Enabled' : 'Disabled'}',
              ),
            ],
            if (a.linkUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open link'),
                onPressed: () async {
                  final uri = Uri.tryParse(a.linkUrl!);
                  var opened = false;
                  if (uri != null && ['http', 'https'].contains(uri.scheme)) {
                    try {
                      opened = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  }
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unable to open this link')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
