import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/listing_api.dart';
import '../../../../core/utils/date_format.dart';
import '../model/announcement_model.dart';

class AnnouncementInput {
  const AnnouncementInput({
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.pushNotification,
    required this.isImportant,
    this.announcementType = 'OTHER',
    this.linkUrl,
  });
  final String title, description, status, announcementType;
  final DateTime startDate, endDate;
  final bool pushNotification, isImportant;
  final String? linkUrl;
  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'status': status,
    'startDate': toIsoDate(startDate),
    'endDate': toIsoDate(endDate),
    'pushNotification': pushNotification,
    'isImportant': isImportant,
    'announcementType': announcementType,
    if (linkUrl != null && linkUrl!.trim().isNotEmpty)
      'linkUrl': linkUrl!.trim(),
  };
}

class AnnouncementsRepository {
  AnnouncementsRepository(this.dio);
  final Dio dio;
  Future<ListingPage> list({
    Map<String, String> filters = const {},
    int page = 1,
  }) =>
      ListingApi(dio)
          .fetch(ApiEndpoints.announcements, filters: filters, page: page);

  /// Fetch all active pages and keep announcements valid today. The student
  /// home uses the splash endpoint's embedded preview instead of this helper.
  Future<List<AnnouncementModel>> studentAnnouncements() async {
    final rows = <AnnouncementModel>[];
    var page = 1;
    while (true) {
      final result = await list(
        filters: const {'by_status': 'ACTIVE'},
        page: page,
      );
      rows.addAll(result.rows.map(AnnouncementModel.fromJson));
      if (page >= result.totalPages) break;
      page++;
    }
    final now = indiaWallTime(DateTime.now());
    final visible = rows.where((a) => a.visibleOn(now)).toList();
    visible.sort((a, b) {
      final important = (b.isImportant ? 1 : 0).compareTo(
        a.isImportant ? 1 : 0,
      );
      return important != 0
          ? important
          : (b.createdAt ?? b.startDate).compareTo(a.createdAt ?? a.startDate);
    });
    return visible;
  }

  Future<AnnouncementModel> get(int id) async {
    try {
      final response = await dio.get(ApiEndpoints.announcementById(id));
      final data = _unwrap(response.data);
      final json =
          data is Map<String, dynamic> &&
              data['announcement'] is Map<String, dynamic>
          ? data['announcement'] as Map<String, dynamic>
          : data;
      return AnnouncementModel.fromJson(json as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> create(AnnouncementInput input) async {
    try {
      _unwrap(
        (await dio.post(ApiEndpoints.announcements, data: input.toJson())).data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> update(int id, Map<String, dynamic> changes) async {
    try {
      _unwrap(
        (await dio.patch(
          ApiEndpoints.announcementById(id),
          data: changes,
        )).data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Object? _unwrap(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw ApiException('Invalid announcement response');
    }
    if (body['status'] != null && body['status'] != 'success') {
      throw ApiException(
        body['message']?.toString() ?? 'Announcement request failed',
      );
    }
    return body['data'] ?? body;
  }
}
