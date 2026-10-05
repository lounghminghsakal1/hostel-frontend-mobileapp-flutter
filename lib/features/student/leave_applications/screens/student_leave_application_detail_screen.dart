import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../../../common/leave_applications/widgets/leave_application_details.dart';
import '../widgets/cancel_leave_application.dart';
import '../widgets/leave_application_form_sheet.dart';

/// One of the student's own applications in full. While it's waiting for
/// approval it can still be edited or cancelled.
class StudentLeaveApplicationDetailScreen extends ConsumerStatefulWidget {
  const StudentLeaveApplicationDetailScreen({super.key, required this.applicationId});

  final int applicationId;

  @override
  ConsumerState<StudentLeaveApplicationDetailScreen> createState() =>
      _StudentLeaveApplicationDetailScreenState();
}

class _StudentLeaveApplicationDetailScreenState extends ConsumerState<StudentLeaveApplicationDetailScreen> {
  bool _isCancelling = false;

  Future<void> _edit(LeaveApplicationModel application) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showLeaveApplicationFormSheet(context, application: application);
    if (!saved || !mounted) return;
    ref.invalidate(myLeaveApplicationDetailProvider(widget.applicationId));
    ref.invalidate(myLeaveApplicationsProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Leave application updated'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _cancel(LeaveApplicationModel application) => confirmAndCancelLeaveApplication(
        context,
        ref,
        application,
        onBusyChanged: (busy) => setState(() => _isCancelling = busy),
      );

  @override
  Widget build(BuildContext context) {
    final detailProvider = myLeaveApplicationDetailProvider(widget.applicationId);
    final applicationAsync = ref.watch(detailProvider);
    final application = applicationAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Leave Application'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: applicationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
                const SizedBox(height: 14),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.navyAlpha(0.6)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(detailProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (application) => RefreshIndicator(
          color: AppColors.navy,
          onRefresh: () => ref.refresh(detailProvider.future),
          child: LeaveApplicationDetails(application: application),
        ),
      ),
      bottomNavigationBar: application != null && application.isPending
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _isCancelling ? null : () => _cancel(application),
                          icon: _isCancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                )
                              : const Icon(Icons.close_rounded, size: 20),
                          label: const Text('Cancel leave'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.navy, width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onPressed: _isCancelling ? null : () => _edit(application),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
