import 'package:dio/dio.dart';

import 'api_exception.dart';

class ListingPage {
  const ListingPage(
    this.rows,
    this.page,
    this.pageSize,
    this.totalPages,
    this.counts,
  );
  final List<Map<String, dynamic>> rows;
  final int page;
  final int pageSize;
  final int totalPages;
  final Map<String, dynamic> counts;
}

/// Endpoint-specific query keys are supplied by each feature.
class ListingApi {
  ListingApi(this.dio);
  final Dio dio;

  Future<ListingPage> fetch(
    String endpoint, {
    Map<String, String> filters = const {},
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        queryParameters: {
          ...Map<String, String>.of(filters)
            ..removeWhere((key, value) => value.trim().isEmpty),
          'page': '$page',
          'pageSize': '20',
        },
        cancelToken: cancelToken,
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['status'] == 'failure') {
        throw ApiException(
          body is Map ? '${body['message']}' : 'Invalid list response',
        );
      }
      final data = body['data'];
      final rows = data is List
          ? data
          : data is Map
          ? data['leaveApplications']
          : null;
      if (rows is! List) throw ApiException('Invalid list response');
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      return ListingPage(
        rows.cast<Map<String, dynamic>>(),
        (meta['page'] as num?)?.toInt() ?? page,
        (meta['pageSize'] as num?)?.toInt() ?? 20,
        (meta['totalPages'] as num?)?.toInt() ?? 1,
        data is Map
            ? Map<String, dynamic>.from(data['statusesCount'] as Map? ?? {})
            : {},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
