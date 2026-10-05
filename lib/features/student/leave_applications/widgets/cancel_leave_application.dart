import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../../../common/leave_applications/widgets/leave_application_card.dart';

/// Asks the student to confirm, then cancels [application]. Shows the
/// outcome in a SnackBar and resolves to `true` once it was cancelled.
/// [onBusyChanged] brackets the request, for showing a spinner.
Future<bool> confirmAndCancelLeaveApplication(
  BuildContext context,
  WidgetRef ref,
  LeaveApplicationModel application, {
  void Function(bool busy)? onBusyChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this leave?'),
      content: Text(
        'Your application for ${leaveDateRangeLabel(application)} will be withdrawn. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cancel leave'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  void show(String message) => messenger.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

  onBusyChanged?.call(true);
  try {
    await ref.read(leaveApplicationsRepositoryProvider).cancelLeaveApplication(application.id);
    ref.invalidate(myLeaveApplicationsProvider);
    ref.invalidate(myLeaveApplicationDetailProvider(application.id));
    show('Leave application cancelled');
    return true;
  } catch (e) {
    show(e.toString());
    return false;
  } finally {
    if (context.mounted) onBusyChanged?.call(false);
  }
}
