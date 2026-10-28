import '../../../../core/utils/date_format.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.announcementType = 'OTHER',
    this.linkUrl,
    this.isImportant = false,
    this.pushNotification = false,
    this.createdAt,
  });
  final int id;
  final String title, description, status, announcementType;
  final DateTime startDate, endDate;
  final String? linkUrl;
  final bool isImportant, pushNotification;
  final DateTime? createdAt;

  String get category => switch (announcementType) {
    'HOSTEL_ANNOUNCEMENT' => 'Hostel',
    'COLLEGE_ANNOUNCEMENT' => 'College',
    _ => 'Notice',
  };
  bool visibleOn(DateTime date) {
    final today = DateTime(date.year, date.month, date.day);
    return status == 'ACTIVE' &&
        !today.isBefore(startDate) &&
        !today.isAfter(endDate);
  }

  String get dateLabel => startDate == endDate
      ? toDisplayDate(startDate)
      : '${toDisplayDate(startDate)} – ${toDisplayDate(endDate)}';
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime date(String key) {
      final value = json[key]?.toString() ?? '';
      final parsed = DateTime.tryParse(
        value.length >= 10 ? value.substring(0, 10) : value,
      );
      if (parsed == null) {
        throw FormatException('Missing or invalid announcement $key');
      }
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    return AnnouncementModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'INACTIVE',
      startDate: date('startDate'),
      endDate: date('endDate'),
      announcementType: json['announcementType'] as String? ?? 'OTHER',
      linkUrl: json['linkUrl'] as String?,
      isImportant: json['isImportant'] == true,
      pushNotification: json['pushNotification'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
