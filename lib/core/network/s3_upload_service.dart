import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';
import 'dio_client.dart';

/// Presigned upload slot returned by the backend's `.../upload_url` endpoints.
class PresignedUpload {
  const PresignedUpload({required this.uploadUrl, required this.objectKey});

  final String uploadUrl;
  final String objectKey;
}

/// Uploads images straight to S3 in two steps: ask the backend for a
/// presigned PUT url, then PUT the raw bytes to it. The returned object key
/// is what the backend expects in follow-up requests.
class S3UploadService {
  S3UploadService(this._api);

  final Dio _api;

  /// Separate client for S3: the presigned url is absolute and must not carry
  /// the app's base url, JSON content type or `Authorization` header (S3
  /// rejects requests with extra auth).
  late final Dio _s3 = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.addAll([if (kDebugMode) LogInterceptor(requestHeader: true)]);

  /// Requests an upload slot from [uploadUrlEndpoint] (sending [requestBody]
  /// and [queryParameters] if given), uploads the JPEG at [filePath] to it
  /// and returns the S3 object key.
  Future<String> uploadJpeg({
    required String uploadUrlEndpoint,
    required String filePath,
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    final slot = await _requestUploadSlot(uploadUrlEndpoint, requestBody, queryParameters);
    await _putToS3(slot.uploadUrl, filePath);
    return slot.objectKey;
  }

  Future<PresignedUpload> _requestUploadSlot(
    String endpoint,
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  ) async {
    try {
      final response = await _api.get(endpoint, data: requestBody, queryParameters: queryParameters);
      final body = response.data as Map<String, dynamic>;
      final status = body['status'];
      if (status != null && status != 'success') {
        throw ApiException(body['message'] as String? ?? 'Failed to get an upload url');
      }
          
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Upload url response was malformed');
      }
      final uploadUrl = (data['uploadURL'] ?? data['uploadUrl']) as String?;
      final objectKey = data['objectKey'] as String?;
      if (uploadUrl == null || uploadUrl.isEmpty || objectKey == null || objectKey.isEmpty) {
        throw ApiException('Upload url response was missing uploadURL or objectKey');
      }
      return PresignedUpload(uploadUrl: uploadUrl, objectKey: objectKey);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> _putToS3(String uploadUrl, String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      await _s3.put<void>(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          // Must match the content type the url was signed for.
          contentType: 'image/jpeg',
          headers: {Headers.contentLengthHeader: bytes.length},
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      throw ApiException(
        code != null ? 'Image upload failed ($code). Please try again.' : 'Image upload failed. Check your connection.',
        statusCode: code,
      );
    }
  }
}

final s3UploadServiceProvider = Provider<S3UploadService>((ref) {
  return S3UploadService(ref.watch(dioProvider));
});
