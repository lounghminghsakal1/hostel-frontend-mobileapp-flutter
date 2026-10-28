import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/widgets/api_listing_view.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../model/announcement_model.dart';
import '../widgets/announcement_tile.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key, this.isAdmin = false});
  final bool isAdmin;
  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _listing = GlobalKey<ApiListingViewState>();
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: Text(widget.isAdmin ? 'Announcements' : 'Notices')),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(AppRoutes.adminAnnouncementCreate);
                _listing.currentState?.reload();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add announcement'),
            )
          : null,
      body: widget.isAdmin
          ? ApiListingView(
              key: _listing,
              endpoint: ApiEndpoints.announcements,
              dateFilters: true,
              filters: const [
                ListingFilter('by_announcement_title', 'Title'),
                ListingFilter(
                  'by_status',
                  'Status',
                  options: {'ACTIVE': 'Active', 'INACTIVE': 'Inactive'},
                ),
                ListingFilter(
                  'by_announcement_type',
                  'Type',
                  options: {
                    'HOSTEL_ANNOUNCEMENT': 'Hostel',
                    'COLLEGE_ANNOUNCEMENT': 'College',
                    'OTHER': 'Other',
                  },
                ),
                ListingFilter(
                  'only_important',
                  'Importance',
                  options: {'true': 'Important only', 'false': 'All'},
                ),
              ],
              itemBuilder: (context, row, reload) {
                final a = AnnouncementModel.fromJson(row);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnnouncementTile(
                      announcement: a,
                      expanded: true,
                      showStatus: true,
                      onTap: () async {
                        await context.push(
                          AppRoutes.adminAnnouncementDetail(a.id),
                        );
                        reload();
                      },
                    ),
                  ),
                );
              },
            )
          : ApiListingView(
              endpoint: ApiEndpoints.announcements,
              defaults: const {'by_status': 'ACTIVE'},
              dateFilters: true,
              filters: const [
                ListingFilter('by_announcement_title', 'Title'),
                ListingFilter(
                  'by_announcement_type',
                  'Type',
                  options: {
                    'HOSTEL_ANNOUNCEMENT': 'Hostel',
                    'COLLEGE_ANNOUNCEMENT': 'College',
                    'OTHER': 'Other',
                  },
                ),
                ListingFilter(
                  'only_important',
                  'Importance',
                  options: {'true': 'Important only', 'false': 'All'},
                ),
              ],
              itemBuilder: (context, row, _) {
                final announcement = AnnouncementModel.fromJson(row);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnnouncementTile(
                      announcement: announcement,
                      expanded: true,
                      onTap: () => context.push(
                        AppRoutes.studentAnnouncementDetail(announcement.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
