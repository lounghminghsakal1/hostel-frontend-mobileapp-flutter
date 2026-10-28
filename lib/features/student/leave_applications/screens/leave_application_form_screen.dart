import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../widgets/student_leave_card.dart';

Future<bool> showLeaveApplicationForm(
  BuildContext context, {
  LeaveApplicationModel? application,
}) async =>
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeaveApplicationFormScreen(application: application),
      ),
    ) ??
    false;

class LeaveApplicationFormScreen extends ConsumerStatefulWidget {
  const LeaveApplicationFormScreen({super.key, this.application});
  final LeaveApplicationModel? application;
  @override
  ConsumerState<LeaveApplicationFormScreen> createState() =>
      _LeaveApplicationFormScreenState();
}

class _LeaveApplicationFormScreenState
    extends ConsumerState<LeaveApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _reasonController = TextEditingController(
    text: widget.application?.leaveReason,
  );
  late DateTime? _from = widget.application?.fromDate,
      _to = widget.application?.toDate;
  bool _isSaving = false;
  String? _error;
  bool get _isEditing => widget.application != null;
  DateTimeRange? get _range => _from == null || _to == null
      ? null
      : DateTimeRange(start: _from!, end: _to!);
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool from) async {
    final today = DateUtils.dateOnly(indiaWallTime(DateTime.now()));
    final existing = widget.application?.fromDate;
    final first = existing != null && existing.isBefore(today)
        ? existing
        : today;
    final firstDate = !from && _from != null && _from!.isAfter(first)
        ? _from!
        : first;
    var last = today.add(const Duration(days: 365));
    if (widget.application != null &&
        widget.application!.toDate.isAfter(last)) {
      last = widget.application!.toDate;
    }
    final initial = (from ? _from : _to) ?? (!from ? _from : null) ?? today;
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: last,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      helpText: from ? 'From date' : 'To date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
      }
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
        final changedFrom =
            DateUtils.isSameDay(range.start, application.fromDate)
            ? null
            : range.start;
        final changedTo = DateUtils.isSameDay(range.end, application.toDate)
            ? null
            : range.end;
        if (changedReason == null && changedFrom == null && changedTo == null) {
          if (mounted) Navigator.of(context).pop(false);
          return;
        }
        await repository.updateLeaveApplication(
          id: application.id,
          leaveReason: changedReason,
          fromDate: changedFrom != null || changedTo != null
              ? range.start
              : null,
          toDate: changedFrom != null || changedTo != null ? range.end : null,
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
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final range = _range;
    final days = range == null
        ? 0
        : range.end.difference(range.start).inDays + 1;
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: c.surface,
        appBar: AppBar(
          backgroundColor: c.surface,
          foregroundColor: c.ink,
          surfaceTintColor: c.surface,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            _isEditing ? 'Edit leave request' : 'Apply for leave',
            style: TextStyle(
              color: c.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _dateField('From', _from, c, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _dateField('To', _to, c, false)),
                  ],
                ),
                if (range != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceSunken,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                color: c.ink,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$days ${days == 1 ? 'day' : 'days'} of leave',
                                style: TextStyle(
                                  color: c.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            studentLeaveDateRangeLabel(range.start, range.end),
                            style: TextStyle(color: c.inkMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Reason',
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  enabled: !_isSaving,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 300,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => Text(
                        '$currentLength / $maxLength',
                        style: TextStyle(color: c.inkMuted, fontSize: 12),
                      ),
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Tell us why you need leave'
                      : v.characters.length > 300
                      ? 'Use 300 characters or fewer'
                      : null,
                  style: TextStyle(color: c.ink, fontSize: 14, height: 1.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.surfaceRaised,
                    hintText: 'Why do you need leave?',
                    hintStyle: TextStyle(color: c.inkMuted),
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: TextStyle(color: c.inkMuted, fontSize: 12),
                    border: _border(c.lineStrong),
                    enabledBorder: _border(c.lineStrong),
                    disabledBorder: _border(c.line),
                    focusedBorder: _border(c.focus, 1.5),
                    errorBorder: _border(c.danger),
                    focusedErrorBorder: _border(c.danger, 1.5),
                    errorStyle: TextStyle(color: c.danger),
                    errorMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: c.inkMuted,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your hostel admin reviews this. You'll see the decision under Leave, and you can edit or cancel until then.",
                        style: TextStyle(
                          color: c.inkMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: c.danger, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            border: Border(top: BorderSide(color: c.line)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        color: c.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save changes' : 'Submit request',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  Widget _dateField(
    String label,
    DateTime? date,
    HostelColors c,
    bool from,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: TextStyle(
          color: c.ink,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        key: ValueKey(from ? 'leave-from' : 'leave-to'),
        onPressed: _isSaving ? null : () => _pickDate(from),
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surfaceRaised,
          foregroundColor: c.ink,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.all(12),
          side: BorderSide(color: c.lineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: c.inkMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date == null
                    ? 'Select date'
                    : '${leaveWeekday(date)}, ${toDisplayDate(date).replaceFirst(' ${date.year}', '')}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
