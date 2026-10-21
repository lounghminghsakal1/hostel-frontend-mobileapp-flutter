import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/camera_permission.dart';
import '../../../../core/utils/location_permission.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/home_header.dart';
import '../../../common/upcoming_events/providers/upcoming_events_providers.dart';
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

  Future<void> _handleMarkAttendance() async {
    if (_isSubmittingAttendance) return;

    setState(() => _isSubmittingAttendance = true);
    try {
      final cameraGranted = await ensureCameraPermission(context);
      if (!cameraGranted || !mounted) return;

      final locationGranted = await ensureLocationPermission(context);
      if (!locationGranted || !mounted) return;

      final imagePath = await Navigator.of(context, rootNavigator: true)
          .push<String>(
            MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
          );
      if (imagePath == null || !mounted) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmittingAttendance = false);
    }
  }

  Future<void> _handleRefreshAttendanceStatus() async {
    ref.invalidate(studentHomeProvider);
    await ref.read(studentHomeProvider.future);
    if (mounted) setState(() => _justMarkedAttendance = false);
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(studentHomeProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(
              greeting: 'Your hostel, at a glance',
              subtitle: 'Attendance, events and announcements',
              initials: 'ST',
              onLogout: () => confirmLogout(context, ref),
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
    );
  }
}

class _StudentHomeContent extends ConsumerWidget {
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
  final Future<void> Function() onRefreshStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Once marked, the card shows as inactive until the student taps it
    // again to re-check `/students/home` for a fresh `canMarkAttendance`.
    final canMark = home.canMarkAttendance && !justMarked;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingEventsProvider);
        try {
          await onRefreshStatus();
        } catch (_) {
          // The provider displays a retry action when refreshing fails.
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AttendanceActionCard(
              canMarkAttendance: canMark,
              isBusy: isSubmitting,
              isComplete: justMarked,
              inactiveMessage: justMarked
                  ? 'Attendance marked for today · tap to check again'
                  : 'Attendance window is closed right now',
              onTap: canMark
                  ? onMarkAttendance
                  : () async {
                      try {
                        await onRefreshStatus();
                      } catch (_) {
                        // The home provider renders the error with a retry action.
                      }
                    },
            ),
            const SizedBox(height: 26),
            const UpcomingEventsSection(),
            const SectionHeader(title: 'Announcements'),
            const SizedBox(height: 14),
            if (home.announcements.isEmpty)
              const AppEmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
                message: 'Hostel updates and notices will show up here.',
              )
            else
              ...home.announcements.map(
                (a) => AnnouncementCard(announcement: a),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentHomeSkeleton extends StatelessWidget {
  const _StudentHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonBox(height: 150, radius: AppRadius.xl),
          const SizedBox(height: AppSpacing.xxl),
          _SkeletonBox(height: 18, width: 140, radius: AppRadius.sm),
          const SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 96, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          _SkeletonBox(height: 18, width: 160, radius: AppRadius.sm),
          const SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 72, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 72, radius: AppRadius.lg),
        ],
      ),
    );
  }
}

/// Static placeholder box used while the home screen loads. Deliberately
/// unanimated — this feature area reserves its one animated moment for the
/// attendance check-in confirmation.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.width, required this.radius});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(radius),
      ),
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
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.errorSoft,
              child: Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.navyAlpha(0.65),
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
