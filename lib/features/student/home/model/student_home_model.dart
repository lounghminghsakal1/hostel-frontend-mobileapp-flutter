import 'announcement_model.dart';

class StudentHomeModel {
  const StudentHomeModel({
    required this.canMarkAttendance,
    required this.announcements,
  });

  final bool canMarkAttendance;
  final List<AnnouncementModel> announcements;

  factory StudentHomeModel.fromJson(Map<String, dynamic> json) {
    return StudentHomeModel(
      canMarkAttendance: json['canMarkAttendance'] as bool? ?? false,
      announcements: (json['announcementsData'] as List<dynamic>? ?? [])
          .map((a) => AnnouncementModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
