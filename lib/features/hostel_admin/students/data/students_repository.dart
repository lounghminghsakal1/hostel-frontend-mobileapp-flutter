import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/s3_upload_service.dart';
import '../model/student_model.dart';

class StudentsRepository {
  StudentsRepository(this._dio, this._s3);

  final Dio _dio;
  final S3UploadService _s3;

  Future<List<StudentModel>> getStudents() async {
    try {
      final response = await _dio.get(ApiEndpoints.students);
      final data = _unwrap(response.data, 'Failed to load students');
      final list = switch (data) {
        List<dynamic> l => l,
        Map<String, dynamic> m when m['students'] is List => m['students'] as List<dynamic>,
        _ => throw ApiException('Students response was malformed'),
      };
      return list.map((s) => StudentModel.fromJson(s as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StudentModel> getStudent(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.studentById(id));
      return StudentModel.fromJson(_studentObject(_unwrap(response.data, 'Failed to load student')));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Patches only the given fields; a null argument leaves that field as is.
  Future<void> updateStudent({
    required int id,
    String? studentName,
    String? contactNumber,
    String? parentMobileNumber,
    int? departmentId,
    String? studentImageKey,
    int? roomId,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.studentById(id),
        data: {
          'studentName': ?studentName,
          'contactNumber': ?contactNumber,
          'parentMobileNumber': ?parentMobileNumber,
          'departmentId': ?departmentId,
          'studentImageKey': ?studentImageKey,
          'roomId': ?roomId,
        },
      );
      _unwrap(response.data, 'Failed to update student');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Uploads a profile photo directly to S3 and returns its object key, to be
  /// sent as `studentImageKey` in [updateStudent].
  Future<String> uploadStudentImage(String imagePath, {required int studentProfileId}) {
    return _s3.uploadJpeg(
      uploadUrlEndpoint: ApiEndpoints.studentImageUploadUrl,
      filePath: imagePath,
      requestBody: {'studentProfileId': studentProfileId},
    );
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

  Map<String, dynamic> _studentObject(Object? data) => switch (data) {
        Map<String, dynamic> m when m['student'] is Map<String, dynamic> => m['student'] as Map<String, dynamic>,
        Map<String, dynamic> m => m,
        _ => throw ApiException('Student response was malformed'),
      };
}
