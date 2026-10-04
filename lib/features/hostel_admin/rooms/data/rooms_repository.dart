import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../model/room_model.dart';

class RoomsRepository {
  RoomsRepository(this._dio);

  final Dio _dio;

  Future<List<RoomModel>> getRooms() async {
    try {
      final response = await _dio.get(ApiEndpoints.rooms);
      final data = _unwrap(response.data, 'Failed to load rooms');
      final list = switch (data) {
        List<dynamic> l => l,
        Map<String, dynamic> m when m['rooms'] is List => m['rooms'] as List<dynamic>,
        _ => throw ApiException('Rooms response was malformed'),
      };
      return list.map((r) => RoomModel.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only.
  Future<void> createRoom({required String roomNumber, required int capacity}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rooms,
        data: {'roomNumber': roomNumber, 'capacity': capacity},
      );
      _unwrap(response.data, 'Failed to create room');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only. Patches only the given fields; a null argument leaves that
  /// field as is.
  Future<void> updateRoom({required int id, String? roomNumber, int? capacity}) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.roomById(id),
        data: {
          'roomNumber': ?roomNumber,
          'capacity': ?capacity,
        },
      );
      _unwrap(response.data, 'Failed to update room');
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
