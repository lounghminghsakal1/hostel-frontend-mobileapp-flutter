import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/camera_permission.dart';
import '../../../../core/utils/location_permission.dart';
import '../../../common/auth/widgets/logout.dart';
import '../../../common/announcements/widgets/announcement_tile.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../attendance/screens/face_capture_screen.dart';
import '../../attendance/screens/attendance_success_screen.dart';
import '../../upcoming_events/widgets/upcoming_events_section.dart';
import '../providers/student_home_providers.dart';
import '../model/student_home_model.dart';
import '../widgets/attendance_action_card.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen>
    with WidgetsBindingObserver {
  bool _isSubmittingAttendance = false;
  DateTime? _locallyMarkedAt;
  Timer? _statusTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(studentHomeProvider);
    }
  }

  void _scheduleStatusRefresh(StudentHomeModel home) {
    _statusTimer?.cancel();
    final now = DateTime.now();
    final local = indiaWallTime(now);
    final midnight = indiaPickerToInstant(
      DateTime(local.year, local.month, local.day + 1),
    );
    final boundaries = [
      midnight,
      home.windowOpensAt,
      home.windowClosesAt,
    ].whereType<DateTime>().where((t) => t.isAfter(now)).toList()..sort();
    _statusTimer = Timer(
      boundaries.first.difference(now) + const Duration(seconds: 1),
      () {
        if (mounted) {
          ref.invalidate(studentHomeProvider);
        }
      },
    );
  }

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
            MaterialPageRoute(
              settings: const RouteSettings(name: '/attendance/photo'),
              builder: (_) => const FaceCaptureScreen(requireLocation: true),
            ),
          );
      if (imagePath == null || !mounted) return;

      // Recheck after capture in case access was revoked or GPS was disabled.
      if (!await ensureCameraPermission(context) || !mounted) return;
      if (!await ensureLocationPermission(context) || !mounted) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final home = ref.read(studentHomeProvider).valueOrNull;
      final repository = ref.read(attendanceRepositoryProvider);
      final imageKey = await repository.uploadAttendanceImage(imagePath);
      await repository.submitAttendanceRecord(
        capturedImageKey: imageKey,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      final markedAt = DateTime.now();
      setState(() => _locallyMarkedAt = markedAt);
      ref.invalidate(studentHomeProvider);
      await Navigator.of(context, rootNavigator: true).push<void>(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, animation, secondaryAnimation) =>
              AttendanceSuccessScreen(
                markedAt: markedAt,
                windowOpensAt: home?.windowOpensAt,
                windowClosesAt: home?.windowClosesAt,
              ),
        ),
      );
      if (mounted) ref.invalidate(studentHomeProvider);
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
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(studentHomeProvider, (_, next) {
      final home = next.valueOrNull;
      if (home != null) _scheduleStatusRefresh(home);
    });
    final homeAsync = ref.watch(studentHomeProvider);
    final home = homeAsync.valueOrNull;
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final hour = indiaWallTime(DateTime.now()).hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: c.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              color: c.onBrandMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            home?.studentName ?? 'Student',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.onBrand,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.bed_outlined,
                                size: 16,
                                color: c.onBrandMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  [
                                    if (home?.roomNumber != null)
                                      home!.roomNumber!,
                                    home?.hostelName ?? 'Our Hostel',
                                  ].join(' \u00b7 '),
                                  style: TextStyle(
                                    color: c.onBrandMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Account',
                      onSelected: (_) => confirmLogout(context, ref),
                      itemBuilder: (_) => [
                        if (home?.accountEmail != null)
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  home!.accountEmail!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${home.roleName ?? 'Student'} · ${home.accountStatus ?? 'Account'}',
                                  style: TextStyle(
                                    color: c.inkMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Log out'),
                        ),
                      ],
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: c.brandRaised,
                        child: Text(
                          home?.initials ?? 'ST',
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    await _handleRefreshAttendanceStatus();
                  } catch (_) {}
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    homeAsync.when(
                      loading: () => Container(
                        height: 194,
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _SectionError(
                        message: '$e',
                        onRetry: () => ref.invalidate(studentHomeProvider),
                      ),
                      data: (data) => AttendanceActionCard(
                        home: data,
                        locallyMarkedAt: _locallyMarkedAt,
                        isBusy: _isSubmittingAttendance,
                        onMark: _handleMarkAttendance,
                        onRefresh: () async {
                          try {
                            await _handleRefreshAttendanceStatus();
                          } catch (_) {}
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Announcements',
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.studentAnnouncements),
                          style: TextButton.styleFrom(
                            foregroundColor: c.primary,
                          ),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    homeAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (data) => Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: c.surfaceRaised,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: data.announcements.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No announcements yet',
                                  style: TextStyle(color: c.inkMuted),
                                ),
                              )
                            : Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < data.announcements.take(2).length;
                                    i++
                                  ) ...[
                                    if (i != 0)
                                      Divider(height: 1, color: c.line),
                                    AnnouncementTile(
                                      announcement: data.announcements[i],
                                      expanded: i == 0,
                                      onTap: () => context.push(
                                        AppRoutes.studentAnnouncementDetail(
                                          data.announcements[i].id,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    homeAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (data) =>
                          UpcomingEventsSection(events: data.upcomingEvents),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
