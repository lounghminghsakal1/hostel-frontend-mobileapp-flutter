import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../model/student_model.dart';
import '../providers/students_providers.dart';
import '../widgets/option_dropdown_field.dart';
import '../widgets/student_avatar.dart';
import '../widgets/student_photo_picker.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: studentAsync.when(
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
                  onPressed: () => ref.invalidate(studentDetailProvider(studentId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (student) => _StudentEditForm(student: student),
      ),
    );
  }
}

typedef _StudentValues = ({
  String studentName,
  String contactNumber,
  String parentMobileNumber,
  int? departmentId,
  String? studentImageKey,
  int? roomId,
});

class _StudentEditForm extends ConsumerStatefulWidget {
  const _StudentEditForm({required this.student});

  final StudentModel student;

  @override
  ConsumerState<_StudentEditForm> createState() => _StudentEditFormState();
}

class _StudentEditFormState extends ConsumerState<_StudentEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.student.studentName);
  late final _contactController = TextEditingController(text: widget.student.contactNumber);
  late final _parentContactController = TextEditingController(text: widget.student.parentMobileNumber);
  late int? _departmentId = widget.student.departmentId;
  late int? _roomId = widget.student.roomId;

  /// Local path of a newly picked photo, shown as the avatar preview.
  String? _pickedImagePath;

  /// S3 key of the uploaded photo; sent on the next save.
  String? _uploadedImageKey;

  /// Field values as last saved, so a save only sends what changed.
  late _StudentValues _savedValues;

  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _savedValues = _currentValues();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _parentContactController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final path = await captureStudentPhoto(context);
    if (path != null) await _uploadPhoto(path);
  }

  Future<void> _pickFromDevice() async {
    final String? path;
    try {
      path = await pickStudentPhotoFromDevice();
    } on PlatformException catch (e) {
      _showMessage(e.message ?? 'Unable to open the photo library');
      return;
    }
    if (path != null) await _uploadPhoto(path);
  }

  Future<void> _uploadPhoto(String path) async {
    if (!mounted) return;
    setState(() {
      _pickedImagePath = path;
      _isUploadingPhoto = true;
    });
    try {
      final key = await ref.read(studentsRepositoryProvider).uploadStudentImage(
            path,
            studentProfileId: widget.student.id,
          );
      if (!mounted) return;
      setState(() {
        _uploadedImageKey = key;
        _isUploadingPhoto = false;
      });
      await _save(successMessage: 'Photo updated');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickedImagePath = null;
        _isUploadingPhoto = false;
      });
      _showMessage(e.toString());
    }
  }

  Future<void> _save({String successMessage = 'Student details saved'}) async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage(
        _uploadedImageKey != null
            ? 'Photo uploaded. Fix the highlighted fields and tap Save to apply it.'
            : 'Please fix the highlighted fields',
      );
      return;
    }

    final current = _currentValues();
    final saved = _savedValues;
    T? changed<T>(T value, T savedValue) => value == savedValue ? null : value;

    final name = changed(current.studentName, saved.studentName);
    final contact = changed(current.contactNumber, saved.contactNumber);
    final parentContact = changed(current.parentMobileNumber, saved.parentMobileNumber);
    final departmentId = changed(current.departmentId, saved.departmentId);
    final imageKey = changed(current.studentImageKey, saved.studentImageKey);
    final roomId = changed(current.roomId, saved.roomId);

    if ([name, contact, parentContact, departmentId, imageKey, roomId].every((v) => v == null)) {
      _showMessage('No changes to save');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(studentsRepositoryProvider).updateStudent(
            id: widget.student.id,
            studentName: name,
            contactNumber: contact,
            parentMobileNumber: parentContact,
            departmentId: departmentId,
            studentImageKey: imageKey,
            roomId: roomId,
          );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _savedValues = current;
      });
      ref.invalidate(studentsListProvider);
      _showMessage(successMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(e.toString());
    }
  }

  _StudentValues _currentValues() {
    return (
      studentName: _nameController.text.trim(),
      contactNumber: _contactController.text.trim(),
      parentMobileNumber: _parentContactController.text.trim(),
      departmentId: _departmentId,
      studentImageKey: _uploadedImageKey ?? widget.student.studentImageKey,
      roomId: _roomId,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  static String? _phone(String? value) =>
      (value?.trim().length ?? 0) == 10 ? null : 'Enter a 10-digit number';

  @override
  Widget build(BuildContext context) {
    final busy = _isUploadingPhoto || _isSaving;
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                StudentAvatar(
                  student: widget.student,
                  size: 112,
                  localImagePath: _pickedImagePath,
                ),
                if (_isUploadingPhoto)
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.navyAlpha(0.45),
                      borderRadius: BorderRadius.circular(112 * 0.32),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Professional photo',
              style: TextStyle(
                color: AppColors.navyAlpha(0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PhotoActionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take photo',
                  onPressed: busy ? null : _takePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PhotoActionButton(
                  icon: Icons.upload_rounded,
                  label: 'Upload from device',
                  onPressed: busy ? null : _pickFromDevice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Details'),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Student name',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
            validator: _required,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            controller: _contactController,
            inputFormatters: digitsOnly,
            maxLength: 10,
            validator: _phone,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Parent mobile number',
            icon: Icons.family_restroom_rounded,
            keyboardType: TextInputType.phone,
            controller: _parentContactController,
            inputFormatters: digitsOnly,
            maxLength: 10,
            validator: _phone,
          ),
          const SizedBox(height: 14),
          OptionDropdownField(
            label: 'Department',
            icon: Icons.apartment_rounded,
            options: ref.watch(departmentsProvider),
            value: _departmentId,
            onChanged: (id) => setState(() => _departmentId = id),
            onRetry: () => ref.invalidate(departmentsProvider),
            fallbackLabel: widget.student.departmentName,
            requiredMessage: 'Required',
          ),
          const SizedBox(height: 14),
          OptionDropdownField(
            label: 'Room · optional',
            icon: Icons.meeting_room_outlined,
            options: ref.watch(roomsProvider),
            value: _roomId,
            onChanged: (id) => setState(() => _roomId = id),
            onRetry: () => ref.invalidate(roomsProvider),
            fallbackLabel: widget.student.roomNumber,
            // Unassigning a room isn't sent in updates, so only offer "No room"
            // while the student has none.
            noneLabel: _savedValues.roomId == null ? 'No room' : null,
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Save changes',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _isUploadingPhoto ? null : _save,
          ),
        ],
      ),
    );
  }
}
