import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../widgets/admin_leave_request_details.dart';
import '../../../common/leave_applications/widgets/leave_status_chip.dart';

/// One leave application in full. While it's pending the admin can approve
/// or reject it; the screen then pops with the new [LeaveStatus].
class AdminLeaveApplicationDetailScreen extends ConsumerStatefulWidget {
  const AdminLeaveApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  final int applicationId;

  @override
  ConsumerState<AdminLeaveApplicationDetailScreen> createState() =>
      _AdminLeaveApplicationDetailScreenState();
}

class _AdminLeaveApplicationDetailScreenState
    extends ConsumerState<AdminLeaveApplicationDetailScreen> {
  /// The decision being submitted, to show the matching button as busy.
  LeaveStatus? _submitting;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve leave?'),
        content: const Text(
          'The student will see this application as approved.',
        ),
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
    await _review(
      LeaveStatus.rejected,
      rejectionReason: reason.isEmpty ? null : reason,
    );
  }

  Future<void> _review(LeaveStatus decision, {String? rejectionReason}) async {
    if (_submitting != null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = decision);
    try {
      await ref
          .read(leaveApplicationsRepositoryProvider)
          .reviewLeaveApplication(
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
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationAsync = ref.watch(
      adminLeaveApplicationDetailProvider(widget.applicationId),
    );
    final application = applicationAsync.valueOrNull;
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Leave request'),
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (application != null) ...[
            LeaveStatusChip(status: application.status),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: applicationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: c.inkMuted, size: 40),
                const SizedBox(height: 18),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => ref.invalidate(
                    adminLeaveApplicationDetailProvider(widget.applicationId),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (application) =>
            AdminLeaveRequestDetails(application: application),
      ),
      bottomNavigationBar: application != null && application.isPending
          ? SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _submitting != null ? null : _reject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.ink,
                            side: BorderSide(color: c.danger, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _submitting == LeaveStatus.rejected
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.danger,
                                  ),
                                )
                              : const Text('Reject'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submitting != null ? null : _approve,
                          icon: _submitting == LeaveStatus.approved
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 19),
                          label: const Text('Approve'),
                          style: FilledButton.styleFrom(
                            backgroundColor: c.brand,
                            foregroundColor: c.onBrand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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

/// The review API requires a rejection reason.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _formKey = GlobalKey<FormState>();
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
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            counterText: '',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter a reason to reject this request'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
