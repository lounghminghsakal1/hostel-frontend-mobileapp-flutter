import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';

/// Opens the apply form, or the edit form when [application] is given.
/// Resolves to `true` once the application was saved.
Future<bool> showLeaveApplicationFormSheet(
  BuildContext context, {
  LeaveApplicationModel? application,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LeaveApplicationFormSheet(application: application),
  );
  return saved ?? false;
}

class _LeaveApplicationFormSheet extends ConsumerStatefulWidget {
  const _LeaveApplicationFormSheet({this.application});

  final LeaveApplicationModel? application;

  @override
  ConsumerState<_LeaveApplicationFormSheet> createState() => _LeaveApplicationFormSheetState();
}

class _LeaveApplicationFormSheetState extends ConsumerState<_LeaveApplicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _reasonController = TextEditingController(text: widget.application?.leaveReason);
  late DateTimeRange? _range = widget.application == null
      ? null
      : DateTimeRange(start: widget.application!.fromDate, end: widget.application!.toDate);
  bool _isSaving = false;

  /// Shown above the submit button; a SnackBar would sit behind the sheet.
  String? _error;

  bool get _isEditing => widget.application != null;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final existingStart = widget.application?.fromDate;
    // When editing a leave that already started, keep its start selectable.
    final firstDate = existingStart != null && existingStart.isBefore(today) ? existingStart : today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _range,
      helpText: 'Select leave dates',
      saveText: 'Done',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = picked;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    final range = _range;
    if (range == null) {
      setState(() => _error = 'Select the leave dates');
      return;
    }

    final reason = _reasonController.text.trim();
    final repository = ref.read(leaveApplicationsRepositoryProvider);
    final application = widget.application;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (application == null) {
        await repository.createLeaveApplication(
          leaveReason: reason,
          fromDate: range.start,
          toDate: range.end,
        );
      } else {
        // Only send the fields that actually changed.
        final changedReason = reason == application.leaveReason ? null : reason;
        final changedFrom = DateUtils.isSameDay(range.start, application.fromDate) ? null : range.start;
        final changedTo = DateUtils.isSameDay(range.end, application.toDate) ? null : range.end;
        if (changedReason == null && changedFrom == null && changedTo == null) {
          if (mounted) Navigator.of(context).pop(false);
          return;
        }
        await repository.updateLeaveApplication(
          id: application.id,
          leaveReason: changedReason,
          fromDate: changedFrom,
          toDate: changedTo,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final days = range == null ? 0 : range.end.difference(range.start).inDays + 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.navyAlpha(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Edit Leave Application' : 'Apply for Leave',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSaving ? null : _pickDates,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.date_range_rounded, color: AppColors.navyAlpha(0.6), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leave dates',
                                  style: TextStyle(color: AppColors.navyAlpha(0.65), fontSize: 12),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  range == null
                                      ? 'Tap to select'
                                      : '${toDisplayDate(range.start)} – ${toDisplayDate(range.end)}',
                                  style: TextStyle(
                                    color: range == null ? AppColors.navyAlpha(0.45) : AppColors.navy,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (range != null)
                            Text(
                              days == 1 ? '1 day' : '$days days',
                              style: TextStyle(
                                color: AppColors.navyAlpha(0.6),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Tell us why you need leave' : null,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Reason for leave',
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                GradientButton(
                  label: _isEditing ? 'Save changes' : 'Submit application',
                  icon: _isEditing ? Icons.check_rounded : Icons.send_rounded,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
