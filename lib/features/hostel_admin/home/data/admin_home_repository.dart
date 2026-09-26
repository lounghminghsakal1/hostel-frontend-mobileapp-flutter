import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../model/admin_dashboard_model.dart';

class AdminHomeRepository {
  AdminHomeRepository(this._dio);

  final Dio _dio;

  Future<AdminDashboardModel> getDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminDashboard);
      return AdminDashboardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
