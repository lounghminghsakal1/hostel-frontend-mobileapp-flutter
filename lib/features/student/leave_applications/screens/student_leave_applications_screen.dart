import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/hostel_colors.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../widgets/cancel_leave_application.dart';
import '../widgets/student_leave_card.dart';
import 'leave_application_form_screen.dart';

class StudentLeaveApplicationsScreen extends ConsumerStatefulWidget {
  const StudentLeaveApplicationsScreen({super.key});

  @override
  ConsumerState<StudentLeaveApplicationsScreen> createState() =>
      _StudentLeaveApplicationsScreenState();
}

class _StudentLeaveApplicationsScreenState
    extends ConsumerState<StudentLeaveApplicationsScreen> {
  /// Id of the application being cancelled, to show its button as busy.
  int? _cancellingId;

  void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openForm({LeaveApplicationModel? application}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showLeaveApplicationForm(
      context,
      application: application,
    );
    if (!saved || !mounted) return;
    ref.invalidate(myLeaveApplicationsProvider);
    if (application != null) {
      ref.invalidate(myLeaveApplicationDetailProvider(application.id));
    }
    _showSnackBar(
      messenger,
      application == null
          ? 'Leave application submitted'
          : 'Leave application updated',
    );
  }

  Future<void> _cancel(LeaveApplicationModel application) =>
      confirmAndCancelLeaveApplication(
        context,
        ref,
        application,
        onBusyChanged: (busy) =>
            setState(() => _cancellingId = busy ? application.id : null),
      );

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(myLeaveApplicationsProvider);
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final pending = value.valueOrNull?.any((a) => a.isPending) ?? false;
    OutlinedButton action(
      String label,
      VoidCallback? onPressed, {
      bool danger = false,
      bool busy = false,
    }) => OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? c.danger : c.ink,
        side: BorderSide(color: danger ? c.danger : c.lineStrong),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      ),
      child: busy
          ? SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(color: c.danger, strokeWidth: 2),
            )
          : Text(label),
    );
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: Text(
          'Leave',
          style: TextStyle(
            color: c.ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        surfaceTintColor: c.surface,
        scrolledUnderElevation: 0,
        actions: [
          if (value.hasValue && !value.hasError && !pending)
            TextButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              style: TextButton.styleFrom(foregroundColor: c.primary),
              label: const Text('Apply for leave'),
            ),
        ],
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(myLeaveApplicationsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (applications) {
          final sorted = [...applications]
            ..sort((a, b) {
              if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
              return b.fromDate.compareTo(a.fromDate);
            });
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myLeaveApplicationsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (pending) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.infoSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: c.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You have a pending request',
                                style: TextStyle(
                                  color: c.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Edit or cancel it to apply for new dates.',
                                style: TextStyle(
                                  color: c.ink,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (sorted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: c.inkMuted,
                          size: 36,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No leave applications yet',
                          style: TextStyle(
                            color: c.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your requests and hostel admin decisions will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.inkMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                for (final a in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StudentLeaveCard(
                      application: a,
                      onTap: () => context.push(
                        AppRoutes.studentLeaveApplicationDetail(a.id),
                      ),
                      actions: a.isPending
                          ? [
                              action(
                                'Edit',
                                _cancellingId != null
                                    ? null
                                    : () => _openForm(application: a),
                              ),
                              action(
                                'Cancel request',
                                _cancellingId != null ? null : () => _cancel(a),
                                danger: true,
                                busy: _cancellingId == a.id,
                              ),
                            ]
                          : const [],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
