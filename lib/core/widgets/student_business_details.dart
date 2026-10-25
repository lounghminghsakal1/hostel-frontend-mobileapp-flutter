import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/hostel_admin/students/model/student_model.dart';
import '../../features/hostel_admin/students/providers/students_providers.dart';
import '../../features/hostel_admin/students/widgets/student_avatar.dart';

/// Shared business fields for scalar student lists and nested attendance/leave profiles.
class StudentBusinessDetails extends ConsumerWidget {
  const StudentBusinessDetails({
    super.key,
    required this.student,
    this.resolveLabels = false,
  });
  final StudentModel student;
  final bool resolveLabels;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? department = student.departmentName;
    String? room = student.roomNumber;
    if (resolveLabels) {
      for (final option in ref.watch(departmentsProvider).valueOrNull ?? []) {
        if (option.id == student.departmentId) department = option.label;
      }
      for (final option in ref.watch(roomsProvider).valueOrNull ?? []) {
        if (option.id == student.roomId) room = option.label;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StudentAvatar(student: student, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Roll number: ${student.rollNumber}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Department: ${department ?? 'Unavailable'}'),
        Text(
          'Room: ${room ?? (student.roomId == null ? 'Not assigned' : 'Unavailable')}',
        ),
        PhoneAction(label: 'Student', number: student.contactNumber),
        PhoneAction(label: 'Parent', number: student.parentMobileNumber),
      ],
    );
  }
}

class PhoneAction extends StatelessWidget {
  const PhoneAction({super.key, required this.label, required this.number});
  final String label;
  final String? number;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$label phone: ${number == null || number!.isEmpty ? '—' : number}',
        ),
      ),
      if (number != null && number!.isNotEmpty)
        IconButton(
          tooltip: 'Call $label',
          icon: const Icon(Icons.call_outlined),
          onPressed: () async {
            bool opened;
            try {
              opened = await launchUrl(Uri(scheme: 'tel', path: number));
            } catch (_) {
              opened = false;
            }
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open dialer')),
              );
            }
          },
        ),
    ],
  );
}
