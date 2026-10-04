import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';
import '../../../common/upcoming_events/providers/upcoming_events_providers.dart';
import '../../../common/upcoming_events/widgets/event_image.dart';

/// Create form, or the edit form for [eventId]. Pops with `true` once saved.
class EventFormScreen extends ConsumerWidget {
  const EventFormScreen({super.key, this.eventId});

  final int? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = eventId;
    final Widget body;
    if (id == null) {
      body = const _EventForm();
    } else {
      body = ref.watch(upcomingEventDetailProvider(id)).when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.navyAlpha(0.6)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(upcomingEventDetailProvider(id)),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (event) => _EventForm(event: event),
          );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(id == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: body,
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.event});

  final UpcomingEventModel? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.event?.eventName);
  late final _descriptionController = TextEditingController(text: widget.event?.eventDescription);
  late final _linkController = TextEditingController(text: widget.event?.eventLink);
  late final _contactNameController = TextEditingController(text: widget.event?.contactPersonName);
  late final _contactPhoneController = TextEditingController(text: widget.event?.contactPersonPhone);

  late DateTime? _startingAt = widget.event?.startingAt;
  late DateTime? _endingAt = widget.event?.endingAt;
  late bool _isActive = widget.event?.isActive ?? true;

  /// Freshly picked banner, shown instead of the current one.
  String? _localImagePath;

  /// S3 key of the freshly uploaded banner; sent on save.
  String? _uploadedImageKey;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  /// Shown above the save button for errors not tied to one field.
  String? _error;

  bool get _isEditing => widget.event != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final String? path;
    try {
      // A quality below 100 makes the picker re-encode the image as JPEG,
      // matching the `image/jpeg` content type the upload url is signed for.
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      path = file?.path;
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Could not open the photo library');
      return;
    }
    if (path == null || !mounted) return;

    final previousPath = _localImagePath;
    setState(() {
      _localImagePath = path;
      _isUploadingImage = true;
      _error = null;
    });
    try {
      final key = await ref.read(upcomingEventsRepositoryProvider).uploadEventImage(path);
      if (!mounted) return;
      setState(() {
        _uploadedImageKey = key;
        _isUploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Keep showing the last successfully uploaded banner, if any.
      setState(() {
        _localImagePath = previousPath;
        _isUploadingImage = false;
        _error = e.toString();
      });
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? current, {DateTime? notBefore}) async {
    final now = DateTime.now();
    final initial = current ?? notBefore ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      // Allow past dates when editing an event that already started.
      firstDate: DateUtils.dateOnly(initial.isBefore(now) ? initial : now),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_startingAt);
    if (picked == null || !mounted) return;
    setState(() {
      // Keep the event's length when moving its start.
      final end = _endingAt;
      final start = _startingAt;
      if (end != null && start != null && !end.isAfter(picked)) {
        _endingAt = picked.add(end.difference(start));
      }
      _startingAt = picked;
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final start = _startingAt;
    final picked = await _pickDateTime(
      _endingAt,
      notBefore: start?.add(const Duration(hours: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endingAt = picked;
      _error = null;
    });
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  static String? _link(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final valid = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    return valid ? null : 'Enter a full link starting with https://';
  }

  /// Trimmed text, or null when empty.
  static String? _text(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (_isSaving || _isUploadingImage) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    final start = _startingAt;
    final end = _endingAt;
    if (start == null || end == null) {
      setState(() => _error = 'Select when the event starts and ends');
      return;
    }
    if (!end.isAfter(start)) {
      setState(() => _error = 'The event must end after it starts');
      return;
    }
    if (!formValid) return;

    final event = widget.event;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final link = _text(_linkController);
    final contactName = _text(_contactNameController);
    final contactPhone = _text(_contactPhoneController);

    final repository = ref.read(upcomingEventsRepositoryProvider);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (event == null) {
        await repository.createUpcomingEvent((
          eventName: name,
          eventDescription: description,
          startingAt: start,
          endingAt: end,
          eventImageKey: _uploadedImageKey,
          eventLink: link,
          contactPersonName: contactName,
          contactPersonPhone: contactPhone,
          isActive: null,
        ));
      } else {
        // Only send the fields that actually changed. The API can't clear an
        // optional field, so an emptied one is left as it was.
        T? changed<T>(T? value, T? original) => value == original ? null : value;
        await repository.updateUpcomingEvent(event.id, (
          eventName: changed(name, event.eventName),
          eventDescription: changed(description, event.eventDescription),
          startingAt: start.isAtSameMomentAs(event.startingAt) ? null : start,
          endingAt: end.isAtSameMomentAs(event.endingAt) ? null : end,
          eventImageKey: _uploadedImageKey,
          eventLink: changed(link, event.eventLink),
          contactPersonName: changed(contactName, event.contactPersonName),
          contactPersonPhone: changed(contactPhone, event.contactPersonPhone),
          isActive: changed(_isActive, event.isActive),
        ));
        ref.invalidate(upcomingEventDetailProvider(event.id));
      }
      ref.invalidate(upcomingEventsProvider);
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
    final busy = _isSaving || _isUploadingImage;
    final event = widget.event;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _BannerPicker(
            localImagePath: _localImagePath,
            event: event,
            isUploading: _isUploadingImage,
            onTap: busy ? null : _pickImage,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Banner image · optional · tap to ${_localImagePath != null || event?.eventImageKey != null ? 'change' : 'add'}',
              style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Details'),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Event name',
            icon: Icons.celebration_outlined,
            controller: _nameController,
            maxLength: 120,
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _required,
            style: const TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  label: 'Starts',
                  value: _startingAt,
                  onTap: busy ? null : _pickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeField(
                  label: 'Ends',
                  value: _endingAt,
                  onTap: busy ? null : _pickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Event link (optional)',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            controller: _linkController,
            validator: _link,
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Contact person'),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Name (optional)',
            icon: Icons.person_outline_rounded,
            controller: _contactNameController,
            maxLength: 80,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Phone (optional)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            controller: _contactPhoneController,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
            maxLength: 15,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                value: _isActive,
                onChanged: busy ? null : (value) => setState(() => _isActive = value),
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'Visible to students',
                  style: TextStyle(color: AppColors.navy, fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _isActive ? 'Students can see this event' : 'Hidden from students',
                  style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: _isEditing ? 'Save changes' : 'Create event',
            icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
            isLoading: _isSaving,
            onPressed: _isUploadingImage ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _BannerPicker extends StatelessWidget {
  const _BannerPicker({
    required this.localImagePath,
    required this.event,
    required this.isUploading,
    required this.onTap,
  });

  final String? localImagePath;
  final UpcomingEventModel? event;
  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (localImagePath != null) {
      image = Image.file(File(localImagePath!), fit: BoxFit.cover);
    } else if (event != null && (event!.eventImageKey != null || event!.eventImageUrl != null)) {
      image = EventImage(event: event!);
    } else {
      image = Container(
        color: AppColors.navyAlpha(0.06),
        child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.navyAlpha(0.4), size: 38),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (isUploading)
                  Container(
                    color: AppColors.navyAlpha(0.45),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.white)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Material(
      color: AppColors.navySoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_rounded, size: 16, color: AppColors.navyAlpha(0.6)),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: AppColors.navyAlpha(0.65), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value == null ? 'Tap to select' : toDisplayDate(value),
                style: TextStyle(
                  color: value == null ? AppColors.navyAlpha(0.45) : AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (value != null) ...[
                const SizedBox(height: 2),
                Text(
                  toDisplayTime(value),
                  style: TextStyle(color: AppColors.navyAlpha(0.6), fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
