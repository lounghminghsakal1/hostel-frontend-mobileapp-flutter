import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../../../common/leave_applications/widgets/leave_application_details.dart';

/// One leave application in full. While it's pending the admin can approve
/// or reject it; the screen then pops with the new [LeaveStatus].
class AdminLeaveApplicationDetailScreen extends ConsumerStatefulWidget {
  const AdminLeaveApplicationDetailScreen({super.key, required this.applicationId});

  final int applicationId;

  @override
  ConsumerState<AdminLeaveApplicationDetailScreen> createState() =>
      _AdminLeaveApplicationDetailScreenState();
}

class _AdminLeaveApplicationDetailScreenState extends ConsumerState<AdminLeaveApplicationDetailScreen> {
  /// The decision being submitted, to show the matching button as busy.
  LeaveStatus? _submitting;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve leave?'),
        content: const Text('The student will see this application as approved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _review(LeaveStatus.approved);
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    // `null` means the dialog was dismissed; an empty string means no reason.
    if (reason == null) return;
    await _review(LeaveStatus.rejected, rejectionReason: reason.isEmpty ? null : reason);
  }

  Future<void> _review(LeaveStatus decision, {String? rejectionReason}) async {
    if (_submitting != null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = decision);
    try {
      await ref.read(leaveApplicationsRepositoryProvider).reviewLeaveApplication(
            id: widget.applicationId,
            decision: decision,
            rejectionReason: rejectionReason,
          );
      if (!mounted) return;
      ref.invalidate(adminLeaveApplicationDetailProvider(widget.applicationId));
      context.pop(decision);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = null);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationAsync = ref.watch(adminLeaveApplicationDetailProvider(widget.applicationId));
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
                  onPressed: () => ref.invalidate(adminLeaveApplicationDetailProvider(widget.applicationId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (application) => LeaveApplicationDetails(application: application, showStudent: true),
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
                          onPressed: _submitting != null ? null : _reject,
                          icon: _submitting == LeaveStatus.rejected
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                )
                              : const Icon(Icons.close_rounded, size: 20),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.navy, width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        isLoading: _submitting == LeaveStatus.approved,
                        onPressed: _submitting != null ? null : _approve,
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

/// Asks for an optional rejection reason. Pops with the trimmed reason
/// (possibly empty), or `null` if dismissed.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject leave?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 300,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Reason (optional, shown to the student)',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
