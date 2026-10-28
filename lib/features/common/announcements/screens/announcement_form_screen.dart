import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../data/announcements_repository.dart';
import '../providers/announcements_providers.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key, this.id});
  final int? id;
  @override
  ConsumerState<AnnouncementFormScreen> createState() =>
      _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState
    extends ConsumerState<AnnouncementFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _link = TextEditingController();
  DateTime _start = DateUtils.dateOnly(DateTime.now()),
      _end = DateUtils.dateOnly(DateTime.now());
  String _status = 'ACTIVE', _type = 'HOSTEL_ANNOUNCEMENT';
  bool _important = false, _push = false, _loading = false, _saving = false;
  Object? _error;
  Map<String, dynamic>? _original;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _link.dispose();
    super.dispose();
  }

  AnnouncementInput _input() => AnnouncementInput(
    title: _title.text,
    description: _description.text,
    status: _status,
    startDate: _start,
    endDate: _end,
    isImportant: _important,
    pushNotification: _push,
    announcementType: _type,
    linkUrl: _link.text,
  );
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await ref.read(announcementsRepositoryProvider).get(widget.id!);
      if (!mounted) return;
      _title.text = a.title;
      _description.text = a.description;
      _link.text = a.linkUrl ?? '';
      _start = a.startDate;
      _end = a.endDate;
      _status = a.status;
      _type = a.announcementType;
      _important = a.isImportant;
      _push = a.pushNotification;
      _original = _input().toJson();
    } catch (e) {
      if (mounted) _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be on or after start date'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(announcementsRepositoryProvider);
      if (widget.id == null) {
        await repo.create(_input());
      } else {
        final changes = _input().toJson()
          ..removeWhere((k, v) => _original?[k] == v);
        if (changes.isNotEmpty) await repo.update(widget.id!, changes);
      }
      if (widget.id != null) {
        ref.invalidate(announcementDetailProvider(widget.id!));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (value != null && mounted) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.id == null ? 'New announcement' : 'Edit announcement'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_error'),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          )
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _title,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a description'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _link,
                  enabled: !_saving,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link (optional)',
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) {
                      return _original?['linkUrl'] != null
                          ? 'Enter a replacement link'
                          : null;
                    }
                    final uri = Uri.tryParse(text);
                    return uri == null ||
                            !['https', 'http'].contains(uri.scheme) ||
                            uri.host.isEmpty
                        ? 'Enter a valid https:// or http:// link'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'INACTIVE',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'HOSTEL_ANNOUNCEMENT',
                      child: Text('Hostel'),
                    ),
                    DropdownMenuItem(
                      value: 'COLLEGE_ANNOUNCEMENT',
                      child: Text('College'),
                    ),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickDate(true),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Start date: ${toDisplayDate(_start)}'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickDate(false),
                  icon: const Icon(Icons.event_outlined),
                  label: Text('End date: ${toDisplayDate(_end)}'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Important'),
                  value: _important,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _important = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Push notification'),
                  value: _push,
                  onChanged: _saving ? null : (v) => setState(() => _push = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save announcement'),
                ),
              ],
            ),
          ),
  );
}
