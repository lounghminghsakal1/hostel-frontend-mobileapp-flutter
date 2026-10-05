import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_format.dart';
import '../model/leave_application_model.dart';

class LeaveApplicationsRepository {
  LeaveApplicationsRepository(this._dio);

  final Dio _dio;

  /// Admin only: every application in the hostel.
  Future<List<LeaveApplicationModel>> getLeaveApplications() =>
      _getList(ApiEndpoints.leaveApplications);

  /// Admin only.
  Future<LeaveApplicationModel> getLeaveApplication(int id) =>
      _getOne(ApiEndpoints.leaveApplicationById(id));

  /// Student only: the signed-in student's own applications.
  Future<List<LeaveApplicationModel>> getMyLeaveApplications() =>
      _getList(ApiEndpoints.myLeaveApplications);

  /// Student only: one of the signed-in student's own applications.
  Future<LeaveApplicationModel> getMyLeaveApplication(int id) =>
      _getOne(ApiEndpoints.myLeaveApplicationById(id));

  Future<List<LeaveApplicationModel>> _getList(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      final data = _unwrap(response.data, 'Failed to load leave applications');
      final list = switch (data) {
        List<dynamic> l => l,
        // Accept the list wrapped in an object, whatever its key.
        Map<String, dynamic> m when m.values.any((v) => v is List) =>
          m.values.firstWhere((v) => v is List) as List<dynamic>,
        _ => throw ApiException('Leave applications response was malformed'),
      };
      return list
          .map((a) => LeaveApplicationModel.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LeaveApplicationModel> _getOne(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      final data = _unwrap(response.data, 'Failed to load the leave application');
      final json = switch (data) {
        Map<String, dynamic> m when m['leaveApplication'] is Map<String, dynamic> =>
          m['leaveApplication'] as Map<String, dynamic>,
        Map<String, dynamic> m => m,
        _ => throw ApiException('Leave application response was malformed'),
      };
      return LeaveApplicationModel.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Student only.
  Future<void> createLeaveApplication({
    required String leaveReason,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.leaveApplications,
        data: {
          'leaveReason': leaveReason,
          'fromDate': toIsoDate(fromDate),
          'toDate': toIsoDate(toDate),
        },
      );
      _unwrap(response.data, 'Failed to submit the leave application');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Student only. Patches only the given fields; a null argument leaves
  /// that field as is.
  Future<void> updateLeaveApplication({
    required int id,
    String? leaveReason,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.leaveApplicationById(id),
        data: {
          'leaveReason': ?leaveReason,
          'fromDate': ?(fromDate == null ? null : toIsoDate(fromDate)),
          'toDate': ?(toDate == null ? null : toIsoDate(toDate)),
        },
      );
      _unwrap(response.data, 'Failed to update the leave application');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Student only.
  Future<void> cancelLeaveApplication(int id) async {
    try {
      final response = await _dio.patch(ApiEndpoints.cancelLeaveApplication(id));
      _unwrap(response.data, 'Failed to cancel the leave application');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only. [decision] must be [LeaveStatus.approved] or
  /// [LeaveStatus.rejected].
  Future<void> reviewLeaveApplication({
    required int id,
    required LeaveStatus decision,
    String? rejectionReason,
  }) async {
    assert(decision == LeaveStatus.approved || decision == LeaveStatus.rejected);
    try {
      final response = await _dio.patch(
        ApiEndpoints.reviewLeaveApplication(id),
        data: {
          'status': decision.apiValue,
          'rejectionReason': ?rejectionReason,
        },
      );
      _unwrap(response.data, 'Failed to review the leave application');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns the `data` payload, throwing if the envelope reports a failure.
  Object? _unwrap(Object? responseData, String fallbackMessage) {
    if (responseData is! Map<String, dynamic>) return responseData;
    final status = responseData['status'];
    if (status != null && status != 'success') {
      throw ApiException(responseData['message'] as String? ?? fallbackMessage);
    }
    return responseData.containsKey('data') ? responseData['data'] : responseData;
  }
}
