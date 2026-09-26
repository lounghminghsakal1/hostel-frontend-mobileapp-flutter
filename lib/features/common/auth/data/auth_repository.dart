import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../model/login_response_model.dart';

/// Handles the single login endpoint that identifies whether the signed-in
/// user is a student or a hostel admin (see backend spec, section 5).
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != 'success') {
        throw ApiException(body['message'] as String? ?? 'Login failed');
      }
      return LoginResponseModel.fromJson(body);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
