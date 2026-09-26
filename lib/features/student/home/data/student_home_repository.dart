import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../model/student_home_model.dart';

class StudentHomeRepository {
  StudentHomeRepository(this._dio);

  final Dio _dio;

  Future<StudentHomeModel> getHomeScreen() async {
    try {
      final response = await _dio.get(ApiEndpoints.studentHomeScreen);
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != 'success') {
        throw ApiException(body['message'] as String? ?? 'Failed to load home screen');
      }
      return StudentHomeModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
