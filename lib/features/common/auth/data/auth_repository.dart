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

  /// Sets the password from an emailed link's [token]. [forgotPassword]
  /// marks a reset link (vs. a new account's first-password link); the flag
  /// is only sent when true.
  Future<void> setupNewPassword({
    required String token,
    required String newPassword,
    bool forgotPassword = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.setupNewPassword,
        data: {
          'token': token,
          'newPassword': newPassword,
          if (forgotPassword) 'forgotPassword': true,
        },
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['status'] != null && body['status'] != 'success') {
        throw ApiException(body['message'] as String? ?? 'Failed to set password');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Asks the backend to email a password reset link to [email], which must
  /// be the address the account was created with.
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      final body = response.data;
      if (body is Map<String, dynamic> && body['status'] != null && body['status'] != 'success') {
        throw ApiException(body['message'] as String? ?? 'Failed to send the reset link');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
