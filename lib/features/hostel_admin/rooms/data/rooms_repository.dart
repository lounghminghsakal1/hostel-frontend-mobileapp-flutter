import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../model/room_model.dart';

class RoomsRepository {
  RoomsRepository(this._dio);

  final Dio _dio;

  /// Collect each page so availability filters and totals cover the hostel.
  Future<List<RoomModel>> getRooms({
    Map<String, String> filters = const {},
    CancelToken? cancelToken,
  }) async {
    try {
      final rooms = <int, RoomModel>{};
      var page = 1;
      while (true) {
        final response = await _dio.get(
          ApiEndpoints.rooms,
          queryParameters: {
            'only_vacancy': 'false',
            ...filters,
            'page': '$page',
            'pageSize': '20',
          },
          cancelToken: cancelToken,
        );
        final data = _unwrap(response.data, 'Failed to load rooms');
        final list = switch (data) {
          List<dynamic> l => l,
          Map<String, dynamic> m when m['rooms'] is List =>
            m['rooms'] as List<dynamic>,
          _ => throw ApiException('Rooms response was malformed'),
        };
        for (final row in list) {
          final room = RoomModel.fromJson(row as Map<String, dynamic>);
          rooms[room.id] = room;
        }
        final body = response.data;
        final meta = body is Map ? body['meta'] : null;
        final totalPages = meta is Map
            ? (meta['totalPages'] as num?)?.toInt() ?? 1
            : 1;
        if (page >= totalPages) return rooms.values.toList();
        page++;
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only.
  Future<void> createRoom({
    required String roomNumber,
    required int capacity,
  }) async {
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
  Future<void> updateRoom({
    required int id,
    String? roomNumber,
    int? capacity,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.roomById(id),
        data: {'roomNumber': ?roomNumber, 'capacity': ?capacity},
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
    return responseData.containsKey('data')
        ? responseData['data']
        : responseData;
  }
}
