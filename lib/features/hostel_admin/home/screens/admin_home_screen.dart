import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/home_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../common/auth/widgets/logout.dart';
import '../model/admin_dashboard_model.dart';
import '../providers/admin_home_providers.dart';
import '../widgets/stat_card.dart';
import '../widgets/student_attendance_tile.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.navy),
          ),
          error: (error, _) => _AdminHomeError(
            message: error.toString(),
            onRetry: () => ref.invalidate(adminDashboardProvider),
            onLogout: () => confirmLogout(context, ref),
          ),
          data: (dashboard) => _AdminHomeContent(
            dashboard: dashboard,
            onLogout: () => confirmLogout(context, ref),
          ),
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

class _AdminHomeContent extends StatelessWidget {
  const _AdminHomeContent({required this.dashboard, required this.onLogout});

  final AdminDashboardModel dashboard;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeHeader(
          greeting: 'Hostel Admin',
          subtitle: '${dashboard.hostelName} · ${dashboard.dateLabel}',
          initials: 'HA',
          onLogout: onLogout,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Students',
                        value: '${dashboard.totalStudents}',
                        icon: Icons.groups_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Marked Present',
                        value: '${dashboard.markedPresent}',
                        icon: Icons.check_circle_outline_rounded,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Not Marked',
                        value: '${dashboard.notMarked}',
                        icon: Icons.hourglass_empty_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _ManageStudentsCard(),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Attendance Marked Students',
                  trailing: 'See all',
                  onTrailingTap: () {},
                ),
                const SizedBox(height: 14),
                ...dashboard.markedStudents.map(
                  (s) => StudentAttendanceTile(student: s),
                ),
              ],
            ),
          ),
        ),
      ],
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

class _AdminHomeError extends StatelessWidget {
  const _AdminHomeError({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navyAlpha(0.6)),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
            TextButton(onPressed: onLogout, child: const Text('Log out')),
          ],
        ),
      ),
    );
  }
}
