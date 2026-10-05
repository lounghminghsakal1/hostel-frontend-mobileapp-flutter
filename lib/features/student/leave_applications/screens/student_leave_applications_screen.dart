import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../../../common/leave_applications/widgets/leave_application_card.dart';
import '../widgets/cancel_leave_application.dart';
import '../widgets/leave_application_form_sheet.dart';

/// The student's leave applications with their review status. Pending ones
/// can still be edited or cancelled.
class StudentLeaveApplicationsScreen extends ConsumerStatefulWidget {
  const StudentLeaveApplicationsScreen({super.key});

  @override
  ConsumerState<StudentLeaveApplicationsScreen> createState() => _StudentLeaveApplicationsScreenState();
}

class _StudentLeaveApplicationsScreenState extends ConsumerState<StudentLeaveApplicationsScreen> {
  /// Id of the application being cancelled, to show its button as busy.
  int? _cancellingId;

  void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openForm({LeaveApplicationModel? application}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showLeaveApplicationFormSheet(context, application: application);
    if (!saved || !mounted) return;
    ref.invalidate(myLeaveApplicationsProvider);
    if (application != null) ref.invalidate(myLeaveApplicationDetailProvider(application.id));
    _showSnackBar(messenger, application == null ? 'Leave application submitted' : 'Leave application updated');
  }

  Future<void> _cancel(LeaveApplicationModel application) => confirmAndCancelLeaveApplication(
        context,
        ref,
        application,
        onBusyChanged: (busy) => setState(() => _cancellingId = busy ? application.id : null),
      );

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(myLeaveApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Leave Applications'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply for leave'),
      ),
      body: applicationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
        error: (error, _) => _LeaveApplicationsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(myLeaveApplicationsProvider),
        ),
        data: (applications) => RefreshIndicator(
          color: AppColors.navy,
          onRefresh: () => ref.refresh(myLeaveApplicationsProvider.future),
          child: applications.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(Icons.event_available_rounded, color: AppColors.navyAlpha(0.3), size: 44),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'No leave applications yet',
                        style: TextStyle(color: AppColors.navyAlpha(0.5)),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  // Bottom padding keeps the last card clear of the apply button.
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    final isCancelling = _cancellingId == application.id;
                    return LeaveApplicationCard(
                      application: application,
                      onTap: () => context.push(AppRoutes.studentLeaveApplicationDetail(application.id)),
                      actions: application.isPending
                          ? [
                              TextButton.icon(
                                onPressed: _cancellingId != null ? null : () => _openForm(application: application),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                              TextButton.icon(
                                onPressed: _cancellingId != null ? null : () => _cancel(application),
                                icon: isCancelling
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                      )
                                    : const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Cancel'),
                              ),
                            ]
                          : const [],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _LeaveApplicationsError extends StatelessWidget {
  const _LeaveApplicationsError({required this.message, required this.onRetry});

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
