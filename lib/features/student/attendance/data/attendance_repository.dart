import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/s3_upload_service.dart';

class AttendanceRepository {
  AttendanceRepository(this._dio, this._s3);

  final Dio _dio;
  final S3UploadService _s3;

  /// Uploads the captured face image directly to S3 and returns its object
  /// key, to be sent as `capturedImageKey` when marking attendance.
  Future<String> uploadAttendanceImage(String imagePath) {
    return _s3.uploadJpeg(
      uploadUrlEndpoint: ApiEndpoints.attendanceImageUploadUrl,
      filePath: imagePath,
    );
  }

  /// Submits the geo-tagged attendance record for the already-uploaded image.
  Future<void> submitAttendanceRecord({
    required String capturedImageKey,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.attendanceRecords,
        data: {
          'capturedImageKey': capturedImageKey,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != 'success') {
        throw ApiException(body['message'] as String? ?? 'Failed to mark attendance');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
