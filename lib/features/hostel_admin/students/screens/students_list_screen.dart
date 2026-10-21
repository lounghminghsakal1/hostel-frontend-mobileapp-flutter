import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../model/student_model.dart';
import '../providers/students_providers.dart';
import '../widgets/student_avatar.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _query = '';

  List<StudentModel> _filter(List<StudentModel> students) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students
        .where(
          (s) =>
              s.studentName.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              s.contactNumber.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminStudentCreate),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: AppSearchField(
              hint: 'Search by name, email or phone',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (studentsAsync.hasValue && _query.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filter(studentsAsync.requireValue).length} ${_filter(studentsAsync.requireValue).length == 1 ? 'result' : 'results'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              ),
              error: (error, _) => _StudentsError(
                message: error.toString(),
                onRetry: () => ref.invalidate(studentsListProvider),
              ),
              data: (students) {
                final visible = _filter(students);
                return RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: () => ref.refresh(studentsListProvider.future),
                  child: visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            AppEmptyState(
                              icon: students.isEmpty
                                  ? Icons.groups_outlined
                                  : Icons.search_off_rounded,
                              title: students.isEmpty
                                  ? 'No students yet'
                                  : 'No matching students',
                              message: students.isEmpty
                                  ? 'Add a student to manage their details and room assignment.'
                                  : 'Try a different search or clear the search field to see all students.',
                              actionLabel: students.isEmpty
                                  ? 'Add your first student'
                                  : null,
                              onAction: students.isEmpty
                                  ? () => context.push(
                                      AppRoutes.adminStudentCreate,
                                    )
                                  : null,
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          // Bottom padding keeps the last tile clear of the add button.
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: visible.length,
                          itemBuilder: (context, index) => _StudentTile(
                            student: visible[index],
                            onTap: () => context.push(
                              AppRoutes.adminStudentDetail(visible[index].id),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final StudentModel student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (student.roomNumber != null) 'Room ${student.roomNumber}',
      if (student.departmentName != null) student.departmentName!,
    ];
    final subtitle = details.isEmpty ? student.email : details.join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                StudentAvatar(student: student, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.navyAlpha(0.55)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.navyAlpha(0.35),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentsError extends StatelessWidget {
  const _StudentsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: AppColors.navyAlpha(0.4),
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navyAlpha(0.6)),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
