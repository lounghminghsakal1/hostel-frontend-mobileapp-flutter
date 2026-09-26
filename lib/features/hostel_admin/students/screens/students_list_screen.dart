import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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
        .where((s) =>
            s.studentName.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.contactNumber.contains(q))
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.navyAlpha(0.5), size: 20),
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
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                students.isEmpty ? 'No students yet' : 'No students match your search',
                                style: TextStyle(color: AppColors.navyAlpha(0.5)),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          itemCount: visible.length,
                          itemBuilder: (context, index) => _StudentTile(
                            student: visible[index],
                            onTap: () => context.push(AppRoutes.adminStudentDetail(visible[index].id)),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyAlpha(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                StudentAvatar(student: student, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.navyAlpha(0.55), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.navyAlpha(0.35)),
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
            Icon(Icons.wifi_off_rounded, color: AppColors.navyAlpha(0.4), size: 40),
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
