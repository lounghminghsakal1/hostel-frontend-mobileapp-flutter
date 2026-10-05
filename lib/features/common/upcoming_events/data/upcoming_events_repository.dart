import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/s3_upload_service.dart';
import '../model/upcoming_event_model.dart';

/// Fields of an event form. On update, null fields are left as they are.
typedef UpcomingEventInput = ({
  String? eventName,
  String? eventDescription,
  DateTime? startingAt,
  DateTime? endingAt,
  String? eventImageKey,
  String? eventLink,
  String? contactPersonName,
  String? contactPersonPhone,
  bool? isActive,
});

class UpcomingEventsRepository {
  UpcomingEventsRepository(this._dio, this._s3);

  final Dio _dio;
  final S3UploadService _s3;

  /// Admin and student.
  Future<List<UpcomingEventModel>> getUpcomingEvents() async {
    try {
      final response = await _dio.get(ApiEndpoints.upcomingEvents);
      final data = _unwrap(response.data, 'Failed to load upcoming events');
      final list = switch (data) {
        List<dynamic> l => l,
        // Accept the list wrapped in an object, whatever its key.
        Map<String, dynamic> m when m.values.any((v) => v is List) =>
          m.values.firstWhere((v) => v is List) as List<dynamic>,
        _ => throw ApiException('Upcoming events response was malformed'),
      };
      final events = list.map((e) => UpcomingEventModel.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.startingAt.compareTo(b.startingAt));
      return events;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin and student.
  Future<UpcomingEventModel> getUpcomingEvent(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.upcomingEventById(id));
      final data = _unwrap(response.data, 'Failed to load the event');
      final json = switch (data) {
        Map<String, dynamic> m when m['upcomingEvent'] is Map<String, dynamic> =>
          m['upcomingEvent'] as Map<String, dynamic>,
        Map<String, dynamic> m => m,
        _ => throw ApiException('Event response was malformed'),
      };
      return UpcomingEventModel.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only. Name, description and both times are required.
  Future<void> createUpcomingEvent(UpcomingEventInput input) async {
    try {
      final response = await _dio.post(ApiEndpoints.upcomingEvents, data: _toBody(input));
      _unwrap(response.data, 'Failed to create the event');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only. Patches only the non-null fields of [input].
  Future<void> updateUpcomingEvent(int id, UpcomingEventInput input) async {
    try {
      final response = await _dio.patch(ApiEndpoints.upcomingEventById(id), data: _toBody(input));
      _unwrap(response.data, 'Failed to update the event');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin only. Uploads a banner directly to S3 and returns its object key,
  /// to be sent as `eventImageKey`.
  Future<String> uploadEventImage(String imagePath) {
    return _s3.uploadJpeg(
      mediaFor: MediaFor.eventImage,
      filePath: imagePath,
    );
  }

  /// Times go out as UTC ISO strings (`...Z`), which `z.string().datetime()`
  /// requires.
  Map<String, dynamic> _toBody(UpcomingEventInput input) => {
        'eventName': ?input.eventName,
        'eventDescription': ?input.eventDescription,
        'startingAt': ?input.startingAt?.toUtc().toIso8601String(),
        'endingAt': ?input.endingAt?.toUtc().toIso8601String(),
        'eventImageKey': ?input.eventImageKey,
        'eventLink': ?input.eventLink,
        'contactPersonName': ?input.contactPersonName,
        'contactPersonPhone': ?input.contactPersonPhone,
        'isActive': ?input.isActive,
      };

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
