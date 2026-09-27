import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/home_header.dart';
import '../../../common/auth/widgets/logout.dart';
import '../../attendance/widgets/attendance_records_view.dart';

/// Landing page after a hostel admin logs in: today's attendance records,
/// with filters, below the header.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            HomeHeader(
              greeting: 'Hostel Admin',
              subtitle: 'Today · ${toDisplayDate(DateTime.now())}',
              initials: 'HA',
              onLogout: () => confirmLogout(context, ref),
            ),
            const Expanded(
              child: AttendanceRecordsView(
                leading: [
                  _ManageStudentsCard(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: const [
          Icons.home_rounded,
          Icons.meeting_room_outlined,
          Icons.groups_outlined,
          Icons.event_note_rounded,
        ],
        activeIndex: 0,
        onItemTap: (index) {
          if (index != 2) return false;
          context.push(AppRoutes.adminStudents);
          return true;
        },
      ),
    );
  }
}

class _ManageStudentsCard extends StatelessWidget {
  const _ManageStudentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(AppRoutes.adminStudents),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_outlined, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage Students',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'View details, edit info and update photos',
                        style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.navyAlpha(0.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
