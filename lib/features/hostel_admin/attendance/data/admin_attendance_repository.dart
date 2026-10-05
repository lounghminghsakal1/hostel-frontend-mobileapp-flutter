import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../model/attendance_records_model.dart';

class AdminAttendanceRepository {
  AdminAttendanceRepository(this._dio);

  final Dio _dio;

  Future<AttendanceRecordsResult> getAttendanceRecords(AttendanceQuery query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.attendanceRecords,
        queryParameters: {
          'date': ?query.date,
          'fromDate': ?query.fromDate,
          'toDate': ?query.toDate,
          'status': query.status.queryValue,
          'page': query.page,
          'pageSize': query.pageSize,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiException('Attendance records response was malformed');
      }
      final status = body['status'];
      if (status != null && status != 'success') {
        throw ApiException(body['message'] as String? ?? 'Failed to load attendance records');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Attendance records response was malformed');
      }
      final meta = body['meta'];
      return AttendanceRecordsResult.fromJson(data, meta is Map<String, dynamic> ? meta : null, query);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
