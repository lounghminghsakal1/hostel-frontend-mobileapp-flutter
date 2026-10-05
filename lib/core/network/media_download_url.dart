import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';
import 'dio_client.dart';

/// Short-lived presigned GET url for an uploaded S3 object key, from the
/// `/media/download_url?image_key=<key>` endpoint. Disposed when unused, so a
/// fresh url is fetched next time instead of reusing an expired one.
final mediaDownloadUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, imageKey) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(
      ApiEndpoints.mediaDownloadUrl,
      queryParameters: {'image_key': imageKey},
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('Image url response was malformed');
    }
    final status = body['status'];
    if (status != null && status != 'success') {
      throw ApiException(body['message'] as String? ?? 'Failed to load the image');
    }
    // Accept the url either wrapped in `data` or at the top level.
    final data = body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body;
    final url = data['downloadUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Image url response was missing downloadUrl');
    }
    return url;
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
});
