import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/leave_applications/model/leave_application_model.dart';
import '../../../common/leave_applications/providers/leave_applications_providers.dart';
import '../../../common/leave_applications/widgets/leave_application_card.dart';

/// Status filters shown as chips; `null` means all.
const _filters = <LeaveStatus?>[
  LeaveStatus.pending,
  LeaveStatus.approved,
  LeaveStatus.rejected,
  LeaveStatus.cancelled,
  null,
];

/// Admin-only list of the hostel's leave applications, filtered by status
/// (pending first) and searchable by student. Tap one to review it.
class AdminLeaveApplicationsScreen extends ConsumerStatefulWidget {
  const AdminLeaveApplicationsScreen({super.key});

  @override
  ConsumerState<AdminLeaveApplicationsScreen> createState() => _AdminLeaveApplicationsScreenState();
}

class _AdminLeaveApplicationsScreenState extends ConsumerState<AdminLeaveApplicationsScreen> {
  LeaveStatus? _status = LeaveStatus.pending;
  String _query = '';

  List<LeaveApplicationModel> _filter(List<LeaveApplicationModel> applications) {
    final q = _query.trim().toLowerCase();
    return applications.where((a) {
      if (_status != null && a.status != _status) return false;
      if (q.isEmpty) return true;
      return [a.studentName, a.rollNumber, a.roomNumber]
          .any((field) => field?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _openDetail(LeaveApplicationModel application) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.push<LeaveStatus>(AppRoutes.adminLeaveApplicationDetail(application.id));
    if (result == null || !mounted) return;
    ref.invalidate(leaveApplicationsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Leave application ${result.label.toLowerCase()}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(leaveApplicationsProvider);
    final applications = applicationsAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Leave Applications'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search by student, roll or room',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.navyAlpha(0.5), size: 20),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = filter == _status;
                final count = filter == null
                    ? applications.length
                    : applications.where((a) => a.status == filter).length;
                return ChoiceChip(
                  label: Text(
                    applicationsAsync.hasValue
                        ? '${filter?.label ?? 'All'} ($count)'
                        : filter?.label ?? 'All',
                  ),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _status = filter),
                  backgroundColor: AppColors.navySoftAlt,
                  selectedColor: AppColors.navy,
                  side: BorderSide(color: selected ? AppColors.navy : AppColors.navyAlpha(0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: applicationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              ),
              error: (error, _) => _AdminLeaveError(
                message: error.toString(),
                onRetry: () => ref.invalidate(leaveApplicationsProvider),
              ),
              data: (applications) {
                final visible = _filter(applications);
                return RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: () => ref.refresh(leaveApplicationsProvider.future),
                  child: visible.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _query.trim().isNotEmpty
                                    ? 'No applications match your search'
                                    : _status == null
                                        ? 'No leave applications yet'
                                        : 'No ${_status!.label.toLowerCase()} applications',
                                style: TextStyle(color: AppColors.navyAlpha(0.5)),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: visible.length,
                          itemBuilder: (context, index) => LeaveApplicationCard(
                            application: visible[index],
                            showStudent: true,
                            onTap: () => _openDetail(visible[index]),
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

class _AdminLeaveError extends StatelessWidget {
  const _AdminLeaveError({required this.message, required this.onRetry});

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
