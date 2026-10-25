import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/api_listing_view.dart';
import '../../../../core/widgets/listing_filters.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/widgets/leave_application_card.dart';

class AdminLeaveApplicationsScreen extends StatelessWidget {
  const AdminLeaveApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Leave Applications')),
    body: ApiListingView(
      endpoint: ApiEndpoints.leaveApplications,
      filters: const [
        ...leaveFilters,
        ListingFilter(
          'by_status',
          'Status',
          options: {
            'WAITING_FOR_APPROVAL': 'Pending',
            'APPROVED': 'Approved',
            'REJECTED': 'Rejected',
            'CANCELLED': 'Cancelled',
          },
        ),
      ],
      itemBuilder: (context, row, reload) => LeaveApplicationCard(
        application: LeaveApplicationModel.fromJson(row),
        showStudent: true,
        onTap: () async {
          await context.push(
            AppRoutes.adminLeaveApplicationDetail((row['id'] as num).toInt()),
          );
          reload();
        },
      ),
    ),
  );
}
