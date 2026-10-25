import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/home_header.dart';
import '../../../../core/widgets/quick_link_card.dart';
import '../../../common/auth/widgets/logout.dart';
import '../../attendance/widgets/attendance_records_view.dart';

/// Landing page after a hostel admin logs in: today's attendance records,
/// with filters, below the header.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(adminProfileProvider);
    final names = profile.valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            HomeHeader(
              greeting: names?['hostelAdminName']?.toString() ?? 'Hostel Admin',
              subtitle: names == null
                  ? (profile.hasError
                        ? 'Profile unavailable'
                        : profile.isLoading
                        ? 'Loading profile...'
                        : 'Profile unavailable')
                  : '${(names['hostel'] as Map?)?['hostelName'] ?? 'Hostel unavailable'} | ${(names['college'] as Map?)?['collegeName'] ?? 'College unavailable'}',
              initials: 'HA',
              onLogout: () => confirmLogout(context, ref),
            ),
            Expanded(
              child: AttendanceRecordsView(
                leading: [
                  QuickLinkCard(
                    icon: Icons.groups_outlined,
                    label: 'Manage Students',
                    subtitle: 'View details, edit info and update photos',
                    onTap: () => context.go(AppRoutes.adminStudents),
                  ),
                  const SizedBox(height: 12),
                  QuickLinkCard(
                    icon: Icons.celebration_outlined,
                    label: 'Upcoming Events',
                    subtitle: 'Create events and choose what students see',
                    onTap: () => context.go(AppRoutes.adminEvents),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final adminProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final response = await ref
      .watch(dioProvider)
      .get(ApiEndpoints.adminSplashScreen);
  return response.data['data'] as Map<String, dynamic>?;
});
