import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/api_listing_view.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../../../../core/widgets/student_business_details.dart';
import '../model/student_model.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});
  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final key = GlobalKey<ApiListingViewState>();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Students')),
    floatingActionButton: FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('Add student'),
      onPressed: () async {
        await context.push(AppRoutes.adminStudentCreate);
        key.currentState?.reload();
      },
    ),
    body: ApiListingView(
      key: key,
      endpoint: ApiEndpoints.students,
      filters: studentFilters,
      itemBuilder: (context, row, reload) => Card(
        child: InkWell(
          onTap: () async {
            await context.push(
              AppRoutes.adminStudentDetail((row['id'] as num).toInt()),
            );
            reload();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StudentBusinessDetails(
              student: StudentModel.fromJson(row),
              resolveLabels: true,
            ),
          ),
        ),
      ),
    ),
  );
}
