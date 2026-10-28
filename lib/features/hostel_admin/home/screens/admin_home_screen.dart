import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hostel_colors.dart';
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
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final adminName = names?['hostelAdminName']?.toString() ?? 'Hostel Admin';
    final hostel =
        (names?['hostel'] as Map?)?['hostelName']?.toString() ?? 'Our Hostel';
    final initials = _initials(adminName);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: c.surface,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hostel admin',
                            style: TextStyle(
                              color: c.onBrandMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            hostel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.onBrand,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      tooltip: 'Account',
                      onSelected: (_) => confirmLogout(context, ref),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Log out'),
                        ),
                      ],
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: c.brandRaised,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: c.onBrand,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: AttendanceRecordsView(isAdminHome: true)),
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

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  return parts.isEmpty
      ? 'HA'
      : '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
            .toUpperCase();
}
