import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_download_url.dart';

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../model/student_model.dart';

/// Rounded-square avatar: a freshly picked local photo if given, otherwise
/// the student's hosted photo, falling back to their initials.
class StudentAvatar extends ConsumerWidget {
  const StudentAvatar({
    super.key,
    required this.student,
    required this.size,
    this.localImagePath,
    this.circular = false,
  });

  final StudentModel student;
  final double size;
  final String? localImagePath;
  final bool circular;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(circular ? size / 2 : size * 0.32);
    final initials = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: radius,
      ),
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
        loadingBuilder: (context, image, progress) => progress == null
            ? image
            : Container(
                color: AppColors.navySoft,
                child: Center(
                  child: SizedBox.square(
                    dimension: size * 0.32,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
        errorBuilder: (context, error, stackTrace) => _ProfileKeyImage(
          imageKey: student.studentImageKey,
          placeholder: initials,
        ),
      );
    } else if (student.studentImageKey?.isNotEmpty ?? false) {
      final key = student.studentImageKey!;
      child = ref
          .watch(mediaDownloadUrlProvider(key))
          .when(
            loading: () => initials,
            error: (_, _) => GestureDetector(
              onTap: () => ref.invalidate(mediaDownloadUrlProvider(key)),
              child: initials,
            ),
            data: (url) => Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => GestureDetector(
                onTap: () => ref.invalidate(mediaDownloadUrlProvider(key)),
                child: initials,
              ),
            ),
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

/// A failed signed detail URL can be renewed using the underlying object key.
class _ProfileKeyImage extends ConsumerWidget {
  const _ProfileKeyImage({required this.imageKey, required this.placeholder});
  final String? imageKey;
  final Widget placeholder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = imageKey;
    if (key == null || key.isEmpty) return placeholder;
    return ref
        .watch(mediaDownloadUrlProvider(key))
        .when(
          loading: () => placeholder,
          error: (_, _) => placeholder,
          data: (url) => Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          ),
        );
  }
}
