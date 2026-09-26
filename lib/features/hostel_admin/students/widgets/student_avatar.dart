import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../model/student_model.dart';

/// Rounded-square avatar: a freshly picked local photo if given, otherwise
/// the student's hosted photo, falling back to their initials.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.student,
    required this.size,
    this.localImagePath,
  });

  final StudentModel student;
  final double size;
  final String? localImagePath;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.32);
    final initials = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: radius),
      child: Text(
        student.initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final Widget child;
    if (localImagePath != null) {
      child = Image.file(File(localImagePath!), fit: BoxFit.cover);
    } else if (student.studentImageUrl?.isNotEmpty ?? false) {
      child = Image.network(
        student.studentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => initials,
      );
    } else {
      child = initials;
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
