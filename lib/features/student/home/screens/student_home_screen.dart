import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/camera_permission.dart';
import '../../../../core/utils/location_permission.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../common/auth/widgets/logout.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../attendance/screens/face_capture_screen.dart';
import '../../upcoming_events/widgets/upcoming_events_section.dart';
import '../model/student_home_model.dart';
import '../providers/student_home_providers.dart';
import '../widgets/announcement_card.dart';
import '../widgets/attendance_action_card.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  bool _isSubmittingAttendance = false;
  bool _justMarkedAttendance = false;

  @override
  void initState() {
    super.initState();
    // Ask for camera + location upfront so the mark-attendance flow doesn't
    // stall on a permission prompt later.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestStartupPermissions());
  }

  Future<void> _requestStartupPermissions() async {
    if (!mounted) return;
    await ensureCameraPermission(context);
    if (!mounted) return;
    await ensureLocationPermission(context);
  }

  Future<void> _handleMarkAttendance() async {
    if (_isSubmittingAttendance) return;

    final cameraGranted = await ensureCameraPermission(context);
    if (!cameraGranted || !mounted) return;

    final locationGranted = await ensureLocationPermission(context);
    if (!locationGranted || !mounted) return;

    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );
    if (imagePath == null || !mounted) return;

    setState(() => _isSubmittingAttendance = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final repository = ref.read(attendanceRepositoryProvider);
      final imageKey = await repository.uploadAttendanceImage(imagePath);
      await repository.submitAttendanceRecord(
        capturedImageKey: imageKey,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _isSubmittingAttendance = false;
        _justMarkedAttendance = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance marked successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingAttendance = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _handleRefreshAttendanceStatus() {
    setState(() => _justMarkedAttendance = false);
    ref.invalidate(studentHomeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(studentHomeProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Home',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout_rounded),
                    color: AppColors.navy,
                    onPressed: () => confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: homeAsync.when(
                loading: () => const _StudentHomeSkeleton(),
                error: (error, _) => _StudentHomeError(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(studentHomeProvider),
                ),
                data: (home) => _StudentHomeContent(
                  home: home,
                  isSubmitting: _isSubmittingAttendance,
                  justMarked: _justMarkedAttendance,
                  onMarkAttendance: _handleMarkAttendance,
                  onRefreshStatus: _handleRefreshAttendanceStatus,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: const [
          Icons.home_rounded,
          Icons.event_note_rounded,
          Icons.fingerprint_rounded,
          Icons.person_outline_rounded,
        ],
        activeIndex: 0,
        onItemTap: (index) {
          if (index != 1) return false;
          context.push(AppRoutes.studentLeaveApplications);
          return true;
        },
      ),
    );
  }
}

class _StudentHomeContent extends StatelessWidget {
  const _StudentHomeContent({
    required this.home,
    required this.isSubmitting,
    required this.justMarked,
    required this.onMarkAttendance,
    required this.onRefreshStatus,
  });

  final StudentHomeModel home;
  final bool isSubmitting;
  final bool justMarked;
  final VoidCallback onMarkAttendance;
  final VoidCallback onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    // Once marked, the card shows as inactive until the student taps it
    // again to re-check `/students/home` for a fresh `canMarkAttendance`.
    final canMark = home.canMarkAttendance && !justMarked;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AttendanceActionCard(
            canMarkAttendance: canMark,
            isBusy: isSubmitting,
            inactiveMessage: justMarked
                ? 'Attendance marked for today · tap to check again'
                : 'Attendance window is closed right now',
            onTap: canMark ? onMarkAttendance : onRefreshStatus,
          ),
          const SizedBox(height: 26),
          const UpcomingEventsSection(),
          const SectionHeader(title: 'Announcements'),
          const SizedBox(height: 14),
          if (home.announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No announcements yet',
                  style: TextStyle(color: AppColors.navyAlpha(0.5)),
                ),
              ),
            )
          else
            ...home.announcements.map(
              (a) => AnnouncementCard(announcement: a),
            ),
        ],
      ),
    );
  }
}

class _StudentHomeSkeleton extends StatelessWidget {
  const _StudentHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.navy),
    );
  }
}

class _StudentHomeError extends StatelessWidget {
  const _StudentHomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
          ],
        ),
      ),
    );
  }
}
