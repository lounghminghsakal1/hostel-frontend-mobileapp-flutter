import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../providers/students_providers.dart';
import '../widgets/option_dropdown_field.dart';
import '../widgets/student_photo_picker.dart';

class CreateStudentScreen extends ConsumerStatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  ConsumerState<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends ConsumerState<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _contactController = TextEditingController();
  final _parentContactController = TextEditingController();
  int? _departmentId;
  int? _roomId;

  /// Local path of the picked photo, shown as the preview.
  String? _pickedImagePath;

  /// S3 key of the uploaded photo; required to create the student.
  String? _uploadedImageKey;

  bool _isUploadingPhoto = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _rollNumberController.dispose();
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
    final previousPath = _pickedImagePath;
    setState(() {
      _pickedImagePath = path;
      _isUploadingPhoto = true;
    });
    try {
      final key = await ref.read(studentsRepositoryProvider).uploadStudentImage(path);
      if (!mounted) return;
      setState(() {
        _uploadedImageKey = key;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Keep showing the last successfully uploaded photo, if any.
      setState(() {
        _pickedImagePath = previousPath;
        _isUploadingPhoto = false;
      });
      _showMessage(e.toString());
    }
  }

  Future<void> _create() async {
    if (_isCreating) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    final imageKey = _uploadedImageKey;
    if (imageKey == null) {
      _showMessage('Add a photo of the student');
      return;
    }
    // Checked separately: if departments failed to load there's no dropdown to validate.
    final departmentId = _departmentId;
    if (!formValid || departmentId == null) {
      _showMessage(departmentId == null ? 'Select a department' : 'Please fix the highlighted fields');
      return;
    }

    setState(() => _isCreating = true);
    try {
      await ref.read(studentsRepositoryProvider).createStudent(
            email: _emailController.text.trim(),
            studentName: _nameController.text.trim(),
            contactNumber: _contactController.text.trim(),
            parentMobileNumber: _parentContactController.text.trim(),
            departmentId: departmentId,
            rollNumber: _rollNumberController.text.trim(),
            studentImageKey: imageKey,
            roomId: _roomId,
          );
      if (!mounted) return;
      ref.invalidate(studentsListProvider);
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Student created'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  static String? _email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) ? null : 'Enter a valid email';
  }

  static String? _phone(String? value) =>
      (value?.trim().length ?? 0) == 10 ? null : 'Enter a 10-digit number';

  @override
  Widget build(BuildContext context) {
    final busy = _isUploadingPhoto || _isCreating;
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Create Student'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(child: _PhotoPreview(path: _pickedImagePath, isUploading: _isUploadingPhoto)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Professional photo · required',
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
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: _email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Roll number',
              icon: Icons.badge_outlined,
              controller: _rollNumberController,
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
              noneLabel: 'No room',
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Create student',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _isCreating,
              onPressed: _isUploadingPhoto ? null : _create,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, required this.isUploading});

  static const double _size = 112;

  final String? path;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_size * 0.32);
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null)
              Image.file(File(path!), fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(color: AppColors.navyAlpha(0.06)),
                child: Icon(Icons.add_a_photo_outlined, color: AppColors.navyAlpha(0.4), size: 34),
              ),
            if (isUploading)
              Container(
                color: AppColors.navyAlpha(0.45),
                child: const Center(child: CircularProgressIndicator(color: AppColors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
